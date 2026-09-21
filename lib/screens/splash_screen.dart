import 'package:classlift/components/background_gradient.dart';
import 'package:classlift/router/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 1500);

  late AnimationController _animationController;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    );
  }

  void _navigateToNextScreen() {
    if (!mounted || _didNavigate) return;
    _didNavigate = true;

    final nextRoute = FirebaseAuth.instance.currentUser == null
        ? AppRoutes.login
        : AppRoutes.home;
    context.go(nextRoute);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGradient(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/classlift_splash.json',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  controller: _animationController,
                  onLoaded: (composition) {
                    final animationDuration = composition.duration;
                    _animationController
                      ..duration = animationDuration > _splashDuration
                          ? _splashDuration
                          : animationDuration
                      ..forward();

                    _animationController.addStatusListener((status) {
                      if (status == AnimationStatus.completed) {
                        _navigateToNextScreen();
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
