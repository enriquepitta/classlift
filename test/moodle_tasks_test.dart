import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:classlift/models/moodle_task.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_tasks_service.dart';

void main() {
  setUp(MoodleTasksService.clearCache);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(MoodleTasksService.clearCache);
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

  test('clears in-memory session when Moodle rejects the token', () async {
    final auth = MoodleAuthService(
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'exception': 'moodle_exception',
              'errorcode': 'invalidtoken',
            }),
            200)))
      ..session = session;

    await expectLater(
      MoodleTasksService(auth: auth).load(),
      throwsA(isA<MoodleAuthException>().having(
          (error) => error.requiresReconnect, 'requiresReconnect', true)),
    );
    expect(auth.session, isNull);
  });

  for (final code in [
    'accessexception',
    'webservice_access_exception',
    'servicenotavailable',
    'sitemaintenance',
  ]) {
    test('retains the session and cached tasks after $code', () async {
      var failing = false;
      final auth = MoodleAuthService(client: MockClient((request) async {
        if (failing) {
          return http.Response(
              jsonEncode({
                'exception': 'webservice_access_exception',
                'errorcode': code,
              }),
              200);
        }
        return http.Response('{"courses":[]}', 200);
      }))
        ..session = session;
      final service = MoodleTasksService(auth: auth);
      final cached = await service.load();
      failing = true;
      await expectLater(
          service.load(),
          throwsA(isA<MoodleAuthException>()
              .having((e) => e.requiresReconnect, 'requiresReconnect', false)));
      expect(auth.session, same(session));
      expect(MoodleTasksService.lastResult, same(cached));
      failing = false;
      await service.load();
      expect(auth.session, same(session));
    });
  }

  test('confirms an expired token after an ambiguous access error', () async {
    final auth = MoodleAuthService(
        client: MockClient((request) async => http.Response(
            jsonEncode({
              'exception': 'moodle_exception',
              'errorcode': request.bodyFields['wsfunction'] ==
                      'core_webservice_get_site_info'
                  ? 'invalidtoken'
                  : 'accessexception',
            }),
            200)))
      ..session = session;
    await expectLater(
        MoodleTasksService(auth: auth).load(),
        throwsA(isA<MoodleAuthException>()
            .having((e) => e.requiresReconnect, 'requiresReconnect', true)));
    expect(auth.session, isNull);
  });

  test('an old failed request cannot disconnect a newly signed-in session',
      () async {
    final response = Completer<http.Response>();
    final auth = MoodleAuthService(client: MockClient((_) => response.future))
      ..session = session;
    final load = MoodleTasksService(auth: auth).load();
    final expected = expectLater(
        load,
        throwsA(isA<MoodleAuthException>()
            .having((e) => e.requiresReconnect, 'requiresReconnect', false)));
    const replacement = MoodleSession(
        siteUrl: 'https://other.example.edu',
        token: 'new-token',
        userId: 90,
        fullName: 'Other Student');
    auth.session = replacement;
    response.complete(http.Response(
        '{"exception":"moodle_exception","errorcode":"invalidtoken"}', 200));
    await expected;
    expect(auth.session, same(replacement));
  });

  test(
      'rejects an expired token during submission loading instead of showing unknown tasks',
      () async {
    final auth = MoodleAuthService(
        client: MockClient((request) async => http.Response(
            jsonEncode(
                request.bodyFields['wsfunction'] == 'mod_assign_get_assignments'
                    ? {
                        'courses': [
                          {
                            ...course,
                            'assignments': [assignment(1)]
                          }
                        ]
                      }
                    : {
                        'exception': 'moodle_exception',
                        'errorcode': 'invalidtoken'
                      }),
            200)))
      ..session = session;
    await expectLater(
        MoodleTasksService(auth: auth).load(),
        throwsA(isA<MoodleAuthException>()
            .having((e) => e.requiresReconnect, 'requiresReconnect', true)));
    expect(auth.session, isNull);
    expect(MoodleTasksService.lastResult, isNull);
  });
}
