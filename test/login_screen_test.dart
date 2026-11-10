import 'dart:async';
import 'package:classlift/screens/login/login_screen.dart';
import 'package:classlift/screens/login/controller/login_controller.dart';
import 'package:classlift/screens/login/widgets/bottom_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(320, 568)]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets('Social login fits $size with text scale $textScale',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          builder: (_, child) => MediaQuery(
            data: MediaQueryData(
                size: size, textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const LoginScreen(),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsNothing);
        expect(find.textContaining('Registrate'), findsNothing);
        expect(find.textContaining('contraseña'), findsNothing);
        for (final label in ['Continuar con Google', 'Continuar con Apple']) {
          await tester.ensureVisible(find.text(label));
          expect(find.text(label).hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'Both providers block duplicate requests and recover after cancellation',
      (tester) async {
    final google = Completer<void>();
    final apple = Completer<void>();
    var googleCalls = 0;
    var appleCalls = 0;
    var signedIn = 0;
    late LoginController controller;
    await tester.pumpWidget(MaterialApp(
        home: _ControllerHost(
      create: (context, vsync) => controller = LoginController(
        context,
        vsync: vsync,
        googleOperation: () {
          googleCalls++;
          return google.future;
        },
        appleOperation: () {
          appleCalls++;
          return apple.future;
        },
        onSignedIn: () => signedIn++,
      ),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();
    await controller.signInWithApple();
    expect(googleCalls, 1);
    expect(appleCalls, 0);
    expect(
        tester
            .widget<OutlinedButton>(find.byType(OutlinedButton).last)
            .onPressed,
        isNull);
    google.completeError(FirebaseAuthException(code: 'web-context-cancelled'));
    await tester.pumpAndSettle();
    expect(signedIn, 0);
    await tester.tap(find.text('Continuar con Apple'));
    await tester.pump();
    expect(appleCalls, 1);
    apple.complete();
    await tester.pumpAndSettle();
    expect(signedIn, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Completing sign-in after leaving the screen is safe',
      (tester) async {
    final pending = Completer<void>();
    await tester.pumpWidget(MaterialApp(
        home: _ControllerHost(
      create: (context, vsync) => LoginController(
        context,
        vsync: vsync,
        appleOperation: () => pending.future,
        onSignedIn: () => fail('A disposed screen must not navigate'),
      ),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar con Apple'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _ControllerHost extends StatefulWidget {
  const _ControllerHost({required this.create});
  final LoginController Function(BuildContext, TickerProvider) create;
  @override
  State<_ControllerHost> createState() => _ControllerHostState();
}

class _ControllerHostState extends State<_ControllerHost>
    with SingleTickerProviderStateMixin {
  late final LoginController controller;
  @override
  void initState() {
    super.initState();
    controller = widget.create(context, this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: BottomNavigation(controller: controller));
}
