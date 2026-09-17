import 'dart:convert';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('authenticates and validates the profile before retaining the session',
      () async {
    var calls = 0;
    final service = MoodleAuthService(client: MockClient((request) async {
      calls++;
      expect(request.method, 'POST');
      expect(request.url.query, isEmpty);
      if (request.url.path == '/login/token.php') {
        expect(request.bodyFields['username'], 'student');
        expect(request.bodyFields['password'], ' password ');
        expect(request.bodyFields['service'], 'moodle_mobile_app');
        return http.Response('{"token":"test-token"}', 200);
      }
      expect(request.bodyFields['wstoken'], 'test-token');
      expect(request.bodyFields['wsfunction'], 'core_webservice_get_site_info');
      return http.Response('{"userid":3,"fullname":"Test Student"}', 200);
    }));
    final session = await service.signIn(' student ', ' password ');
    expect(calls, 2);
    expect(session.userId, 3);
    expect(service.session, same(session));
    service.signOut();
    expect(service.session, isNull);
  });

  for (final response in [
    http.Response(
        jsonEncode({'error': 'Invalid login', 'errorcode': 'invalidlogin'}),
        200),
    http.Response('<html>Unavailable</html>', 200),
    http.Response('{}', 200),
    http.Response('Unavailable', 503),
  ]) {
    test('rejects failed login: ${response.body}', () async {
      final service =
          MoodleAuthService(client: MockClient((_) async => response));
      await expectLater(service.signIn('student', 'bad'),
          throwsA(isA<MoodleAuthException>()));
      expect(service.session, isNull);
    });
  }

  test('does not retain a token when profile validation fails', () async {
    final service = MoodleAuthService(
        client: MockClient((request) async => http.Response(
            request.url.path == '/login/token.php'
                ? '{"token":"test-token"}'
                : '{"exception":"webservice_access_exception","errorcode":"accessexception"}',
            200)));
    await expectLater(service.signIn('student', 'password'),
        throwsA(isA<MoodleAuthException>()));
    expect(service.session, isNull);
  });
}
