import 'dart:io';

import 'package:classlift/models/career.dart';
import 'package:classlift/services/account_service.dart';
import 'package:classlift/services/database_service.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_credential_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _label = 'Álgebra — Mañana — A — Ana — Lunes:08:00 - 10:00|F1';
const _pendingKey = 'classlift.pending_account_deletion.v1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Directory directory;
  late _Auth auth;
  late _User user;
  late AccountService accounts;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await DatabaseService.close();
    directory =
        await Directory.systemTemp.createTemp('classlift-deletion-test-');
    await databaseFactory.setDatabasesPath(directory.path);
    FlutterSecureStorage.setMockInitialValues({});
    auth = _Auth();
    user = _User(auth, 'alice');
    auth.active = user;
    accounts = AccountService(
        auth: auth,
        googleCredential: () async =>
            GoogleAuthProvider.credential(idToken: 'test'));
    await accounts.prepareCurrentAccount();
    await DatabaseService.saveSelectedSubjects({
      'IIN': [_label]
    }, [
      Career('IIN', 'Informática')
    ], {
      'IIN': {
        1: [_label]
      }
    });
    await MoodleAuthService.instance.persistSession(const MoodleSession(
        siteUrl: 'https://campus.example.edu',
        token: 'test-secret',
        userId: 3,
        fullName: 'Alice'));
  });
  tearDown(() async {
    MoodleAuthService.instance.signOut();
    await DatabaseService.close();
    await directory.delete(recursive: true);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
      'logout preserves planning, removes campus secrets and isolates next login',
      () async {
    await accounts.signOut();
    expect(auth.active, isNull);
    expect(
        await MoodleCredentialStore(accountId: 'alice').readSession(), isNull);
    auth.active = _User(auth, 'bob');
    await accounts.prepareCurrentAccount();
    expect(await DatabaseService.getTotalSubjectsCount(), 0);
    auth.active = user;
    await accounts.prepareCurrentAccount();
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
  });

  test('cancelled verification never deletes data or the Firebase account',
      () async {
    user.reauthError = 'web-context-cancelled';
    await expectLater(
        accounts.deleteCurrentAccount(), throwsA(isA<FirebaseAuthException>()));
    expect(auth.events, ['reauth']);
    expect(auth.active, same(user));
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
    expect(await MoodleCredentialStore(accountId: 'alice').readSession(),
        isNotNull);
  });

  test('remote failure keeps planning and clears the deletion receipt',
      () async {
    user.deleteError = 'network-request-failed';
    await expectLater(
        accounts.deleteCurrentAccount(), throwsA(isA<FirebaseAuthException>()));
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
    expect(await const FlutterSecureStorage().read(key: _pendingKey), isNull);
    expect(auth.active, same(user));
  });

  test(
      'Google deletion authenticates first, deletes Firebase and erases only its local account',
      () async {
    await accounts.deleteCurrentAccount();
    expect(auth.events, ['reauth', 'delete']);
    expect(auth.active, isNull);
    expect(
        await MoodleCredentialStore(accountId: 'alice').readSession(), isNull);
    await DatabaseService.useAccount('alice');
    expect(await DatabaseService.getTotalSubjectsCount(), 0);
    expect(await const FlutterSecureStorage().read(key: _pendingKey), isNull);
  });

  test('Apple deletion revokes authorization before deleting the account',
      () async {
    user.provider = 'apple.com';
    await accounts.deleteCurrentAccount();
    expect(auth.events, ['reauth', 'revoke:apple-code', 'delete']);
  });

  test('revocation failure aborts deletion without deleting planning',
      () async {
    user.provider = 'apple.com';
    auth.revocationFails = true;
    await expectLater(
        accounts.deleteCurrentAccount(), throwsA(isA<FirebaseAuthException>()));
    expect(auth.events, ['reauth', 'revoke:apple-code']);
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
  });

  test(
      'startup finishes local erasure after confirmed server deletion and interruption',
      () async {
    await const FlutterSecureStorage().write(key: _pendingKey, value: 'alice');
    auth.active = null;
    await accounts.recoverPendingDeletion();
    await DatabaseService.useAccount('alice');
    expect(await DatabaseService.getTotalSubjectsCount(), 0);
    expect(
        await MoodleCredentialStore(accountId: 'alice').readSession(), isNull);
    expect(await const FlutterSecureStorage().read(key: _pendingKey), isNull);
  });

  test('an interrupted request that never deleted Firebase keeps local data',
      () async {
    await const FlutterSecureStorage().write(key: _pendingKey, value: 'alice');
    await accounts.recoverPendingDeletion();
    expect(await DatabaseService.getTotalSubjectsCount(), 1);
    expect(auth.events, ['reload']);
    expect(await const FlutterSecureStorage().read(key: _pendingKey), isNull);
  });
}

class _Auth extends Fake implements FirebaseAuth {
  _User? active;
  final events = <String>[];
  bool revocationFails = false;
  @override
  User? get currentUser => active;
  @override
  Future<void> signOut() async => active = null;
  @override
  Future<void> revokeTokenWithAuthorizationCode(String code) async {
    events.add('revoke:$code');
    if (revocationFails) {
      throw FirebaseAuthException(code: 'network-request-failed');
    }
  }
}

class _User extends Fake implements User {
  _User(this.auth, this.uid);
  final _Auth auth;
  @override
  final String uid;
  String provider = 'google.com';
  String? reauthError;
  String? deleteError;
  @override
  List<UserInfo> get providerData => [_Info(provider)];
  Future<UserCredential> _verify() async {
    auth.events.add('reauth');
    if (reauthError != null) throw FirebaseAuthException(code: reauthError!);
    return _Credential(this);
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
          AuthCredential credential) =>
      _verify();
  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) =>
      _verify();
  @override
  Future<void> reload() async => auth.events.add('reload');
  @override
  Future<void> delete() async {
    auth.events.add('delete');
    if (deleteError != null) throw FirebaseAuthException(code: deleteError!);
    auth.active = null;
  }
}

class _Info extends Fake implements UserInfo {
  _Info(this.providerId);
  @override
  final String providerId;
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);
  @override
  final User user;
  @override
  AdditionalUserInfo? get additionalUserInfo => _AdditionalInfo();
}

class _AdditionalInfo extends Fake implements AdditionalUserInfo {
  @override
  String? get authorizationCode => 'apple-code';
}
