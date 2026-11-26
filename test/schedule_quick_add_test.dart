import 'package:classlift/widgets/home/schedule_quick_add.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _faculty = find.text('Horarios de la facultad');
final _excel = find.text('Importar desde Excel');
final _add = find.byTooltip('Añadir');

Future<void> _mountMenu(
  WidgetTester tester, {
  required VoidCallback onFaculty,
  required VoidCallback onExcel,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 568);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: const Center(child: Text('Inicio')),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(22),
        child: Align(
          heightFactor: 1,
          alignment: Alignment.centerRight,
          child: ScheduleQuickAdd(onFaculty: onFaculty, onExcel: onExcel),
        ),
      ),
    ),
  ));
}

void main() {
  testWidgets('tap opens both options above the add button with large text',
      (tester) async {
    var facultyCalls = 0;
    await _mountMenu(tester,
        onFaculty: () => facultyCalls++,
        onExcel: () => fail('Must not import'),
        textScale: 2);
    final anchor = tester.getCenter(_add);
    await tester.tap(_add);
    await tester.pumpAndSettle();

    expect(tester.getBottomRight(_faculty).dy, lessThan(anchor.dy));
    expect(
        tester.getCenter(_excel).dx, lessThan(tester.getCenter(_faculty).dx));
    expect(_faculty.hitTestable(), findsOneWidget);
    expect(_excel.hitTestable(), findsOneWidget);
    expect(tester.getCenter(find.byTooltip('Cerrar acciones rápidas')), anchor);

    await tester.tap(_faculty);
    await tester.tap(_faculty);
    await tester.pumpAndSettle();
    expect(facultyCalls, 1);
    expect(_faculty, findsNothing);
  });

  testWidgets('hold, drag and release only runs the option under the finger',
      (tester) async {
    var excelCalls = 0;
    await _mountMenu(tester,
        onFaculty: () => fail('Must not open faculty'),
        onExcel: () => excelCalls++);
    final gesture = await tester.startGesture(tester.getCenter(_add));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Deslizá y soltá'), findsOneWidget);

    await gesture.moveTo(tester.getCenter(_faculty));
    await tester.pump();
    expect(excelCalls, 0);
    await gesture.moveTo(tester.getCenter(_excel));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(excelCalls, 1);
    expect(_excel, findsNothing);
  });

  testWidgets('outside, back and drag release dismiss without an action',
      (tester) async {
    await _mountMenu(tester,
        onFaculty: () => fail('Must not open faculty'),
        onExcel: () => fail('Must not import'));
    final anchor = tester.getCenter(_add);
    const outside = Offset(30, 50);
    final gesture = await tester.startGesture(anchor);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_faculty, findsOneWidget);
    await tester.tapAt(outside);
    await tester.pumpAndSettle();
    expect(_faculty, findsNothing);

    await tester.tap(_add);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_faculty, findsNothing);
    expect(find.text('Inicio'), findsOneWidget);

    final cancelledGesture = await tester.startGesture(anchor);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await cancelledGesture.moveTo(outside);
    await cancelledGesture.up();
    await tester.pumpAndSettle();
    expect(_faculty, findsNothing);
  });
}
