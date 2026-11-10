import 'dart:convert';

import 'package:classlift/services/faculty_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('consulta el catálogo, lo guarda y permite volver a usarlo sin internet',
      () async {
    final cache = <String, String>{};
    final client = MockClient((request) async {
      expect(request.headers['apikey'], isNotEmpty);
      if (request.url.queryParameters['select'] == 'careers') {
        return http.Response(
            jsonEncode([
              {
                'careers': {
                  'IIN': {
                    '1': ['Álgebra — Mañana']
                  }
                }
              }
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }
      return http.Response(
          jsonEncode([
            {
              'id': '2026-2-new',
              'period': 'Segundo período 2026',
              'plan': 'Plan 2026',
              'updated_at': '2026-08-03T12:00:00Z'
            }
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final service = FacultyScheduleService(
      client: client,
      readCache: (key) async => cache[key],
      writeCache: (key, value) async => cache[key] = value,
    );
    final catalogs = await service.listCatalogs();
    expect(catalogs.single.plan, 'Plan 2026');
    expect((await service.loadCatalog(catalogs.single.id))['IIN']![1],
        ['Álgebra — Mañana']);
    service.dispose();

    final offline = FacultyScheduleService(
      client: MockClient((_) async => throw Exception('offline')),
      readCache: (key) async => cache[key],
      writeCache: (key, value) async => cache[key] = value,
    );
    expect((await offline.listCatalogs()).single.id, '2026-2-new');
    expect((await offline.loadCatalog('2026-2-new'))['IIN']![1],
        ['Álgebra — Mañana']);
    offline.dispose();
  });

  test('no reemplaza una copia válida cuando la respuesta está incompleta',
      () async {
    final cache = <String, String>{
      'faculty_schedule_catalog_v1_2026-2-new': jsonEncode({
        'IIN': {
          '1': ['Álgebra — Mañana']
        }
      }),
    };
    final service = FacultyScheduleService(
      client: MockClient((_) async => http.Response('[{"careers":{}}]', 200)),
      readCache: (key) async => cache[key],
      writeCache: (key, value) async => cache[key] = value,
    );
    expect((await service.loadCatalog('2026-2-new'))['IIN']![1],
        ['Álgebra — Mañana']);
    service.dispose();
  });
}
