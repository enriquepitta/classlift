import 'package:classlift/screens/login/login_screen.dart';
import 'package:classlift/screens/login/widgets/login_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(() => KeyboardVisibilityTesting.setVisibilityForTesting(false));

  Future<void> showLogin(WidgetTester tester,
      {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, fontFamily: 'Poppins'),
      home: const LoginScreen(),
    ));
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(390, 844), const Size(320, 568)]) {
    testWidgets('Login retains focus, text and actions with keyboard at $size',
        (tester) async {
      await showLogin(tester, size: size);
      final google =
          find.widgetWithText(OutlinedButton, 'Continuar con Google');
      final googleSize = tester.getSize(google);
      final googleState = tester.state(google);
      final email = find.byType(EditableText).first;
      final emailState = tester.state(email);
      await tester.enterText(
          find.byType(TextFormField).first, 'alumno@example.com');
      KeyboardVisibilityTesting.setVisibilityForTesting(true);
      for (final inset in [80.0, 160.0, 260.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.state(email), same(emailState));
        expect(tester.state(google), same(googleState));
        expect(tester.getSize(google), googleSize);
        expect(find.text('O continuá con'), findsOneWidget);
        expect(find.text('Moodle'), findsNothing);
        expect(find.text('Apple'), findsNothing);
        expect(tester.widget<EditableText>(email).focusNode.hasFocus, isTrue);
        expect(
            tester
                .getBottomLeft(
                    find.widgetWithText(ElevatedButton, 'Iniciá sesión'))
                .dy,
            lessThanOrEqualTo(size.height - inset));
      }
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      final password = find.byType(EditableText).last;
      expect(tester.widget<EditableText>(password).focusNode.hasFocus, isTrue);
      await tester.enterText(
          find.byType(TextFormField).last, 'clave de prueba');
      final passwordState = tester.state(password);
      await tester.ensureVisible(find.byTooltip('Mostrar contraseña'));
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pumpAndSettle();
      expect(tester.state(password), same(passwordState));
      expect(tester.widget<EditableText>(password).obscureText, isFalse);
      expect(tester.widget<EditableText>(password).focusNode.hasFocus, isTrue);
      expect(tester.widget<EditableText>(password).controller.text,
          'clave de prueba');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(password).focusNode.hasFocus, isFalse);
      tester.view.resetViewInsets();
      KeyboardVisibilityTesting.setVisibilityForTesting(false);
      await tester.pumpAndSettle();
      expect(tester.state(email), same(emailState));
      expect(tester.widget<EditableText>(email).controller.text,
          'alumno@example.com');
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Moodle'), findsNothing);
      expect(find.text('Apple'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Header expands smoothly when the keyboard closes and can reverse',
      (tester) async {
    await showLogin(tester);
    final header = find.ancestor(
      of: find.byType(LoginTitle),
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    final fullHeight = tester.getSize(header).height;
    final email = find.byType(EditableText).first;
    final emailState = tester.state(email);
    await tester.enterText(
        find.byType(TextFormField).first, 'alumno@example.com');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    final compactHeight = tester.getSize(header).height;
    expect(compactHeight, lessThan(fullHeight));

    tester.view.resetViewInsets();
    await tester.pump();
    expect(tester.getSize(header).height, closeTo(compactHeight, 0.01));
    await tester.pump(const Duration(milliseconds: 80));
    final intermediateHeight = tester.getSize(header).height;
    expect(intermediateHeight, greaterThan(compactHeight));
    expect(intermediateHeight, lessThan(fullHeight));

    // Reopening mid-transition continues from the current size without a jump.
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pump();
    expect(tester.getSize(header).height, closeTo(intermediateHeight, 0.01));
    await tester.pump(const Duration(milliseconds: 220));
    expect(tester.getSize(header).height, closeTo(compactHeight, 0.01));
    tester.view.resetViewInsets();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(tester.getSize(header).height, closeTo(fullHeight, 0.01));
    expect(tester.state(email), same(emailState));
    expect(tester.widget<EditableText>(email).controller.text,
        'alumno@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login validates and registration keeps entered credentials',
      (tester) async {
    await showLogin(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciá sesión'));
    await tester.pumpAndSettle();
    expect(
        find.text('Por favor ingresa un correo electrónico'), findsOneWidget);
    expect(find.text('Por favor ingresa una contraseña'), findsOneWidget);
    await tester.enterText(
        find.byType(TextFormField).first, 'alumno@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'clave de prueba');
    await tester.tap(find.text('¿No tenés una cuenta? Registrate'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.widgetWithText(ElevatedButton, 'Regístrate'), findsOneWidget);
    expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .controller
            .text,
        'alumno@example.com');
    await tester.tap(find.text('¿Ya tenés una cuenta? Iniciá sesión'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .controller
            .text,
        'clave de prueba');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Password recovery retains its route', (tester) async {
    final router = GoRouter(initialLocation: '/login', routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const Scaffold(body: Text('Recuperar cuenta'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperar cuenta'), findsOneWidget);
  });
}
