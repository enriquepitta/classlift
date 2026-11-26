// Captures the production Flutter widget. Run from the repository root.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:classlift/screens/login/login_screen.dart';
import 'package:classlift/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Capture animated splash from the real Flutter widget',
      (tester) async {
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final font = FontLoader('Poppins');
    for (final weight in ['Regular', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins/Poppins-$weight.ttf'));
    }
    await font.load();
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: RepaintBoundary(
        key: key,
        child: const SplashScreen(child: LoginScreen()),
      ),
    ));
    await tester.runAsync(() => precacheImage(
          const AssetImage(SplashArtwork.logoAsset),
          tester.element(find.byType(SplashScreen)),
        ));
    await tester.pump();
    var previous = 0;
    for (final time in [0, 150, 300, 500, 700, 1000, 1400]) {
      await tester.pump(Duration(milliseconds: time - previous));
      previous = time;
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file =
            File('marketing/classlift-splash/snapshots/flutter-$time.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    debugDisableShadows = true;
  });
}
