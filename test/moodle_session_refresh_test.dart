import 'dart:async';

import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_tasks_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
      'overlapping refreshes share a request, recover offline and isolate accounts',
      () async {
    var response = Completer<http.Response>();
    final started = Completer<void>();
    var requests = 0;
    await http.runWithClient(() async {
      final auth = MoodleAuthService.instance;
      addTearDown(() {
        auth.signOut();
        MoodleTasksService.clearCache();
      });
      auth.session = const MoodleSession(
          siteUrl: 'https://campus.example.edu',
          token: 'first',
          userId: 1,
          fullName: 'First');
      final first = MoodleTasksService.loadCurrentSession()!;
      final second = MoodleTasksService.loadCurrentSession()!;
      expect(second, same(first));
      await started.future;
      expect(requests, 1);
      response.complete(http.Response('{"courses":[]}', 200));
      final cached = await first;
      expect(MoodleTasksService.lastResult, same(cached));

      response = Completer<http.Response>();
      final offline = MoodleTasksService.loadCurrentSession()!;
      final failure = expectLater(offline, throwsA(isA<MoodleAuthException>()));
      response.complete(http.Response('Unavailable', 503));
      await failure;
      expect(auth.session, isNotNull);
      expect(MoodleTasksService.lastResult, same(cached));

      response = Completer<http.Response>();
      final retry = MoodleTasksService.loadCurrentSession()!;
      response.complete(http.Response('{"courses":[]}', 200));
      await retry;
      expect(requests, 3);

      auth.session = const MoodleSession(
          siteUrl: 'https://campus.example.edu',
          token: 'second',
          userId: 2,
          fullName: 'Second');
      response = Completer<http.Response>();
      final otherAccount = MoodleTasksService.loadCurrentSession()!;
      expect(MoodleTasksService.lastResult, isNull);
      response.complete(http.Response('{"courses":[]}', 200));
      await otherAccount;
    },
        () => MockClient((_) {
              requests++;
      if (!started.isCompleted) started.complete();
              return response.future;
            }));
  });
}
