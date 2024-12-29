import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login_page.dart';
import 'package:firebase_core/firebase_core.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  String _statusMessage = 'Verificando Firebase...';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador de animación
    _animationController = AnimationController(vsync: this);

    // Verificar la inicialización de Firebase
    // _checkFirebaseInitialization();
  }

  void _checkFirebaseInitialization() async {
    try {
      // Verifica si Firebase está inicializado
      if (Firebase.apps.isNotEmpty) {
        setState(() {
          _statusMessage = 'Firebase está inicializado';
        });
      } else {
        setState(() {
          _statusMessage = 'Firebase no está inicializado';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al verificar Firebase: $e';
      });
    }
  }

  void _navigateToNextScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF333D86),
              Color(0xFF333D86),
              Color(0xFF4E7AB5),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/classify_splash.json',
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
              // Text(
              //   _statusMessage,
              //   textAlign: TextAlign.center,
              //   style: const TextStyle(
              //     fontSize: 16,
              //     color: Colors.white,
              //     fontWeight: FontWeight.w600,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}