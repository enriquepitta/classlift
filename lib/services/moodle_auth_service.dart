import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
}

class MoodleAuthException implements Exception {
  final String message;
  const MoodleAuthException(this.message);
}

class MoodleAuthService {
  static final instance = MoodleAuthService();
  final http.Client _client;
  final String siteUrl;

  // Tokens stay in memory and are never written to logs or plain-text storage.
  MoodleSession? session;

  MoodleAuthService({http.Client? client, this.siteUrl = MoodleConfig.siteUrl})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _post(
      String path, Map<String, String> fields) async {
    final base = Uri.parse(siteUrl);
    if (base.scheme != 'https' || base.host.isEmpty) {
      throw const MoodleAuthException('El servidor Moodle debe usar HTTPS.');
    }
    try {
      final response = await _client
          .post(Uri.parse('${siteUrl.replaceFirst(RegExp(r'/+$'), '')}$path'),
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
        throw MoodleAuthException(
          code == 'invalidlogin'
              ? 'Usuario o contraseña incorrectos.'
              : code == 'username_required' || code == 'password_required'
                  ? 'Ingresá tu usuario y contraseña de Moodle.'
                  : 'Moodle rechazó el acceso. Verificá que tu cuenta tenga '
                      'habilitado el servicio móvil o consultá al administrador.',
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
          'Iniciá sesión con Moodle para ver tus tareas.');
    }
    final result = await _post('/webservice/rest/server.php', {
      ...parameters,
      'wstoken': current.token,
      'wsfunction': function,
      'moodlewsrestformat': 'json',
    });
    if (!identical(current, session)) {
      throw const MoodleAuthException(
          'La sesión de Moodle cambió. Actualizá las tareas.');
    }
    return result;
  }

  void signOut() => session = null;
}
