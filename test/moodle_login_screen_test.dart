import 'package:classlift/screens/login/moodle_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Campus selection exposes the custom URL field', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MoodleLoginScreen()));
    expect(find.text('Politécnica UNA'), findsOneWidget);
    expect(find.text('URL del campus'), findsNothing);
    await tester.tap(find.text('Politécnica UNA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otro campus Moodle'));
    await tester.pumpAndSettle();
    expect(find.text('URL del campus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Keyboard leaves credentials and connect button visible',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const MaterialApp(home: MoodleLoginScreen()));
    final button = find.widgetWithText(FilledButton, 'Conectar campus');
    final originalBottom = tester.getBottomLeft(button).dy;
    final usernameState = tester.state(find.byType(EditableText).first);
    await tester.tap(find.byType(TextFormField).first);
    await tester.enterText(find.byType(TextFormField).first, 'alumno');
    // The button must move during opening, not only at the final inset.
    for (final inset in [80.0, 160.0, 240.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getBottomLeft(button).dy, lessThanOrEqualTo(844 - inset));
      expect(
          tester.state(find.byType(EditableText).first), same(usernameState));
    }
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(EditableText).first), same(usernameState));
    expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .focusNode
            .hasFocus,
        isTrue);
    expect(find.text('Tu campus, más cerca'), findsOneWidget);
    expect(find.text('Usá la misma cuenta con la que entrás a tu campus.'),
        findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    for (final field in find.byType(TextFormField).evaluate()) {
      final bounds = tester.getRect(find.byWidget(field.widget));
      expect(bounds.top, greaterThanOrEqualTo(56));
      expect(bounds.bottom, lessThan(tester.getTopLeft(button).dy));
    }
    expect(tester.getBottomLeft(button).dy, lessThanOrEqualTo(844 - 336));
    expect(tester.takeException(), isNull);
    final password = find.byType(EditableText).last;
    expect(tester.widget<EditableText>(password).focusNode.hasFocus, isTrue);
    await tester.enterText(find.byType(TextFormField).last, 'clave de prueba');
    final passwordState = tester.state(password);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(tester.state(password), same(passwordState));
    expect(tester.widget<EditableText>(password).obscureText, isFalse);
    expect(tester.widget<EditableText>(password).focusNode.hasFocus, isTrue);
    expect(tester.widget<EditableText>(password).controller.text,
        'clave de prueba');
    await tester.tapAt(const Offset(8, 100));
    await tester.pump();
    expect(tester.widget<EditableText>(password).focusNode.hasFocus, isFalse);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(button).dy, originalBottom);
    expect(tester.state(find.byType(EditableText).first), same(usernameState));
    expect(tester.state(password), same(passwordState));
    expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        'alumno');
  });
}
