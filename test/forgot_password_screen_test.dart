import 'package:classlift/screens/forgot_password_screen.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(() => KeyboardVisibilityTesting.setVisibilityForTesting(false));

  for (final size in [const Size(390, 844), const Size(320, 568)]) {
    testWidgets('Recovery keeps its design and email with keyboard at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));
      await tester.pumpAndSettle();
      final field = find.byType(EditableText);
      final fieldState = tester.state(field);
      final button = find.widgetWithText(ElevatedButton, 'Enviar enlace');
      final originalButtonSize = tester.getSize(button);
      await tester.ensureVisible(field);
      await tester.enterText(find.byType(TextFormField), 'alumno@example.com');
      KeyboardVisibilityTesting.setVisibilityForTesting(true);
      for (final inset in [80.0, 160.0, 260.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pumpAndSettle();
        expect(tester.state(field), same(fieldState));
        expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
        expect(tester.getSize(button), originalButtonSize);
      }
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(button).dy,
          lessThanOrEqualTo(size.height - 260));
      await tester.tapAt(const Offset(8, 200));
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(field).focusNode.hasFocus, isFalse);
      tester.view.resetViewInsets();
      KeyboardVisibilityTesting.setVisibilityForTesting(false);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(field).controller.text,
          'alumno@example.com');
      expect(tester.state(field), same(fieldState));
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> showRecovery(WidgetTester tester, _FakeAuth auth) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(MaterialApp(home: ForgotPasswordScreen(auth: auth)));
    await tester.pumpAndSettle();
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  }

  Future<void> send(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Enviar enlace'));
    await tester.tap(find.text('Enviar enlace'));
    await tester.pump();
  }

  testWidgets('Invalid addresses do not call Firebase', (tester) async {
    final auth = _FakeAuth();
    await showRecovery(tester, auth);
    await send(tester);
    expect(
        tester
            .state<FormFieldState<String>>(find.byType(TextFormField))
            .errorText,
        'Ingresá tu correo electrónico');
    for (final email in ['correo', 'nombre@', 'a b@example.com']) {
      await tester.enterText(find.byType(TextFormField), email);
      await send(tester);
      expect(find.text('Ingresá un correo electrónico válido'), findsOneWidget);
    }
    expect(auth.emails, isEmpty);
  });

  testWidgets(
      'Sends a trimmed email in Spanish, waits, and prevents duplicate requests',
      (tester) async {
    final auth = _FakeAuth()..pending = Completer<void>();
    await showRecovery(tester, auth);
    await tester.enterText(
        find.byType(TextFormField), '  alumno@example.university  ');
    await send(tester);
    expect(auth.emails, ['alumno@example.university']);
    expect(auth.languages, ['es']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    expect(find.text('Revisá tu\ncorreo'), findsNothing);
    await tester.tap(find.byType(ElevatedButton));
    expect(auth.emails, hasLength(1));
    auth.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Revisá tu\ncorreo'), findsOneWidget);
    expect(find.textContaining('alumno@example.university'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Confirmation can resend after cooldown and change the email',
      (tester) async {
    final auth = _FakeAuth();
    await showRecovery(tester, auth);
    await tester.enterText(find.byType(TextFormField), 'primero@example.com');
    await send(tester);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextButton>(
                find.widgetWithText(TextButton, 'Reenviar en 30s'))
            .onPressed,
        isNull);
    await tester.pump(const Duration(seconds: 31));
    await tester.ensureVisible(find.text('Reenviar enlace'));
    await tester.tap(find.text('Reenviar enlace'));
    await tester.pumpAndSettle();
    expect(auth.emails, ['primero@example.com', 'primero@example.com']);
    await tester.ensureVisible(find.text('Usar otro correo'));
    await tester.tap(find.text('Usar otro correo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'segundo@example.com');
    await send(tester);
    await tester.pumpAndSettle();
    expect(auth.emails.last, 'segundo@example.com');
    expect(find.textContaining('segundo@example.com'), findsOneWidget);
  });

  for (final error in [
    (
      'network-request-failed',
      'No pudimos conectarnos. Revisá tu conexión e intentá de nuevo.'
    ),
    (
      'too-many-requests',
      'Hubo demasiados intentos. Esperá unos minutos antes de volver a intentar.'
    ),
    ('invalid-email', 'Revisá el correo electrónico e intentá de nuevo.'),
    (
      'operation-not-allowed',
      'No pudimos enviar el enlace. Intentá nuevamente más tarde.'
    ),
  ]) {
    testWidgets('Firebase ${error.$1} shows an error and permits retry',
        (tester) async {
      final auth = _FakeAuth()..error = FirebaseAuthException(code: error.$1);
      await showRecovery(tester, auth);
      await tester.enterText(find.byType(TextFormField), 'alumno@example.com');
      await send(tester);
      await tester.pumpAndSettle();
      expect(find.text(error.$2), findsOneWidget);
      expect(find.text('Revisá tu\ncorreo'), findsNothing);
      expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          'alumno@example.com');
      auth.error = null;
      await send(tester);
      await tester.pumpAndSettle();
      expect(auth.emails, hasLength(2));
      expect(find.text('Revisá tu\ncorreo'), findsOneWidget);
    });
  }

  testWidgets('Unknown accounts receive the same neutral confirmation',
      (tester) async {
    final auth = _FakeAuth()
      ..error = FirebaseAuthException(code: 'user-not-found');
    await showRecovery(tester, auth);
    await tester.enterText(find.byType(TextFormField), 'alumno@example.com');
    await send(tester);
    await tester.pumpAndSettle();
    expect(find.text('Revisá tu\ncorreo'), findsOneWidget);
    expect(find.textContaining('Si hay una cuenta asociada'), findsOneWidget);
  });

  testWidgets('Leaving during a request does not update disposed state',
      (tester) async {
    final auth = _FakeAuth()..pending = Completer<void>();
    await showRecovery(tester, auth);
    await tester.enterText(find.byType(TextFormField), 'alumno@example.com');
    await send(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    auth.pending!
        .completeError(FirebaseAuthException(code: 'network-request-failed'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Confirmation returns to login', (tester) async {
    final auth = _FakeAuth();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(initialLocation: '/login', routes: [
      GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Login'))),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => ForgotPasswordScreen(auth: auth)),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/forgot-password');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'alumno@example.com');
    await send(tester);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Volver al login'));
    await tester.tap(find.text('Volver al login'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAuth extends Fake implements FirebaseAuth {
  final emails = <String>[];
  final languages = <String?>[];
  Object? error;
  Completer<void>? pending;

  @override
  Future<void> setLanguageCode(String? languageCode) async {
    languages.add(languageCode);
  }

  @override
  Future<void> sendPasswordResetEmail(
      {required String email, ActionCodeSettings? actionCodeSettings}) async {
    emails.add(email);
    if (pending != null) await pending!.future;
    if (error != null) throw error!;
  }
}
