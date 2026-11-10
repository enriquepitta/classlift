import 'dart:async';
import 'dart:convert';

import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_credential_store.dart';
import 'package:classlift/services/moodle_tasks_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _session = MoodleSession(
    siteUrl: 'https://campus.example.edu',
    token: 'expired',
    userId: 7,
    fullName: 'Student');
const _account = MoodleRememberedAccount(
    siteUrl: 'https://campus.example.edu',
    userId: 7,
    username: 'student',
    password: 'test-password');
http.Response _json(Object data) => http.Response(jsonEncode(data), 200);
http.Response _expired() =>
    _json({'exception': 'moodle_exception', 'errorcode': 'invalidtoken'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    MoodleTasksService.clearCache();
  });
  tearDown(MoodleTasksService.clearCache);

  MoodleAuthService service(MoodleCredentialStore store,
          Future<http.Response> Function(http.Request) handler,
          {Future<void> Function(MoodleSession)? persist}) =>
      MoodleAuthService(
          client: MockClient(handler),
          credentialStore: store,
          sessionPersistence: persist ?? (_) async {},
          sessionRemoval: () async {});

  Future<http.Response> login(http.Request request) async =>
      request.url.path == '/login/token.php'
          ? _json({'token': 'renewed'})
          : _json({'userid': 7, 'fullname': 'Student'});

  test('only remembers credentials after successful explicit opt-in', () async {
    final store = MoodleCredentialStore();
    final auth = service(store, login);
    await auth.connect(' student ', 'test-password',
        campusUrl: _session.siteUrl, remember: false);
    expect(await store.read(), isNull);
    await auth.connect(' student ', 'test-password',
        campusUrl: _session.siteUrl, remember: true);
    final remembered = (await store.read())!;
    expect(remembered.username, 'student');
    expect(remembered.siteUrl, _session.siteUrl);
    expect(remembered.userId, 7);
    expect(remembered.password, 'test-password');
    await auth.connect('student', 'test-password',
        campusUrl: _session.siteUrl, remember: false);
    expect(await store.read(), isNull);
  });

  test('failed login never saves credentials', () async {
    final store = MoodleCredentialStore();
    final auth = service(store,
        (_) async => _json({'error': 'invalid', 'errorcode': 'invalidlogin'}));
    await expectLater(
        auth.connect('student', 'wrong',
            campusUrl: _session.siteUrl, remember: true),
        throwsA(isA<MoodleAuthException>()));
    expect(await store.read(), isNull);
    expect(auth.session, isNull);
  });

  test(
      'renews an expired session and retries tasks with the new persisted token',
      () async {
    final store = MoodleCredentialStore();
    await store.save(_account);
    var logins = 0;
    var taskRequests = 0;
    MoodleSession? persisted;
    final auth = service(store, (request) async {
      expect(request.url.host, 'campus.example.edu');
      if (request.url.path == '/login/token.php') {
        logins++;
        expect(request.bodyFields['username'], 'student');
        expect(request.bodyFields['password'], 'test-password');
        return _json({'token': 'renewed'});
      }
      if (request.bodyFields['wsfunction'] == 'core_webservice_get_site_info') {
        return login(request);
      }
      taskRequests++;
      return request.bodyFields['wstoken'] == 'expired'
          ? _expired()
          : _json({'courses': []});
    }, persist: (session) async => persisted = session)
      ..session = _session;
    final result = await MoodleTasksService(auth: auth).load();
    expect(result.tasks, isEmpty);
    expect(auth.session!.token, 'renewed');
    expect(persisted, same(auth.session));
    expect(logins, 1);
    expect(taskRequests, 2);
  });

  test(
      'retains remembered account and session when renewal is temporarily offline',
      () async {
    final store = MoodleCredentialStore();
    await store.save(_account);
    final auth = service(
        store,
        (request) async => request.url.path == '/login/token.php'
            ? http.Response('offline', 503)
            : _expired())
      ..session = _session;
    await expectLater(
        MoodleTasksService(auth: auth).load(),
        throwsA(isA<MoodleAuthException>()
            .having((e) => e.requiresReconnect, 'reconnect', false)));
    expect(auth.session, same(_session));
    expect(await store.read(), isNotNull);
  });

  test('changed password stops silent retries and asks to reconnect', () async {
    final store = MoodleCredentialStore();
    await store.save(_account);
    final auth = service(
        store,
        (request) async => request.url.path == '/login/token.php'
            ? _json({'error': 'invalid', 'errorcode': 'invalidlogin'})
            : _expired())
      ..session = _session;
    await expectLater(
        MoodleTasksService(auth: auth).load(),
        throwsA(isA<MoodleAuthException>()
            .having((e) => e.requiresReconnect, 'reconnect', true)));
    expect(auth.session, isNull);
    expect(await store.read(), isNull);
  });

  test('never sends a remembered password to another campus or account',
      () async {
    final store = MoodleCredentialStore();
    await store.save(_account);
    final auth = service(
        store, (_) async => throw StateError('must not contact server'));
    for (final candidate in [
      const MoodleSession(
          siteUrl: 'https://other.example.edu',
          token: 'expired',
          userId: 7,
          fullName: 'Other'),
      const MoodleSession(
          siteUrl: 'https://campus.example.edu',
          token: 'expired',
          userId: 8,
          fullName: 'Other'),
    ]) {
      auth.session = candidate;
      expect(await auth.renewSession(candidate), isNull);
    }
  });

  test('overlapping renewals share one login and logout cancels its result',
      () async {
    final store = MoodleCredentialStore();
    await store.save(_account);
    final response = Completer<http.Response>();
    final started = Completer<void>();
    var logins = 0;
    final auth = service(store, (request) async {
      if (request.url.path == '/login/token.php') {
        logins++;
        started.complete();
        return response.future;
      }
      return login(request);
    })
      ..session = _session;
    final first = auth.renewSession(_session);
    final second = auth.renewSession(_session);
    await started.future;
    await auth.disconnect();
    response.complete(_json({'token': 'renewed'}));
    expect(await first, isNull);
    expect(await second, isNull);
    expect(logins, 1);
    expect(auth.session, isNull);
    expect(await store.read(), isNull);
  });

  test('a rejected replacement token does not cause an endless login loop',
      () async {
    final store = MoodleCredentialStore();
    await store.save(_account);
    var logins = 0;
    final auth = service(store, (request) async {
      if (request.url.path == '/login/token.php') {
        logins++;
        return _json({'token': 'renewed'});
      }
      if (request.bodyFields['wsfunction'] == 'core_webservice_get_site_info') {
        return login(request);
      }
      return _expired();
    })
      ..session = _session;
    await expectLater(MoodleTasksService(auth: auth).load(),
        throwsA(isA<MoodleAuthException>()));
    expect(logins, 1);
    expect(auth.session, isNull);
  });
}
