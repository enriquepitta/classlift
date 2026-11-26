import 'dart:convert';

import 'package:classlift/models/career.dart';
import 'package:classlift/services/database_service.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_credential_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final scope = 'native-qa-${DateTime.now().microsecondsSinceEpoch}';
  final alice = '$scope-alice';
  final bob = '$scope-bob';
  const label = 'Álgebra — Mañana — A — Ana — Lunes:08:00 - 10:00|F1';
  const session = MoodleSession(
      siteUrl: 'https://campus.example.edu',
      token: 'disposable-native-test-token',
      userId: 1,
      fullName: 'QA');

  Future<void> addClass() => DatabaseService.saveSelectedSubjects({
        'IIN': [label]
      }, [
        Career('IIN', 'Informática')
      ], {
        'IIN': {
          1: [label]
        }
      });

  tearDownAll(() async {
    for (final uid in [alice, bob]) {
      final store = MoodleCredentialStore(accountId: uid);
      await store.delete();
      await store.deleteSession();
      await DatabaseService.deleteAccountData(uid);
    }
    await DatabaseService.close();
  });

  testWidgets('native migration and disconnect erase secrets but keep planning',
      (_) async {
    await DatabaseService.useAccount(alice);
    await addClass();
    await DatabaseService.setAppSetting(
        'moodle_session', jsonEncode(session.toJson()));
    final store = MoodleCredentialStore(accountId: alice);
    final auth = MoodleAuthService(credentialStore: store);

    expect((await auth.restoreSession())?.token, session.token);
    expect(await DatabaseService.getAppSetting('moodle_session'), isNull);
    expect(await store.readSession(), contains(session.token));
    await auth.disconnect();
    expect(await store.readSession(), isNull);
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
    await DatabaseService.close();
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
  });

  testWidgets('native account erasure preserves another account', (_) async {
    await DatabaseService.useAccount(bob);
    await addClass();
    await DatabaseService.deleteAccountData(alice);
    await DatabaseService.useAccount(alice);
    expect(await DatabaseService.getTotalSubjectsCount(), 0);
    await DatabaseService.useAccount(bob);
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
  });
}
