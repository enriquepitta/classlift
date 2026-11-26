import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'database_service.dart';
import 'moodle_auth_service.dart';
import 'moodle_credential_store.dart';
import 'moodle_tasks_service.dart';
import 'social_auth_service.dart';

class AccountCleanupException implements Exception {}

class AccountService {
  static final instance = AccountService();
  static const _pendingDeletionKey = 'classlift.pending_account_deletion.v1';
  final FirebaseAuth _auth;
  final FlutterSecureStorage _storage;
  final Future<AuthCredential> Function() _googleCredential;
  final http.Client _client;

  AccountService({
    FirebaseAuth? auth,
    FlutterSecureStorage? storage,
    Future<AuthCredential> Function()? googleCredential,
    http.Client? client,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? const FlutterSecureStorage(),
        _googleCredential =
            googleCredential ?? SocialAuthService.googleCredential,
        _client = client ?? http.Client();

  Future<void> prepareCurrentAccount({bool migrateLegacy = false}) async {
    await recoverPendingDeletion();
    final uid = _auth.currentUser?.uid;
    await DatabaseService.useAccount(uid, migrateLegacy: migrateLegacy);
    await MoodleAuthService.instance
        .useAccount(uid, migrateLegacy: migrateLegacy);
    MoodleTasksService.clearCache();
    if (uid != null) await MoodleAuthService.instance.restoreSession();
  }

  Future<void> signOut() async {
    // Disconnect campus secrets, but keep this user's academic database.
    await MoodleAuthService.instance.disconnect();
    MoodleTasksService.clearCache();
    await _auth.signOut();
    await DatabaseService.useAccount(null);
    await MoodleAuthService.instance.useAccount(null);
  }

  Future<void> deleteCurrentAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user');
    final providers = user.providerData.map((provider) => provider.providerId);
    final apple = providers.contains('apple.com');
    late final UserCredential verified;
    if (apple) {
      final provider = AppleAuthProvider();
      verified = kIsWeb
          ? await user.reauthenticateWithPopup(provider)
          : await user.reauthenticateWithProvider(provider);
    } else if (providers.contains('google.com')) {
      verified = kIsWeb
          ? await user.reauthenticateWithPopup(GoogleAuthProvider())
          : await user.reauthenticateWithCredential(await _googleCredential());
    } else {
      throw FirebaseAuthException(code: 'unsupported-provider');
    }
    if (_auth.currentUser?.uid != user.uid || verified.user?.uid != user.uid) {
      throw FirebaseAuthException(code: 'user-mismatch');
    }
    if (apple) await _revokeApple(user, verified);

    // A receipt lets startup finish local erasure after an interrupted delete.
    // Failed/cancelled reauthentication never changes local planning.
    await _storage.write(key: _pendingDeletionKey, value: user.uid);
    try {
      await user.delete();
    } catch (_) {
      await _storage.delete(key: _pendingDeletionKey);
      rethrow;
    }
    try {
      await _eraseLocalAccount(user.uid);
      await _storage.delete(key: _pendingDeletionKey);
    } catch (_) {
      throw AccountCleanupException();
    }
  }

  Future<void> _revokeApple(User user, UserCredential verified) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      final code = verified.additionalUserInfo?.authorizationCode;
      if (code == null || code.isEmpty) {
        throw FirebaseAuthException(code: 'missing-apple-authorization-code');
      }
      await _auth.revokeTokenWithAuthorizationCode(code);
      return;
    }
    // firebase_auth 5.x exposes native revocation only on Apple platforms.
    // Use the same official Identity Toolkit API for an OAuth access token.
    final token = verified.credential?.accessToken;
    if (token == null || token.isEmpty) {
      throw FirebaseAuthException(code: 'missing-apple-access-token');
    }
    final response = await _client
        .post(
          Uri.https('identitytoolkit.googleapis.com',
              '/v2/accounts:revokeToken', {'key': _auth.app.options.apiKey}),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'providerId': 'apple.com',
            'tokenType': 'ACCESS_TOKEN',
            'token': token,
            'idToken': await user.getIdToken(),
            if (_auth.tenantId != null) 'tenantId': _auth.tenantId,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw FirebaseAuthException(code: 'apple-revocation-failed');
    }
  }

  Future<void> _eraseLocalAccount(String uid) async {
    MoodleAuthService.instance.signOut();
    MoodleTasksService.clearCache();
    final secrets = MoodleCredentialStore(accountId: uid);
    await secrets.delete();
    await secrets.deleteSession();
    await DatabaseService.deleteAccountData(uid);
    await MoodleAuthService.instance.useAccount(null);
  }

  Future<void> recoverPendingDeletion() async {
    final uid = await _storage.read(key: _pendingDeletionKey);
    if (uid == null) return;
    final user = _auth.currentUser;
    if (user?.uid == uid) {
      try {
        // The process may have ended before the server accepted deletion.
        await user!.reload();
        await _storage.delete(key: _pendingDeletionKey);
        return;
      } on FirebaseAuthException catch (error) {
        if (error.code != 'user-not-found') {
          rethrow;
        }
        await _auth.signOut();
      }
    }
    await _eraseLocalAccount(uid);
    await _storage.delete(key: _pendingDeletionKey);
  }
}
