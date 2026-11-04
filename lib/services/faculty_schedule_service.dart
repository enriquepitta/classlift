import 'dart:convert';

import 'package:classlift/services/database_service.dart';
import 'package:http/http.dart' as http;

class FacultyScheduleCatalog {
  final String id;
  final String period;
  final String plan;
  final DateTime updatedAt;

  const FacultyScheduleCatalog({
    required this.id,
    required this.period,
    required this.plan,
    required this.updatedAt,
  });

  factory FacultyScheduleCatalog.fromJson(Map<String, dynamic> json) =>
      FacultyScheduleCatalog(
        id: json['id'] as String,
        period: json['period'] as String,
        plan: json['plan'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class FacultyScheduleService {
  static const _baseUrl = String.fromEnvironment(
    'CLASSLIFT_SUPABASE_URL',
    defaultValue: 'https://trypmrfuryasyovjdvau.supabase.co',
  );
  // A publishable key only grants the read access enforced by database policies.
  static const _publishableKey = String.fromEnvironment(
    'CLASSLIFT_SUPABASE_KEY',
    defaultValue: 'sb_publishable_nNVRzDyhrcDNUn_6D6YDAw_uM550qCy',
  );
  static const _catalogsCacheKey = 'faculty_schedule_catalogs_v1';

  final http.Client _client;
  final Future<String?> Function(String) _readCache;
  final Future<void> Function(String, String) _writeCache;

  FacultyScheduleService({
    http.Client? client,
    Future<String?> Function(String)? readCache,
    Future<void> Function(String, String)? writeCache,
  })  : _client = client ?? http.Client(),
        _readCache = readCache ?? DatabaseService.getAppSetting,
        _writeCache = writeCache ?? DatabaseService.setAppSetting;

  Future<dynamic> _get(Map<String, String> query) async {
    final uri = Uri.parse('$_baseUrl/rest/v1/faculty_schedule_catalogs')
        .replace(queryParameters: query);
    final response = await _client.get(uri, headers: {
      'apikey': _publishableKey,
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw const FormatException('No se pudieron consultar los horarios.');
    }
    return jsonDecode(response.body);
  }

  Future<List<FacultyScheduleCatalog>> listCatalogs() async {
    String? cached;
    try {
      final data = await _get({
        'select': 'id,period,plan,updated_at,year,term',
        'order': 'year.desc,term.desc,plan.asc',
      }) as List<dynamic>;
      final catalogs = data
          .map((item) => FacultyScheduleCatalog.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList();
      if (catalogs.isEmpty) {
        throw const FormatException('Aún no hay horarios disponibles.');
      }
      await _writeCache(_catalogsCacheKey, jsonEncode(data));
      return catalogs;
    } catch (_) {
      cached = await _readCache(_catalogsCacheKey);
      if (cached == null) rethrow;
      return (jsonDecode(cached) as List<dynamic>)
          .map((item) => FacultyScheduleCatalog.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList();
    }
  }

  Future<Map<String, Map<int, List<String>>>> loadCatalog(String id) async {
    final cacheKey = 'faculty_schedule_catalog_v1_$id';
    Map<String, dynamic> decode(dynamic item) {
      final values = Map<String, dynamic>.from(item as Map);
      if (values.isEmpty) {
        throw const FormatException('El catálogo no contiene carreras.');
      }
      return values;
    }

    Map<String, Map<int, List<String>>> convert(Map<String, dynamic> values) =>
        values.map((career, semesters) => MapEntry(
              career,
              Map<String, dynamic>.from(semesters as Map).map(
                (semester, labels) => MapEntry(
                  int.parse(semester),
                  (labels as List<dynamic>).cast<String>(),
                ),
              ),
            ));

    try {
      final rows = await _get({
        'select': 'careers',
        'id': 'eq.$id',
        'limit': '1',
      }) as List<dynamic>;
      if (rows.length != 1) {
        throw const FormatException('No encontramos ese horario.');
      }
      final data = decode((rows.first as Map)['careers']);
      final result = convert(data);
      await _writeCache(cacheKey, jsonEncode(data));
      return result;
    } catch (_) {
      final cached = await _readCache(cacheKey);
      if (cached == null) rethrow;
      return convert(decode(jsonDecode(cached)));
    }
  }

  void dispose() => _client.close();
}
