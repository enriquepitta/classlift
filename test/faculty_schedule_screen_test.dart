import 'dart:convert';

import 'package:classlift/screens/faculty_schedule_screen.dart';
import 'package:classlift/screens/select_career.dart';
import 'package:classlift/services/faculty_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('elige plan y continúa a las carreras publicadas',
      (tester) async {
    final cache = <String, String>{};
    final service = FacultyScheduleService(
      client: MockClient((request) async {
        final data = request.url.queryParameters['select'] == 'careers'
            ? [
                {
                  'careers': {
                    'IIN': {
                      '1': ['Álgebra — Mañana — MI']
                    }
                  }
                }
              ]
            : [
                {
                  'id': '2026-2-new',
                  'period': 'Segundo período 2026',
                  'plan': 'Plan 2026',
                  'updated_at': '2026-08-03T12:00:00Z',
                },
                {
                  'id': '2026-2-previous',
                  'period': 'Segundo período 2026',
                  'plan': 'Planes anteriores',
                  'updated_at': '2026-08-03T12:00:00Z',
                },
              ];
        return http.Response(jsonEncode(data), 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }),
      readCache: (key) async => cache[key],
      writeCache: (key, value) async => cache[key] = value,
    );
    addTearDown(service.dispose);
    await tester
        .pumpWidget(MaterialApp(home: FacultyScheduleScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.text('Segundo período 2026'), findsOneWidget);
    expect(find.text('Plan 2026'), findsOneWidget);
    await tester.tap(find.text('Plan 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir carrera'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectCareerScreen), findsOneWidget);
    expect(find.text('Ingeniería en Informática'), findsOneWidget);
    expect(find.text('Ingeniería en Electricidad'), findsNothing);
  });
}
