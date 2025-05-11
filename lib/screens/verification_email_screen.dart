import 'dart:async';
import 'package:classlift/screens/success_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:classlift/components/background_gradient.dart';

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> with SingleTickerProviderStateMixin {
  bool _isResendEnabled = false;
  bool _isVerified = false;
  int _timeRemaining = 30;
  late Timer _timer;
  late Timer _verificationCheckTimer;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔵 Para la animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startVerificationCheck();

    // 🔵 Inicializar animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    // 🔵 Iniciar animación al construir la pantalla
    _animationController.forward();
  }

  void _startTimer() {
    setState(() {
      _isResendEnabled = false;
      _timeRemaining = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _timer.cancel();
          _isResendEnabled = true;
        }
      });
    });
  }

  void _startVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _auth.currentUser?.reload();
      if (_auth.currentUser?.emailVerified == true) {
        setState(() {
          _isVerified = true;
          getIdToken();
        });
        _verificationCheckTimer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _verificationCheckTimer.cancel();
    _animationController.dispose(); // 🔵 Liberar la animación
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? fullName = FirebaseAuth.instance.currentUser?.displayName;
    final String firstName = fullName?.split(' ').first ?? 'Usuario';

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            const BackgroundGradient(),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Center(
                              child: Lottie.asset(
                                'assets/lottie/email_verification_lottie.json',
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 🔵 Fade-in en el saludo
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                '¡Hola, $firstName!',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            const Text(
                              'Verificá tu correo electrónico',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),

                            const Text(
                              'Te hemos enviado un correo de verificación a la dirección que proporcionaste. Revisa tu bandeja de entrada y confirmá tu dirección de correo electrónico.',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 20),

                            const Text(
                              'Después de verificar tu correo, regresa a esta pantalla para continuar con el registro.',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: true
                          ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SuccessScreen(),
                          ),
                        );
                      }
                          : null,
                      child: const Text('Ya verifiqué mi correo'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: _isVerified
                            ? const Color(0xFF4E7AB5)
                            : const Color(0xFF979797),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _isResendEnabled
                          ? () {
                        _auth.currentUser?.sendEmailVerification();
                        _startTimer();
                      }
                          : null,
                      child: Text.rich(
                        TextSpan(
                          text: _isResendEnabled
                              ? "Reenviar correo"
                              : "Reenviar en ",
                          style: TextStyle(
                            color: _isResendEnabled
                                ? const Color(0xFF333D86)
                                : const Color(0xFF979797),
                            fontSize: 16,
                          ),
                          children: _isResendEnabled
                              ? []
                              : [
                            TextSpan(
                              text: "$_timeRemaining",
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            const TextSpan(text: " segundos"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> getIdToken() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return await user.getIdToken();
  } else {
    throw Exception("No user is signed in");
  }
}