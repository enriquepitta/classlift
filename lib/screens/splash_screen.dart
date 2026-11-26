import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps the native launch artwork visible while Flutter prepares the first page.
class SplashArtwork extends StatelessWidget {
  const SplashArtwork({super.key, this.logoScale = 1});

  final double logoScale;

  static const backgroundColor = Color(0xFFF2F5FE);
  static const logoAsset = 'assets/images/classlift_splash.png';
  static const logoSize = 144.0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: backgroundColor,
        child: Center(
          child: Transform.scale(
            scale: logoScale,
            child: Image.asset(
              logoAsset,
              width: logoSize,
              height: logoSize,
              semanticLabel: 'ClassLift',
            ),
          ),
        ),
      ),
    );
  }
}

/// Reveals the first page once startup finishes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.child});

  final Widget child;

  static const _duration = Duration(milliseconds: 270);
  static const _logoCurve = Cubic(0.23, 1, 0.32, 1);
  static const _fadeCurve = Interval(0.24, 1, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion ? Duration.zero : _duration,
      child: child,
      builder: (context, progress, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            if (!reduceMotion && progress < 1)
              AbsorbPointer(
                child: BlockSemantics(
                  child: Opacity(
                    opacity: 1 - _fadeCurve.transform(progress),
                    child: SplashArtwork(
                      logoScale: 1 + 0.045 * _logoCurve.transform(progress),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
