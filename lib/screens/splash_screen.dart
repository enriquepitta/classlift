import 'dart:async';
import 'dart:math' as math;

import 'package:classlift/router/app_routes.dart';
import 'package:classlift/widgets/classlift_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  final FirebaseAuth? auth;

  const SplashScreen({super.key, this.auth});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _entranceDuration = Duration(milliseconds: 450);
  static const _visibleDuration = Duration(milliseconds: 1050);

  late final AnimationController _animationController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        // Hold the finished composition after it has actually been painted.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _navigationTimer != null) return;
          _navigationTimer = Timer(_visibleDuration, _navigateToNextScreen);
        });
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    final nextRoute = (widget.auth ?? FirebaseAuth.instance).currentUser == null
        ? AppRoutes.login
        : AppRoutes.home;
    context.go(nextRoute);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFEDF4FF),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const IgnorePointer(
              child: CustomPaint(painter: _SplashBackgroundPainter()),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 500;
                  final logoSize = compact ? 100.0 : 144.0;
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) {
                      final progress = _animationController.value;
                      final markProgress = reduceMotion
                          ? 1.0
                          : Curves.easeOutCubic
                              .transform((progress / 0.52).clamp(0.0, 1.0));
                      final titleProgress = reduceMotion
                          ? 1.0
                          : Curves.easeOutCubic.transform(
                              ((progress - 0.12) / 0.48).clamp(0.0, 1.0));
                      return Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.translate(
                                      offset:
                                          Offset(0, 16 * (1 - markProgress)),
                                      child: Transform.scale(
                                        scale: 0.88 + 0.12 * markProgress,
                                        child: _LogoHalo(size: logoSize),
                                      ),
                                    ),
                                    SizedBox(height: compact ? 12 : 24),
                                    Transform.translate(
                                      offset:
                                          Offset(0, 10 * (1 - titleProgress)),
                                      child: Column(
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text.rich(
                                              const TextSpan(
                                                text: 'Class',
                                                children: [
                                                  TextSpan(
                                                    text: 'Lift',
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFF3479F6)),
                                                  ),
                                                ],
                                              ),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: compact ? 40 : 50,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -2.5,
                                                height: 1.15,
                                                color: const Color(0xFF0A173E),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          const Text(
                                            'Tu vida universitaria,\nen orden.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Color(0xFF7185A9),
                                              fontSize: 15,
                                              height: 1.5,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                bottom: compact ? 16 : 36, top: 12),
                            child: Semantics(
                              label: 'Cargando ClassLift',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  final intensity = reduceMotion
                                      ? 0.55
                                      : 0.35 +
                                          0.65 *
                                              (math.sin(progress * math.pi * 3 -
                                                      index * 0.8) +
                                                  1) /
                                              2;
                                  return Opacity(
                                    opacity: intensity,
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF5F8FD9),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoHalo extends StatelessWidget {
  final double size;

  const _LogoHalo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size * 1.65,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xBBFFFFFF), Color(0x22FFFFFF)],
              ),
              border: Border.all(color: const Color(0x77FFFFFF)),
            ),
          ),
          Container(
            width: size * 1.35,
            height: size * 1.35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x99FFFFFF)),
            ),
          ),
          ClassliftLogo(size: size),
        ],
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  const _SplashBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFCBDEFB),
            Color(0xFFF4F8FF),
            Color(0xFFF6F9FF),
            Color(0xFFD2E4FF)
          ],
          stops: [0, 0.36, 0.62, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.scale(size.width / 400, size.height / 870);
    final upperWave = Path()
      ..moveTo(232, 0)
      ..cubicTo(232, 142, 315, 138, 400, 242)
      ..lineTo(400, 0)
      ..close();
    canvas.drawPath(
      upperWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0x995E94E7), Color(0x115E94E7)],
        ).createShader(const Rect.fromLTWH(232, 0, 168, 242)),
    );
    final lowerWave = Path()
      ..moveTo(0, 665)
      ..cubicTo(99, 695, 68, 759, 163, 789)
      ..cubicTo(216, 808, 252, 837, 265, 870)
      ..lineTo(0, 870)
      ..close();
    canvas.drawPath(
      lowerWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x889EC3F7), Color(0xAA87B0EE)],
        ).createShader(const Rect.fromLTWH(0, 665, 265, 205)),
    );
    final line = Paint()
      ..color = const Color(0x99FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(
      Path()
        ..moveTo(-20, 162)
        ..cubicTo(83, 116, 159, 172, 185, 222),
      line,
    );
    for (final offset in [0.0, 24.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(215 + offset, 886)
          ..cubicTo(260 + offset, 775, 330 + offset, 748, 419, 746 + offset),
        line,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SplashBackgroundPainter oldDelegate) => false;
}
