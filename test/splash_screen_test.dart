import 'package:classlift/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash starts at the native size and fades over the first page',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          child: Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('Continuar'),
              ),
            ),
          ),
        ),
      ),
    );

    final artwork = find.byType(SplashArtwork);
    final logo = find.descendant(of: artwork, matching: find.byType(Image));
    final button = find.text('Continuar');
    double opacity() => tester
        .widget<Opacity>(
          find.ancestor(of: artwork, matching: find.byType(Opacity)).first,
        )
        .opacity;

    expect(tester.widget<Image>(logo).image,
        const AssetImage(SplashArtwork.logoAsset));
    expect(tester.getSize(logo), const Size.square(SplashArtwork.logoSize));
    expect(tester.widget<SplashArtwork>(artwork).logoScale, 1);
    expect(opacity(), 1);
    await tester.tapAt(tester.getCenter(button));
    expect(taps, 0);

    await tester.pump(const Duration(milliseconds: 135));
    expect(
      tester.widget<SplashArtwork>(artwork).logoScale,
      inExclusiveRange(1, 1.045),
    );
    expect(opacity(), inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 135));
    expect(artwork, findsNothing);
    await tester.tap(button);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('The startup artwork is centered at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: SplashArtwork()));
      final logo = find.byType(Image);
      expect(tester.getCenter(logo), size.center(Offset.zero));
      expect(tester.getSize(logo), const Size.square(SplashArtwork.logoSize));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Reduced motion reveals the first page immediately',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SplashScreen(
            child: Scaffold(body: Text('Primera pantalla')),
          ),
        ),
      ),
    );
    expect(find.byType(SplashArtwork), findsNothing);
    expect(find.text('Primera pantalla').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Removing the splash mid-transition disposes the animation',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(child: Scaffold())),
    );
    await tester.pump(const Duration(milliseconds: 90));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
