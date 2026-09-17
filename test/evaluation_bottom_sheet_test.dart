import 'package:classlift/components/evaluation_bottom_sheet.dart';
import 'package:classlift/models/database_models.dart';
import 'package:classlift/utils/evaluation_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  for (final hasBoard in [false, true]) {
    testWidgets('detalle de evaluación con mesa: $hasBoard', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final board = encodeExamBoard(const [
        ParsedExamBoardMember(name: 'Ana Ríos', role: 'Presidente'),
        ParsedExamBoardMember(name: 'Luis Pérez', role: 'Miembro'),
      ]);
      final evaluation = UpcomingEvaluation(
        subjectName:
            'Administración I — Mañana — A${hasBoard ? ' — $board' : ''}',
        subjectCode: 'ADM',
        careerCode: 'IIN',
        careerName: 'Ingeniería en Informática',
        semester: 3,
        evaluationType: '1.er Parcial',
        date: DateTime(2026, 9, 18),
      );
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showEvaluationBottomSheet(
            context,
            evaluation,
            const Color(0xFFDDF8EC),
            const Color(0xFF3C7960),
          ),
          child: const Text('Abrir'),
        ),
      ))));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Administración I'), findsOneWidget);
      expect(find.text('Viernes 18 de septiembre de 2026'), findsOneWidget);
      expect(find.text('Horario no asignado'), findsOneWidget);
      expect(find.text('Aula no asignada'), findsOneWidget);
      expect(find.text('Mesa examinadora no asignada'),
          hasBoard ? findsNothing : findsOneWidget);
      if (hasBoard) {
        expect(find.text('Ana Ríos'), findsOneWidget);
        expect(find.text('Presidente'), findsOneWidget);
        expect(find.text('Luis Pérez'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byType(EvaluationBottomSheet), findsNothing);
    });
  }
}
