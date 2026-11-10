import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MoodleRememberedAccount {
  final String siteUrl;
  final int userId;
  final String username;
  final String password;

  const MoodleRememberedAccount(
      {required this.siteUrl,
      required this.userId,
      required this.username,
      required this.password});
}

/// Only an explicitly remembered account is stored here, never in SQLite.
class MoodleCredentialStore {
  static const _key = 'classlift.moodle.remembered_account.v1';
  final FlutterSecureStorage _storage;
  Future<void> _pending = Future<void>.value();

  MoodleCredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
                synchronizable: false,
              ),
            );

  Future<void> _mutate(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> save(MoodleRememberedAccount account) =>
      _mutate(() => _storage.write(
          key: _key,
          value: jsonEncode({
            'siteUrl': account.siteUrl,
            'userId': account.userId,
            'username': account.username,
            'password': account.password,
          })));

  Future<MoodleRememberedAccount?> read() async {
    await _pending;
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic> ||
          data['siteUrl'] is! String ||
          data['userId'] is! int ||
          data['username'] is! String ||
          data['password'] is! String ||
          (data['username'] as String).isEmpty ||
          (data['password'] as String).isEmpty) {
        throw const FormatException();
      }
      final uri = Uri.tryParse(data['siteUrl'] as String);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException();
      }
      return MoodleRememberedAccount(
          siteUrl: data['siteUrl'] as String,
          userId: data['userId'] as int,
          username: data['username'] as String,
          password: data['password'] as String);
    } on FormatException {
      await delete();
      return null;
    }
  }

  Future<void> delete() => _mutate(() => _storage.delete(key: _key));
}
