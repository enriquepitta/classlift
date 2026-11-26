import 'package:classlift/utils/options_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openOptions(
  WidgetTester tester, {
  required VoidCallback onExcel,
  VoidCallback? onFaculty,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Builder(
        builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  builder: (_) => OptionsBottomSheet(
                      onExcel: onExcel, onFaculty: onFaculty),
                ),
                child: const Text('Abrir opciones'),
              ),
            )),
  ));
  await tester.tap(find.text('Abrir opciones'));
  await tester.pumpAndSettle();
}

void main() {
  for (final faculty in [false, true]) {
    testWidgets(
        '${faculty ? 'faculty' : 'Excel'} closes once before its action',
        (tester) async {
      var calls = 0;
      await openOptions(tester,
          onExcel: () => calls++, onFaculty: faculty ? () => calls++ : null);
      expect(find.text('Agregar manualmente'), findsNothing);
      expect(find.text('Próximamente'), findsNothing);
      final option = find
          .text(faculty ? 'Horarios de la facultad' : 'Importar desde Excel');
      await tester.ensureVisible(option);
      final point = tester.getCenter(option);
      await tester.tapAt(point);
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.byType(OptionsBottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large text keeps supported options and cancel reachable',
      (tester) async {
    await openOptions(tester,
        onExcel: () {},
        onFaculty: () {},
        size: const Size(320, 568),
        textScale: 2);
    final excel = find.text('Importar desde Excel');
    await tester.scrollUntilVisible(excel, 100,
        scrollable: find.descendant(
            of: find.byType(OptionsBottomSheet),
            matching: find.byType(Scrollable)));
    expect(excel, findsOneWidget);
    expect(find.text('Cancelar').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel dismisses without running an action', (tester) async {
    await openOptions(tester, onExcel: () => fail('Must not import'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(OptionsBottomSheet), findsNothing);
  });
}
