import 'dart:convert';
import 'dart:io';

import 'package:classlift/models/career.dart';
import 'package:classlift/services/database_service.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_credential_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const algebra = 'Álgebra — Mañana — A — Ana — Lunes:08:00 - 10:00|F1';
const physics = 'Física — Tarde — A — Luis — Martes:14:00 - 16:00|F2';
final careers = [Career('IIN', 'Informática')];
const semesters = {
  'IIN': {
    1: [algebra, physics]
  }
};
const session = MoodleSession(
    siteUrl: 'https://campus.example.edu',
    token: 'sensitive-test-token',
    userId: 7,
    fullName: 'Test Student');
Future<void> add(List<String> subjects) =>
    DatabaseService.saveSelectedSubjects({'IIN': subjects}, careers, semesters);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Directory directory;
  setUp(() async {
    await DatabaseService.close();
    directory =
        await Directory.systemTemp.createTemp('classlift-account-test-');
    await databaseFactory.setDatabasesPath(directory.path);
    FlutterSecureStorage.setMockInitialValues({});
    await DatabaseService.useAccount('alice');
  });
  tearDown(() async {
    await DatabaseService.close();
    await directory.delete(recursive: true);
  });

  test(
      'adding preserves existing classes and repeated additions are idempotent',
      () async {
    await add([algebra]);
    final db = await DatabaseService.database;
    final subject = (await DatabaseService.getSelectedSubjects()).single;
    await db.insert('subject_evaluations', {
      'subject_code': subject.subjectCode,
      'career_code': 'IIN',
      'evaluation_type': 'Parcial',
      'evaluation_date': DateTime(2027).millisecondsSinceEpoch,
    });
    await add([physics]);
    expect(await DatabaseService.getTotalSubjectsCount(), 2);
    expect((await DatabaseService.getAllActiveClasses()).length, 2);
    expect((await db.query('subject_evaluations')).length, 1);
    await add([physics]);
    expect(await DatabaseService.getTotalSubjectsCount(), 2);
    expect((await DatabaseService.getAllActiveClasses()).length, 2);
    expect((await db.query('subject_evaluations')).length, 1);
  });

  test('failed addition rolls back without erasing existing data', () async {
    await add([algebra]);
    final db = await DatabaseService.database;
    await db.execute(
        "CREATE TRIGGER fail_save BEFORE INSERT ON subject_schedules BEGIN SELECT RAISE(ABORT, 'disk write failure'); END");
    await expectLater(add([physics]), throwsA(isA<DatabaseException>()));
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
    expect((await DatabaseService.getAllActiveClasses()).single.subjectName,
        algebra);
  });

  test('switching accounts and restarting preserve and isolate planning',
      () async {
    await add([algebra]);
    await DatabaseService.useAccount(null);
    expect(await DatabaseService.getTotalSubjectsCount(), 0);
    await DatabaseService.useAccount('bob');
    expect(await DatabaseService.getTotalSubjectsCount(), 0);
    await add([physics]);
    await DatabaseService.useAccount('alice');
    await DatabaseService.close();
    expect((await DatabaseService.getSelectedSubjects()).single.subjectName,
        algebra);
    await DatabaseService.deleteAccountData('alice');
    await DatabaseService.useAccount('bob');
    expect((await DatabaseService.getSelectedSubjects()).single.subjectName,
        physics);
  });

  test('legacy data migrates only for the account signed in during upgrade',
      () async {
    await add([algebra]);
    final source = (await DatabaseService.database).path;
    await DatabaseService.close();
    final legacy = p.join(directory.path, 'classlift.db');
    await File(source).copy(legacy);
    await DatabaseService.useAccount('new-login');
    expect(await DatabaseService.getTotalSubjectsCount(), 0);
    expect(await databaseExists(legacy), isTrue);
    await DatabaseService.useAccount('upgrade-owner', migrateLegacy: true);
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
    expect(await databaseExists(legacy), isFalse);
    await DatabaseService.useAccount('other', migrateLegacy: true);
    expect(await DatabaseService.getTotalSubjectsCount(), 0);
  });

  test('Moodle migrates plaintext only after secure write and scrubs SQLite',
      () async {
    await DatabaseService.setAppSetting(
        'moodle_session', jsonEncode(session.toJson()));
    final failing = MoodleAuthService(credentialStore: _FailingStore());
    await expectLater(failing.restoreSession(), throwsStateError);
    expect(failing.session, isNull);
    expect(await DatabaseService.getAppSetting('moodle_session'), isNotNull);
    final store = MoodleCredentialStore(accountId: 'alice');
    final auth = MoodleAuthService(credentialStore: store);
    expect((await auth.restoreSession())?.token, session.token);
    expect(await store.readSession(), contains(session.token));
    expect(await DatabaseService.getAppSetting('moodle_session'), isNull);
    final path = (await DatabaseService.database).path;
    await DatabaseService.close();
    expect(latin1.decode(await File(path).readAsBytes()),
        isNot(contains(session.token)));
  });

  test('an upgrade without a signed-in owner discards unscoped credentials',
      () async {
    final legacy = MoodleCredentialStore();
    await legacy.save(const MoodleRememberedAccount(
        siteUrl: 'https://campus.example.edu',
        userId: 3,
        username: 'previous-owner',
        password: 'test-password'));
    final auth = MoodleAuthService();
    await auth.useAccount(null, migrateLegacy: true);
    await auth.useAccount('next-user', migrateLegacy: true);
    expect(await legacy.read(), isNull);
    expect(await MoodleCredentialStore(accountId: 'next-user').read(), isNull);
  });

  test(
      'new sessions stay secure, isolate accounts and disconnect erases secrets only',
      () async {
    await add([algebra]);
    final store = MoodleCredentialStore(accountId: 'alice');
    final auth = MoodleAuthService(credentialStore: store);
    await auth.persistSession(session);
    expect(await DatabaseService.getAppSetting('moodle_session'), isNull);
    expect(await MoodleCredentialStore(accountId: 'bob').readSession(), isNull);
    final restored = MoodleAuthService(credentialStore: store);
    expect((await restored.restoreSession())?.token, session.token);
    await restored.disconnect();
    expect(await store.readSession(), isNull);
    expect(await store.read(), isNull);
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
  });
}

class _FailingStore extends MoodleCredentialStore {
  @override
  Future<void> saveSession(String json) async =>
      throw StateError('Keychain unavailable');
}
