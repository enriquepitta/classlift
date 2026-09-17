import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:classlift/models/moodle_task.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_tasks_service.dart';

void main() {
  test('prioritizes future deadlines and separates overdue and undated tasks',
      () {
    final now = DateTime(2026, 9, 17, 12);
    MoodleTask task(int id, DateTime? due, {bool submitted = false}) =>
        MoodleTask(
            id: id,
            moduleId: id,
            courseId: 1,
            courseName: 'Materia',
            title: 'Tarea $id',
            description: '',
            dueDate: due,
            submissionStatus: submitted ? 'submitted' : 'new',
            statusKnown: true,
            siteUrl: 'https://school.moodledemo.net');
    final result = MoodleTasksResult([
      task(1, now.subtract(const Duration(days: 3))),
      task(2, now.add(const Duration(days: 2))),
      task(3, null),
      task(4, now.add(const Duration(hours: 1))),
      task(5, now),
      task(6, now.add(const Duration(minutes: 10)), submitted: true),
    ]);
    expect(result.upcomingAt(now).map((task) => task.id), [4, 2]);
    expect(result.overdueAt(now).map((task) => task.id), [5, 1]);
    expect(result.allPendingAt(now).map((task) => task.id), [4, 2, 3, 5, 1]);
  });
  const session = MoodleSession(
      siteUrl: 'https://school.moodledemo.net',
      token: 'test',
      userId: 56,
      fullName: 'Student');
  Map<String, dynamic> assignment(int id) => {
        'id': id,
        'cmid': id + 100,
        'name': 'Tarea $id',
        'intro': '<p>Resolver &amp; entregar</p><p>Unidad 3</p>',
        'duedate': 1000,
        'teamsubmission': 0,
      };
  final course = {'id': 72, 'fullname': 'Matemática I'};

  test('uses extension, decodes HTML and links by module ID', () {
    final task = MoodleTask.fromJson(
        assignment(1),
        course,
        {
          'lastattempt': {
            'extensionduedate': 2000,
            'submission': {'status': 'draft'}
          }
        },
        session.siteUrl);
    expect(task.dueDate!.millisecondsSinceEpoch, 2000000);
    expect(task.description, 'Resolver & entregar Unidad 3');
    expect(task.url.queryParameters['id'], '101');
    expect(task.submitted, isFalse);
  });

  test('supports missing deadlines and group submissions', () {
    final task = MoodleTask.fromJson(
        {...assignment(1), 'duedate': 0, 'teamsubmission': 1},
        course,
        {
          'lastattempt': {
            'teamsubmission': {'status': 'submitted'},
            'extensionduedate': null
          }
        },
        session.siteUrl);
    expect(task.dueDate, isNull);
    expect(task.submitted, isTrue);
  });

  test(
      'filters submitted tasks and retains unverified tasks after partial errors',
      () async {
    final auth = MoodleAuthService(client: MockClient((request) async {
      final fields = request.bodyFields;
      expect(fields['wstoken'], 'test');
      if (fields['wsfunction'] == 'mod_assign_get_assignments') {
        return http.Response(
            jsonEncode({
              'courses': [
                {
                  ...course,
                  'assignments': [
                    assignment(1),
                    assignment(2),
                    {...assignment(3), 'duedate': 0}
                  ]
                }
              ],
              'warnings': []
            }),
            200);
      }
      if (fields['assignid'] == '2') return http.Response('Unavailable', 503);
      return http.Response(
          jsonEncode({
            'lastattempt': {
              'submission': {
                'status': fields['assignid'] == '1' ? 'submitted' : 'draft'
              }
            },
            'warnings': []
          }),
          200);
    }))
      ..session = session;
    final result = await MoodleTasksService(auth: auth).load();
    expect(result.tasks.map((task) => task.id), [2, 3]);
    expect(result.tasks.first.statusKnown, isFalse);
    expect(result.incomplete, isTrue);
  });

  test('does not treat a malformed response as an empty task list', () async {
    final auth = MoodleAuthService(
        client: MockClient((_) async => http.Response('{}', 200)))
      ..session = session;
    await expectLater(MoodleTasksService(auth: auth).load(),
        throwsA(isA<MoodleAuthException>()));
  });
}
