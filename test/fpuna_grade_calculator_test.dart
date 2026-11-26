import 'package:classlift/screens/fpuna_grade_calculator_screen.dart';
import 'package:classlift/utils/fpuna_grade_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Percentages support comma and dot without rounding invalid input', () {
    expect(parseFpUnaPercentage(' 78,5 '), 7850);
    expect(parseFpUnaPercentage('78.05'), 7805);
    expect(parseFpUnaPercentage('0'), 0);
    expect(parseFpUnaPercentage('100,00'), 10000);
    for (final invalid in ['', '100.01', '-1', '60.001', 'NaN']) {
      expect(parseFpUnaPercentage(invalid), isNull);
    }
  });

  test('The partial and process carry equal weight in each stage', () {
    final calculation = FpUnaGradeCalculator.fromStages(
      partial1: 7000,
      process1: 9000,
      partial2: 6000,
      process2: 7000,
    );
    expect(calculation.stage1, 80);
    expect(calculation.stage2, 65);
    expect(calculation.pep, 72.5);
    expect(
        calculation.resultWithFinal(6900), (rp: 71.1, roundedRp: 71, grade: 3));
  });

  test('PEP and final minimums apply before rounding RP', () {
    final belowPep = FpUnaGradeCalculator.fromStages(
      partial1: 6000,
      process1: 6000,
      partial2: 6000,
      process2: 5999,
    );
    expect(belowPep.pep, 59.9975);
    expect(belowPep.meetsPepRequirement, isFalse);
    expect(belowPep.resultWithFinal(10000), isNull);
    expect(belowPep.finalRequiredFor(2), isNull);

    const strongPep = FpUnaGradeCalculator.fromPep(10000);
    expect(strongPep.resultWithFinal(4999), isNull);
    expect(
        strongPep.resultWithFinal(5000), (rp: 80.0, roundedRp: 80, grade: 3));
    expect(strongPep.finalRequiredFor(2), 5000);
  });

  test('The target honors the official half-up rounding and EF limits', () {
    const calculation = FpUnaGradeCalculator.fromPep(6000);
    expect(calculation.resultWithFinal(5874)?.grade, 1);
    expect(
        calculation.resultWithFinal(5875), (rp: 59.5, roundedRp: 60, grade: 2));
    expect(calculation.finalRequiredFor(2), 5875);
    expect(calculation.finalRequiredFor(3), 8625);
    expect(calculation.finalRequiredFor(4), isNull);

    final fractionalPep = FpUnaGradeCalculator.fromStages(
      partial1: 6001,
      process1: 6000,
      partial2: 6000,
      process2: 6000,
    );
    expect(fractionalPep.resultWithFinal(5874)?.grade, 1);
    expect(fractionalPep.finalRequiredFor(2), 5875);
  });

  test('Attendance identifies the first available call', () {
    expect(FpUnaGradeCalculator.callByAttendance(4999),
        FpUnaFinalCall.insufficientAttendance);
    expect(FpUnaGradeCalculator.callByAttendance(5000), FpUnaFinalCall.second);
    expect(FpUnaGradeCalculator.callByAttendance(6999), FpUnaFinalCall.second);
    expect(FpUnaGradeCalculator.callByAttendance(7000), FpUnaFinalCall.first);
  });

  testWidgets('On a compact screen the form checks fields above the viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: FpUnaGradeCalculatorScreen()),
    );

    final calculate = find.text('Calcular');
    await tester.ensureVisible(calculate);
    await tester.tap(calculate);
    await tester.pumpAndSettle();
    expect(find.text('Ingresá un porcentaje.'), findsNWidgets(4));
    expect(find.text('Resultado'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Direct PEP displays the estimated grade, call and targets',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FpUnaGradeCalculatorScreen()),
    );
    await tester.tap(find.text('Ya tengo mi PEP'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Si tu planilla ya muestra el PEP').hitTestable(),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'PEP de la materia'),
      '60',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Examen final'),
      '58,75',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Asistencia'),
      '65',
    );
    await tester.tap(find.text('Calcular'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('PEP de 60%'), findsOneWidget);
    expect(find.bySemanticsLabel('Nota estimada 2'), findsOneWidget);
    expect(find.textContaining('El PEP aporta el 60%'), findsOneWidget);
    expect(
        find.textContaining('desde la segunda convocatoria'), findsOneWidget);
    expect(find.text('58,75%'), findsOneWidget);
    await tester.tap(find.text('Editar datos'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresá tus porcentajes').hitTestable(), findsOneWidget);
    expect(find.text('58,75'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Before the final, the maximum grade respects exam eligibility',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FpUnaGradeCalculatorScreen()),
    );
    await tester.tap(find.text('Ya tengo mi PEP'));
    await tester.pumpAndSettle();
    final pep = find.widgetWithText(TextFormField, 'PEP de la materia');
    final attendance = find.widgetWithText(TextFormField, 'Asistencia');
    final calculate = find.text('Calcular');
    final maximum = find.bySemanticsLabel(RegExp('Nota máxima posible'));

    await tester.enterText(pep, '60');
    await tester.tap(calculate);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Nota máxima posible 3'), findsOneWidget);
    expect(find.textContaining('86,25% en el final'), findsOneWidget);
    expect(find.text('Nota estimada'), findsNothing);

    await tester.tap(find.text('Editar datos'));
    await tester.pumpAndSettle();
    await tester.enterText(attendance, '49,99');
    await tester.pump();
    await tester.tap(calculate);
    await tester.pumpAndSettle();
    expect(maximum, findsNothing);
    expect(find.textContaining('necesitás al menos 50% de asistencia'),
        findsOneWidget);

    await tester.tap(find.text('Editar datos'));
    await tester.pumpAndSettle();
    await tester.enterText(attendance, '65');
    await tester.enterText(pep, '59,99');
    await tester.pump();
    await tester.tap(calculate);
    await tester.pumpAndSettle();
    expect(maximum, findsNothing);
    expect(find.textContaining('un PEP de al menos 60%'), findsOneWidget);
  });

  testWidgets('The calculator fits a compact screen with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2),
        ),
        child: FpUnaGradeCalculatorScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final definition = find.textContaining('El PEP es el promedio general');
    expect(definition, findsOneWidget);
    expect(find.text('Por etapas').hitTestable(), findsOneWidget);
    await Scrollable.ensureVisible(tester.element(definition), alignment: 0.5);
    await tester.pumpAndSettle();
    final scrollBounds = tester.getRect(find.byType(SingleChildScrollView));
    expect(scrollBounds.contains(tester.getCenter(definition)), isTrue);
    expect(find.text('Calcular').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
