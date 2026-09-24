import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:classlift/services/database_service.dart';

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
  const MoodleAuthException(this.message, {this.requiresReconnect = false});
}

class MoodleAuthService {
  static final instance = MoodleAuthService();
  static const _storedSessionKey = 'moodle_session';
  final http.Client _client;
  final String siteUrl;

  MoodleSession? session;

  MoodleAuthService({http.Client? client, this.siteUrl = MoodleConfig.siteUrl})
      : _client = client ?? http.Client();

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
        final code = data['errorcode'];
        final requiresReconnect = code == 'invalidtoken' ||
            code == 'accessexception' ||
            code == 'webservice_access_exception' ||
            code == 'servicenotavailable';
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
    final credentials = await _post('/login/token.php', {
      'username': username.trim(),
      'password': password,
      'service': 'moodle_mobile_app',
    });
    final token = credentials['token'];
    if (token is! String || token.isEmpty) {
      throw const MoodleAuthException('Moodle no devolvió un token de acceso.');
    }
    final profile = await _post('/webservice/rest/server.php', {
      'wstoken': token,
      'wsfunction': 'core_webservice_get_site_info',
      'moodlewsrestformat': 'json',
    });
    if (profile['userid'] is! int || profile['fullname'] is! String) {
      throw const MoodleAuthException(
          'No se pudo validar tu perfil de Moodle.');
    }
    return session = MoodleSession(
      siteUrl: siteUrl,
      token: token,
      userId: profile['userid'] as int,
      fullName: profile['fullname'] as String,
    );
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
    final result = await _post(
      '/webservice/rest/server.php',
      {
        ...parameters,
        'wstoken': current.token,
        'wsfunction': function,
        'moodlewsrestformat': 'json',
      },
      baseUrl: current.siteUrl,
    );
    if (!identical(current, session)) {
      throw const MoodleAuthException(
        'La sesión de Moodle cambió. Volvé a conectar EDUCA.',
        requiresReconnect: true,
      );
    }
    return result;
  }

  Future<void> persistSession(MoodleSession value) async {
    session = value;
    await DatabaseService.setAppSetting(
        _storedSessionKey, jsonEncode(value.toJson()));
  }

  Future<MoodleSession?> restoreSession() async {
    final raw = await DatabaseService.getAppSetting(_storedSessionKey);
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

  void signOut() => session = null;
}
