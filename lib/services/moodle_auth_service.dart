import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:classlift/services/database_service.dart';
import 'package:classlift/services/moodle_credential_store.dart';

class MoodleConfig {
  static const siteUrl = String.fromEnvironment(
    'MOODLE_URL',
    defaultValue: kReleaseMode
        ? 'https://grado.pol.una.py'
        : 'https://school.moodledemo.net',
  );
}

class MoodleSession {
  final String siteUrl;

  final String token;
  final int userId;
  final String fullName;

  const MoodleSession({
    required this.siteUrl,
    required this.token,
    required this.userId,
    required this.fullName,
  });

  Map<String, Object?> toJson() => {
        'siteUrl': siteUrl,
        'token': token,
        'userId': userId,
        'fullName': fullName,
      };

  factory MoodleSession.fromJson(Map<String, dynamic> json) {
    final siteUrl = json['siteUrl'];
    final token = json['token'];
    final userId = json['userId'];
    final fullName = json['fullName'];
    if (siteUrl is! String ||
        token is! String ||
        userId is! int ||
        fullName is! String ||
        siteUrl.isEmpty ||
        token.isEmpty) {
      throw const FormatException('Invalid Moodle session');
    }
    return MoodleSession(
      siteUrl: siteUrl,
      token: token,
      userId: userId,
      fullName: fullName,
    );
  }
}

class MoodleAuthException implements Exception {
  final String message;
  final bool requiresReconnect;
  final String? code;
  const MoodleAuthException(this.message,
      {this.requiresReconnect = false, this.code});
}

class MoodleAuthService {
  static final instance = MoodleAuthService();
  static const _storedSessionKey = 'moodle_session';
  final http.Client _client;
  final String siteUrl;
  final MoodleCredentialStore _credentialStore;
  final Future<void> Function(MoodleSession)? _sessionPersistence;
  final Future<void> Function()? _sessionRemoval;
  Future<MoodleSession?>? _renewal;
  MoodleSession? _renewingSession;
  int _sessionRevision = 0;

  MoodleSession? session;

  MoodleAuthService(
      {http.Client? client,
      this.siteUrl = MoodleConfig.siteUrl,
      MoodleCredentialStore? credentialStore,
      Future<void> Function(MoodleSession)? sessionPersistence,
      Future<void> Function()? sessionRemoval})
      : _client = client ?? http.Client(),
        _credentialStore = credentialStore ?? MoodleCredentialStore(),
        _sessionPersistence = sessionPersistence,
        _sessionRemoval = sessionRemoval;

  Future<Map<String, dynamic>> _post(String path, Map<String, String> fields,
      {String? baseUrl}) async {
    final effectiveSiteUrl = baseUrl ?? siteUrl;
    final base = Uri.parse(effectiveSiteUrl);
    if (base.scheme != 'https' || base.host.isEmpty) {
      throw const MoodleAuthException('El servidor Moodle debe usar HTTPS.');
    }
    try {
      final response = await _client
          .post(
              Uri.parse(
                  '${effectiveSiteUrl.replaceFirst(RegExp(r'/+$'), '')}$path'),
              body: fields)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw const MoodleAuthException(
            'El servidor Moodle no está disponible. Intentá nuevamente.');
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw const FormatException();
      }
      if (data.containsKey('error') || data.containsKey('exception')) {
        final code = data['errorcode'] as String?;
        // Access/service errors can also mean permissions, IP restrictions or
        // maintenance. They do not establish that the token has expired.
        final requiresReconnect = code == 'invalidtoken';
        throw MoodleAuthException(
          code == 'invalidlogin'
              ? 'Usuario o contraseña incorrectos.'
              : requiresReconnect
                  ? 'Tu sesión de EDUCA venció. Volvé a conectar tu cuenta.'
                  : code == 'username_required' || code == 'password_required'
                      ? 'Ingresá tu usuario y contraseña de Moodle.'
                      : 'Moodle rechazó el acceso. Verificá que tu cuenta tenga '
                          'habilitado el servicio móvil o consultá al administrador.',
          requiresReconnect: requiresReconnect,
          code: code,
        );
      }
      return data;
    } on TimeoutException {
      throw const MoodleAuthException(
          'Moodle tardó demasiado en responder. Intentá nuevamente.');
    } on http.ClientException {
      throw const MoodleAuthException(
          'No se pudo conectar con Moodle. Revisá tu conexión.');
    } on FormatException {
      throw const MoodleAuthException(
          'El servidor no devolvió una respuesta válida de Moodle.');
    }
  }

  Future<MoodleSession> signIn(String username, String password) async {
    session = null;
    return session = await _authenticate(siteUrl, username, password);
  }

  Future<MoodleSession> _authenticate(
      String campusUrl, String username, String password) async {
    final credentials = await _post(
        '/login/token.php',
        {
          'username': username.trim(),
          'password': password,
          'service': 'moodle_mobile_app',
        },
        baseUrl: campusUrl);
    final token = credentials['token'];
    if (token is! String || token.isEmpty) {
      throw const MoodleAuthException('Moodle no devolvió un token de acceso.');
    }
    final profile = await _post(
        '/webservice/rest/server.php',
        {
          'wstoken': token,
          'wsfunction': 'core_webservice_get_site_info',
          'moodlewsrestformat': 'json',
        },
        baseUrl: campusUrl);
    if (profile['userid'] is! int || profile['fullname'] is! String) {
      throw const MoodleAuthException(
          'No se pudo validar tu perfil de Moodle.');
    }
    return MoodleSession(
      siteUrl: campusUrl,
      token: token,
      userId: profile['userid'] as int,
      fullName: profile['fullname'] as String,
    );
  }

  Future<void> connect(String username, String password,
      {required String campusUrl, required bool remember}) async {
    final revision = ++_sessionRevision;
    final value = await _authenticate(campusUrl, username, password);
    if (_sessionRevision != revision) {
      throw const MoodleAuthException('La conexión al campus fue cancelada.');
    }
    try {
      if (remember) {
        await _credentialStore.save(MoodleRememberedAccount(
            siteUrl: value.siteUrl,
            userId: value.userId,
            username: username.trim(),
            password: password));
      } else {
        await _credentialStore.delete();
      }
    } catch (_) {
      throw const MoodleAuthException(
          'No pudimos actualizar la cuenta recordada en este dispositivo. Intentá nuevamente.');
    }
    if (_sessionRevision != revision) {
      throw const MoodleAuthException('La conexión al campus fue cancelada.');
    }
    await persistSession(value);
  }

  Future<MoodleSession?> renewSession(MoodleSession expired) async {
    if (identical(_renewingSession, expired) && _renewal != null) {
      return _renewal;
    }
    if (!identical(session, expired)) return null;
    _renewingSession = expired;
    final future = _renewRememberedSession(expired, _sessionRevision);
    _renewal = future;
    try {
      return await future;
    } finally {
      if (identical(_renewal, future)) {
        _renewal = null;
        _renewingSession = null;
      }
    }
  }

  Future<MoodleSession?> _renewRememberedSession(
      MoodleSession expired, int revision) async {
    bool unchanged() =>
        identical(session, expired) && _sessionRevision == revision;
    MoodleRememberedAccount? account;
    try {
      account = await _credentialStore.read();
    } catch (_) {
      throw const MoodleAuthException(
          'No pudimos acceder a la cuenta recordada. Desbloqueá el dispositivo y reintentá.');
    }
    if (!unchanged() ||
        account == null ||
        account.siteUrl != expired.siteUrl ||
        account.userId != expired.userId) {
      return null;
    }
    late final MoodleSession renewed;
    try {
      renewed = await _authenticate(
          account.siteUrl, account.username, account.password);
    } on MoodleAuthException catch (error) {
      if (unchanged() &&
          const {'invalidlogin', 'passwordisexpired'}.contains(error.code)) {
        await _credentialStore.delete();
        throw const MoodleAuthException(
            'Las credenciales de tu campus cambiaron. Volvé a conectar tu cuenta.',
            requiresReconnect: true);
      }
      rethrow;
    }
    if (!unchanged()) return null;
    if (renewed.userId != expired.userId) {
      await _credentialStore.delete();
      throw const MoodleAuthException('Volvé a conectar tu cuenta del campus.',
          requiresReconnect: true);
    }
    await persistSession(renewed);
    return identical(session, renewed) ? renewed : null;
  }

  Future<void> disconnect() async {
    signOut();
    await _credentialStore.delete();
    if (_sessionRemoval != null) return _sessionRemoval();
    await DatabaseService.deleteAppSetting(_storedSessionKey);
  }

  Future<Map<String, dynamic>> call(String function,
      [Map<String, String> parameters = const {}]) async {
    final current = session;
    if (current == null) {
      throw const MoodleAuthException(
        'Iniciá sesión con Moodle para ver tus tareas.',
        requiresReconnect: true,
      );
    }
    Future<Map<String, dynamic>> request(String name) => _post(
          '/webservice/rest/server.php',
          {
            if (name == function) ...parameters,
            'wstoken': current.token,
            'wsfunction': name,
            'moodlewsrestformat': 'json',
          },
          baseUrl: current.siteUrl,
        );
    late final Map<String, dynamic> result;
    try {
      result = await request(function);
    } on MoodleAuthException catch (error) {
      if (!identical(current, session)) {
        throw const MoodleAuthException(
            'La sesión cambió. Volvé a cargar las tareas.');
      }
      // Moodle deletes expired tokens before returning an ambiguous access
      // error. A profile check distinguishes this from a service restriction.
      if (function != 'core_webservice_get_site_info' &&
          const {'accessexception', 'webservice_access_exception'}
              .contains(error.code)) {
        try {
          await request('core_webservice_get_site_info');
        } on MoodleAuthException catch (verificationError) {
          if (identical(current, session) &&
              verificationError.requiresReconnect) {
            rethrow;
          }
        }
      }
      rethrow;
    }
    if (!identical(current, session)) {
      throw const MoodleAuthException(
        'La sesión cambió. Volvé a cargar las tareas.',
      );
    }
    return result;
  }

  Future<void> persistSession(MoodleSession value) async {
    _sessionRevision++;
    session = value;
    if (_sessionPersistence != null) return _sessionPersistence(value);
    await DatabaseService.setAppSetting(
        _storedSessionKey, jsonEncode(value.toJson()));
  }

  Future<MoodleSession?> restoreSession() async {
    if (session != null) return session;
    final raw = await DatabaseService.getAppSetting(_storedSessionKey);
    // A sign-in may finish while the database read is pending.
    if (session != null) return session;
    if (raw == null) return session;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return session = MoodleSession.fromJson(decoded);
    } catch (_) {
      await DatabaseService.deleteAppSetting(_storedSessionKey);
      session = null;
      return null;
    }
  }

  Future<void> forgetPersistedSession() async {
    session = null;
    await DatabaseService.deleteAppSetting(_storedSessionKey);
  }

  void signOut() {
    _sessionRevision++;
    session = null;
  }
}
