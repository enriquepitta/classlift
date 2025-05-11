import 'package:classlift/components/background_gradient.dart';
import 'package:classlift/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
    );
  }

  void _navigateToNextScreen() {
    context.go(AppRoutes.login);
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
                    // Configurar el controlador para la animación
                    _animationController
                      ..duration = composition.duration
                      ..forward();

                    // Escuchar el evento de finalización
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