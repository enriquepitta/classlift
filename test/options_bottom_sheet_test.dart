import 'package:classlift/utils/options_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openOptions(
  WidgetTester tester, {
  required VoidCallback onExcel,
  required VoidCallback onManual,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
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
    home: Builder(builder: (context) {
      return Scaffold(
        body: TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            useSafeArea: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => OptionsBottomSheet(
              onExcel: onExcel,
              onManual: onManual,
            ),
          ),
          child: const Text('Abrir opciones'),
        ),
      );
    }),
  ));
  await tester.tap(find.text('Abrir opciones'));
  await tester.pumpAndSettle();
}

void main() {
  for (final manual in [false, true]) {
    testWidgets('${manual ? 'manual' : 'Excel'} closes once before its action',
        (tester) async {
      var excelCalls = 0;
      var manualCalls = 0;
      await openOptions(tester,
          onExcel: () => excelCalls++, onManual: () => manualCalls++);
      final option =
          find.text(manual ? 'Agregar manualmente' : 'Importar desde Excel');
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      final position = tester.getCenter(option);
      await tester.tapAt(position);
      await tester.tapAt(position);
      await tester.pumpAndSettle();
      expect(excelCalls, manual ? 0 : 1);
      expect(manualCalls, manual ? 1 : 0);
      expect(find.byType(OptionsBottomSheet), findsNothing);
      expect(find.text('Abrir opciones'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('close and cancel dismiss without running actions',
      (tester) async {
    var calls = 0;
    await openOptions(tester, onExcel: () => calls++, onManual: () => calls++);
    await tester.tap(find.byTooltip('Cerrar opciones'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionsBottomSheet), findsNothing);
    await tester.tap(find.text('Abrir opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionsBottomSheet), findsNothing);
    expect(calls, 0);
  });

  testWidgets('large text on a compact screen keeps both options accessible',
      (tester) async {
    var manualCalls = 0;
    await openOptions(tester,
        onExcel: () {},
        onManual: () => manualCalls++,
        size: const Size(320, 568),
        textScale: 1.6);
    expect(find.text('Cancelar').hitTestable(), findsOneWidget);
    final manual = find.text('Agregar manualmente');
    await tester.scrollUntilVisible(manual, 120,
        scrollable: find.descendant(
            of: find.byType(OptionsBottomSheet),
            matching: find.byType(Scrollable)));
    await tester.ensureVisible(manual);
    await tester.pumpAndSettle();
    expect(find.text('Próximamente'), findsOneWidget);
    await tester.tap(manual);
    await tester.pumpAndSettle();
    expect(manualCalls, 1);
    expect(find.byType(OptionsBottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
