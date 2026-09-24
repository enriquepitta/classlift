import 'package:html/parser.dart' as html;

class MoodleTask {
  final int id;
  final int moduleId;
  final int courseId;
  final String courseName;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String? submissionStatus;
  final bool statusKnown;
  final String siteUrl;

  const MoodleTask(
      {required this.id,
      required this.moduleId,
      required this.courseId,
      required this.courseName,
      required this.title,
      required this.description,
      required this.dueDate,
      required this.submissionStatus,
      required this.statusKnown,
      required this.siteUrl});

  static DateTime? date(dynamic value) => value is num && value > 0
      ? DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000)
      : null;

  static String plainText(String source) {
    final document = html.parseFragment(source.replaceAll(
        RegExp(r'</(?:p|div|li|h[1-6])>|<br\s*/?>', caseSensitive: false),
        ' '));
    for (final element in document.querySelectorAll('script, style')) {
      element.remove();
    }
    return (document.text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  factory MoodleTask.fromJson(
      Map<String, dynamic> task,
      Map<String, dynamic> course,
      Map<String, dynamic>? status,
      String siteUrl) {
    final attempt = status?['lastattempt'] as Map<String, dynamic>?;
    final group = task['teamsubmission'] == 1;
    final submission = attempt?[group ? 'teamsubmission' : 'submission']
        as Map<String, dynamic>?;
    final extension = date(attempt?['extensionduedate']);
    final deadline = date(task['duedate']);
    return MoodleTask(
      id: task['id'] as int,
      moduleId: task['cmid'] as int,
      courseId: course['id'] as int,
      courseName: plainText(course['fullname'] as String? ?? ''),
      title: plainText(task['name'] as String? ?? 'Tarea'),
      description: plainText(task['intro'] as String? ?? ''),
      dueDate:
          extension != null && (deadline == null || extension.isAfter(deadline))
              ? extension
              : deadline,
      submissionStatus: submission?['status'] as String?,
      statusKnown: attempt != null,
      siteUrl: siteUrl,
    );
  }

  bool get submitted => statusKnown && submissionStatus == 'submitted';

  Uri get url => Uri.parse(
          '${siteUrl.replaceFirst(RegExp(r'/+$'), '')}/mod/assign/view.php')
      .replace(queryParameters: {'id': '$moduleId'});
}
