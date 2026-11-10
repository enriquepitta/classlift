import 'package:classlift/models/moodle_task.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:flutter/foundation.dart';

class MoodleTasksResult {
  final List<MoodleTask> tasks;
  final bool incomplete;
  const MoodleTasksResult(this.tasks, {this.incomplete = false});

  List<MoodleTask> upcomingAt(DateTime now) => tasks
      .where((task) =>
          !task.submitted && task.dueDate != null && task.dueDate!.isAfter(now))
      .toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  List<MoodleTask> overdueAt(DateTime now) => tasks
      .where((task) =>
          !task.submitted &&
          task.dueDate != null &&
          !task.dueDate!.isAfter(now))
      .toList()
    ..sort((a, b) => b.dueDate!.compareTo(a.dueDate!));

  List<MoodleTask> allPendingAt(DateTime now) => [
        ...upcomingAt(now),
        ...tasks.where((task) => !task.submitted && task.dueDate == null),
        ...overdueAt(now),
      ];
}

class MoodleTasksService {
  static MoodleTasksResult? lastResult;
  static final _loadNotifier = ValueNotifier<Future<MoodleTasksResult>?>(null);
  static ValueListenable<Future<MoodleTasksResult>?> get loadListenable =>
      _loadNotifier;
  static Future<MoodleTasksResult>? get lastLoad => _loadNotifier.value;
  static MoodleSession? _loadingSession;
  static Future<MoodleTasksResult>? _inFlight;
  static MoodleSession? _cachedSession;

  final MoodleAuthService auth;
  MoodleTasksService({MoodleAuthService? auth})
      : auth = auth ?? MoodleAuthService.instance;

  Future<MoodleTasksResult> load() async {
    var session = auth.session;
    if (session == null) {
      throw const MoodleAuthException(
        'Iniciá sesión con Moodle para ver tus tareas.',
        requiresReconnect: true,
      );
    }
    for (var attempt = 0;; attempt++) {
      try {
        return await _loadTasks(session!);
      } on MoodleAuthException catch (error) {
        if (!error.requiresReconnect || !identical(session, auth.session)) {
          rethrow;
        }
        var failure = error;
        if (attempt == 0) {
          try {
            final renewed = await auth.renewSession(session!);
            if (renewed != null) {
              session = renewed;
              continue;
            }
          } on MoodleAuthException catch (renewalError) {
            if (!renewalError.requiresReconnect) rethrow;
            failure = renewalError;
          }
        }
        if (!identical(session, auth.session)) throw failure;
        if (identical(auth, MoodleAuthService.instance)) {
          await auth.forgetPersistedSession();
        } else {
          auth.signOut();
        }
        if (auth.session == null &&
            (identical(_cachedSession, session) ||
                identical(_loadingSession, session))) {
          clearCache();
        }
        throw failure;
      }
    }
  }

  Future<MoodleTasksResult> _loadTasks(MoodleSession session) async {
    final response = await auth.call('mod_assign_get_assignments');
    if (response['courses'] is! List) {
      throw const MoodleAuthException('No se pudo leer la lista de tareas.');
    }
    var incomplete = (response['warnings'] as List? ?? []).isNotEmpty;
    final entries =
        <({Map<String, dynamic> task, Map<String, dynamic> course})>[];
    for (final course in response['courses'] as List) {
      for (final task in course['assignments'] as List? ?? []) {
        // Offline activities do not require a student submission.
        if (task['nosubmissions'] == 1) continue;
        entries.add((
          task: Map<String, dynamic>.from(task),
          course: Map<String, dynamic>.from(course)
        ));
      }
    }
    final tasks = <MoodleTask>[];
    // Limit simultaneous requests to avoid flooding the school's server.
    for (var offset = 0; offset < entries.length; offset += 4) {
      final batch = entries.skip(offset).take(4);
      tasks.addAll(await Future.wait(batch.map((entry) async {
        Map<String, dynamic>? status;
        try {
          status = await auth.call('mod_assign_get_submission_status',
              {'assignid': '${entry.task['id']}'});
          if ((status['warnings'] as List? ?? []).isNotEmpty) {
            incomplete = true;
            status = null;
          }
        } on MoodleAuthException catch (error) {
          if (error.requiresReconnect) rethrow;
          incomplete = true;
        }
        final task = MoodleTask.fromJson(
            entry.task, entry.course, status, session.siteUrl);
        if (!task.statusKnown) incomplete = true;
        return task;
      })));
    }
    if (!identical(session, auth.session)) {
      throw const MoodleAuthException(
          'La sesión cambió. Volvé a cargar las tareas.');
    }
    tasks.removeWhere((task) => task.submitted);
    tasks.sort((a, b) {
      if (a.dueDate == null) {
        return b.dueDate == null ? a.id.compareTo(b.id) : 1;
      }
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    final result = MoodleTasksResult(tasks, incomplete: incomplete);
    if (identical(session, auth.session)) {
      _cachedSession = session;
      lastResult = result;
    }
    return result;
  }

  static Future<MoodleTasksResult>? loadCurrentSession() {
    final session = MoodleAuthService.instance.session;
    if (session == null) {
      clearCache();
      return null;
    }
    if (identical(session, _loadingSession) && _inFlight != null) {
      return _inFlight;
    }
    if (!identical(session, _cachedSession)) lastResult = null;
    _loadingSession = session;
    final load = MoodleTasksService().load();
    _inFlight = load;
    // Lifecycle refreshes may have no awaiting caller. Observe failures while
    // leaving the original future available to the UI and manual refreshes.
    load.then((_) {
      if (identical(_inFlight, load)) _inFlight = null;
    }, onError: (Object _, StackTrace __) {
      if (identical(_inFlight, load)) _inFlight = null;
    });
    _loadNotifier.value = load;
    return load;
  }

  static void clearCache() {
    lastResult = null;
    _cachedSession = null;
    _loadingSession = null;
    _inFlight = null;
    _loadNotifier.value = null;
  }
}
