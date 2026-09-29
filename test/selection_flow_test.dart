import 'package:classlift/models/career.dart';
import 'package:classlift/screens/class_schedule.dart';
import 'package:classlift/screens/select_career.dart';
import 'package:classlift/widgets/selection/subject_options_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const algebra = 'Álgebra — Mañana — A — Lic. Ana Ríos — Lunes:08:00 - 10:00|F1';
const programming =
    'Programación — Noche — B — Ing. Luis Vera — Martes:18:00 - 20:00|Lab 2';
const physics =
    'Física — Tarde — Lic. María López — Miércoles:14:00 - 16:00|F3';
const circuits = 'Circuitos — Mañana — A — Ing. Pedro Silva';

final selectionCareers = [
  Career('IIN', 'Ingeniería en Informática'),
  Career('IEK', 'Ingeniería en Electrónica'),
];
const selectionSemesters = {
  'IIN': {
    1: [algebra, programming],
    2: [physics],
  },
  'IEK': {
    1: [circuits],
  },
};

Widget subjectScreen() => SelectSemesterScreen(
      careerSemesters: selectionSemesters,
      selectedCareerCodes: const ['IIN', 'IEK'],
      careers: selectionCareers,
    );

Future<void> showScreen(WidgetTester tester, Widget screen,
    {Size size = const Size(390, 844), double textScale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(fontFamily: 'Poppins'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: screen,
  ));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(find.text(text), 160,
        scrollable: find.byType(Scrollable).first);
  }
  final target = find.text(text).first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> tapSubject(WidgetTester tester, String label) async {
  final target = find.byWidgetPredicate(
      (widget) => widget is SubjectCheckboxTile && widget.title == label);
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 160,
        scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'groups options by subject, shift and section without merging selections',
      (tester) async {
    const morningB =
        'Álgebra — Mañana — B — Lic. Marta Vera — Lunes:10:00 - 12:00|F2';
    const afternoon =
        'Álgebra — Tarde — C — Lic. Nora Pérez — Martes:14:00 - 16:00|F3';
    const nightA =
        'Álgebra — Noche — A — Lic. Luis Ruiz — Miércoles:18:00 - 20:00|F4';
    const unspecified = 'Álgebra — Lic. Clara Gómez — Viernes:08:00 - 10:00|F5';
    const options = [
      nightA,
      unspecified,
      morningB,
      programming,
      afternoon,
      algebra
    ];
    await showScreen(
        tester,
        SelectSemesterScreen(
          careerSemesters: const {
            'IIN': {1: options}
          },
          selectedCareerCodes: const ['IIN'],
          careers: selectionCareers,
        ));
    await tapText(tester, 'Ingeniería en Informática');
    await tapText(tester, 'Semestre 1');
    expect(find.text('2 materias · 6 opciones'), findsOneWidget);
    expect(find.text('Álgebra'), findsOneWidget);
    final group = find.byWidgetPredicate((widget) =>
        widget is SubjectOptionsGroup && widget.subjectName == 'Álgebra');
    expect(find.descendant(of: group, matching: find.text('Mañana')),
        findsOneWidget);
    expect(
      tester
          .widgetList<SubjectCheckboxTile>(find.descendant(
              of: group, matching: find.byType(SubjectCheckboxTile)))
          .map((tile) => tile.title),
      [algebra, morningB, afternoon, nightA, unspecified],
    );
    expect(find.text('Turno sin especificar'), findsOneWidget);
    expect(find.text('Sección sin especificar'), findsOneWidget);
    expect(find.text('Lunes · 10:00 - 12:00'), findsOneWidget);

    await tapSubject(tester, morningB);
    await tapSubject(tester, nightA);
    await tapSubject(tester, unspecified);
    await tapText(tester, 'Continuar');
    var summary = tester.widget<SubjectSummaryBottomSheet>(
        find.byType(SubjectSummaryBottomSheet));
    expect(summary.selectedSubjectsByCareer['IIN'],
        {morningB, nightA, unspecified});
    await tester.tap(find.byTooltip('Volver a la selección'));
    await tester.pumpAndSettle();
    await tapSubject(tester, nightA);
    await tapText(tester, 'Continuar');
    summary = tester.widget<SubjectSummaryBottomSheet>(
        find.byType(SubjectSummaryBottomSheet));
    expect(summary.selectedSubjectsByCareer['IIN'], {morningB, unspecified});
    await tester.tap(find.byTooltip('Volver a la selección'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Seleccionar todo el semestre');
    await tapText(tester, 'Continuar');
    summary = tester.widget<SubjectSummaryBottomSheet>(
        find.byType(SubjectSummaryBottomSheet));
    expect(summary.selectedSubjectsByCareer['IIN'], options.toSet());
    expect(tester.takeException(), isNull);
  });

  testWidgets('career search retains multiple selections and available sheets',
      (tester) async {
    await showScreen(
      tester,
      const SelectCareerScreen(availableSheets: ['IIN', 'IEK', 'IEL']),
    );
    expect(find.text('Técnico Superior en Electrónica'), findsNothing);
    await tapText(tester, 'Ingeniería en Informática');
    await tapText(tester, 'Ingeniería en Electrónica');
    expect(find.text('2 carreras seleccionadas'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'informatica');
    await tester.pumpAndSettle();
    expect(find.text('Ingeniería en Electrónica'), findsNothing);
    expect(
        tester
            .widget<CareerCheckboxTile>(find.byType(CareerCheckboxTile))
            .isSelected,
        isTrue);
    expect(find.text('2 carreras seleccionadas'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'sin resultados');
    await tester.pumpAndSettle();
    expect(find.textContaining('No encontramos esa carrera'), findsOneWidget);
    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<CareerCheckboxTile>(find.byType(CareerCheckboxTile))
          .where((tile) => tile.isSelected)
          .length,
      2,
    );
    await tapText(tester, 'Ingeniería en Informática');
    expect(find.text('1 carrera seleccionada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('career continues to require a selection', (tester) async {
    await showScreen(
        tester, const SelectCareerScreen(availableSheets: ['IIN']));
    await tapText(tester, 'Continuar');
    expect(find.text('Por favor, seleccione al menos una carrera'),
        findsOneWidget);
    expect(find.byType(SelectSemesterScreen), findsNothing);
  });

  testWidgets(
      'subjects retain individual and semester selection in the summary',
      (tester) async {
    await showScreen(tester, subjectScreen());
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);

    await tapText(tester, 'Ingeniería en Informática');
    await tapText(tester, 'Semestre 1');
    await tapSubject(tester, algebra);
    expect(find.text('1 materia seleccionada'), findsWidgets);
    await tapText(tester, 'Seleccionar todo el semestre');
    expect(find.text('2 materias seleccionadas'), findsWidgets);
    await tapText(tester, 'Seleccionar todo el semestre');
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    await tapSubject(tester, programming);

    await tapText(tester, 'Semestre 2');
    await tapSubject(tester, physics);
    await tapText(tester, 'Continuar');
    final summary = tester.widget<SubjectSummaryBottomSheet>(
        find.byType(SubjectSummaryBottomSheet));
    expect(summary.selectedSubjectsByCareer['IIN'], {programming, physics});
    expect(summary.selectedSubjectsByCareer['IEK'], isEmpty);
    expect(summary.getTotalSelectedSubjects(), 2);

    await tester.tap(find.byTooltip('Volver a la selección'));
    await tester.pumpAndSettle();
    final selectedTiles = tester
        .widgetList<SubjectCheckboxTile>(find.byType(SubjectCheckboxTile))
        .where((tile) => tile.isSelected)
        .map((tile) => tile.title);
    expect(selectedTiles, containsAll([programming, physics]));

    await tapText(tester, 'Ingeniería en Informática');
    await tapText(tester, 'Ingeniería en Electrónica');
    await tapText(tester, 'Semestre 1');
    await tapSubject(tester, circuits);
    await tapText(tester, 'Continuar');
    final multipleCareers = tester.widget<SubjectSummaryBottomSheet>(
        find.byType(SubjectSummaryBottomSheet));
    expect(multipleCareers.selectedSubjectsByCareer['IIN'],
        {programming, physics});
    expect(multipleCareers.selectedSubjectsByCareer['IEK'], {circuits});
    expect(multipleCareers.getTotalSelectedSubjects(), 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('summary keeps optional metadata, schedules and save callback',
      (tester) async {
    var saves = 0;
    await showScreen(
      tester,
      Scaffold(
        body: SubjectSummaryBottomSheet(
          selectedSubjectsByCareer: const {
            'IIN': {physics},
          },
          careerSemesters: selectionSemesters,
          careers: selectionCareers,
          onSave: () => saves++,
        ),
      ),
    );
    await tester.ensureVisible(find.text('Física'));
    await tester.pumpAndSettle();
    expect(find.text('Lic. María López'), findsOneWidget);
    expect(find.text('Miércoles'), findsOneWidget);
    expect(find.textContaining('14:00 - 16:00', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('Aula F3', findRichText: true), findsOneWidget);
    await tapText(tester, 'Guardar y ver horario');
    expect(saves, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact screens and larger text keep actions accessible',
      (tester) async {
    await showScreen(tester, subjectScreen(),
        size: const Size(320, 568), textScale: 1.6);
    await tapText(tester, 'Ingeniería en Informática');
    await tapText(tester, 'Semestre 1');
    await tapSubject(tester, programming);
    await tapText(tester, 'Continuar');
    expect(find.byType(SubjectSummaryBottomSheet), findsOneWidget);
    expect(find.text('Guardar y ver horario').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('career search fits a compact screen with the keyboard open',
      (tester) async {
    await showScreen(
        tester, const SelectCareerScreen(availableSheets: ['IIN', 'IEK']),
        size: const Size(320, 568), textScale: 1.2);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byType(TextField), 'informatica');
    await tester.pumpAndSettle();
    expect(find.text('Continuar').hitTestable(), findsOneWidget);
    expect(find.text('Ingeniería en Informática'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
