import 'package:classlift/screens/splash_screen.dart';
import 'package:classlift/widgets/classlift_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class SplashTestAuth extends Fake implements FirebaseAuth {
  final bool signedIn;
  SplashTestAuth({this.signedIn = false});

  @override
  User? get currentUser => signedIn ? _TestUser() : null;
}

class _TestUser extends Fake implements User {}

void main() {
  for (final signedIn in [false, true]) {
    testWidgets('Splash routes correctly when signedIn=$signedIn',
        (tester) async {
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: SplashScreen(auth: SplashTestAuth(signedIn: signedIn)))),
        GoRoute(
            path: '/login',
            builder: (_, __) =>
                const Scaffold(body: Text('Login destination'))),
        GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('Home destination'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.byType(ClassliftLogo), findsOneWidget);
      expect(find.text('ClassLift'), findsOneWidget);
      expect(find.text('Tu vida universitaria,\nen orden.'), findsOneWidget);
      // No blank first frame while waiting for either an SVG or a fade-in.
      for (final target in [
        find.byType(ClassliftLogo),
        find.text('ClassLift'),
        find.text('Tu vida universitaria,\nen orden.')
      ]) {
        expect(
            tester
                .widgetList<Opacity>(
                    find.ancestor(of: target, matching: find.byType(Opacity)))
                .every((widget) => widget.opacity == 1),
            isTrue);
        expect(
            tester
                .widgetList<FadeTransition>(find.ancestor(
                    of: target, matching: find.byType(FadeTransition)))
                .every((widget) => widget.opacity.value == 1),
            isTrue);
        expect(tester.getSize(target).isEmpty, isFalse);
      }
      expect(
          find.descendant(
              of: find.byType(ClassliftLogo),
              matching: find.byType(CustomPaint)),
          findsOneWidget);
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 1049));
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(signedIn ? 'Home destination' : 'Login destination'),
          findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('Splash fits $size and cancels navigation when disposed',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester
          .pumpWidget(MaterialApp(home: SplashScreen(auth: SplashTestAuth())));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('A delayed entrance cannot navigate before the content is shown',
      (tester) async {
    final ticking = ValueNotifier(false);
    addTearDown(ticking.dispose);
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: ValueListenableBuilder<bool>(
                  valueListenable: ticking,
                  builder: (_, enabled, __) => TickerMode(
                    enabled: enabled,
                    child: SplashScreen(auth: SplashTestAuth()),
                  ),
                ),
              )),
      GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Login destination'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Login destination'), findsNothing);
    ticking.value = true;
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 16));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1050));
    await tester.pumpAndSettle();
    expect(find.text('Login destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion presents the logo immediately', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: SplashScreen(auth: SplashTestAuth()),
      ),
    ));
    final opacities = tester.widgetList<Opacity>(find.ancestor(
        of: find.byType(ClassliftLogo), matching: find.byType(Opacity)));
    expect(opacities.every((widget) => widget.opacity == 1), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
