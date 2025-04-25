import 'dart:async';
import 'package:classlift/screens/success_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:classlift/components/background_gradient.dart';
import 'forgot_password_screen.dart';

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isResendEnabled = false; // Control del botón de reenviar
  bool _isVerified = false; // Estado del botón de "Ya verifiqué mi correo"
  int _timeRemaining = 30; // Tiempo restante para reenviar el código
  late Timer _timer;
  late Timer _verificationCheckTimer;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _startTimer(); // Iniciar temporizador para reenviar código
    _startVerificationCheck(); // Iniciar verificación periódica del correo
  }

  // Función para iniciar el temporizador de reenvío
  void _startTimer() {
    setState(() {
      _isResendEnabled = false;
      _timeRemaining = 30;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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

  // Función para verificar periódicamente si el correo está verificado
  void _startVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _auth.currentUser?.reload(); // Actualizar información del usuario
      if (_auth.currentUser?.emailVerified == true) {
        setState(() {
          _isVerified = true; // Habilitar el botón
          getIdToken();
        });
        _verificationCheckTimer.cancel(); // Detener la verificación
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _verificationCheckTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Ocultar teclado
        },
        child: Stack(
          children: [
            const BackgroundGradient(), // Fondo con gradiente

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
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
                            const Text(
                              'Verificá tu correo electrónico',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Te hemos enviado un correo de verificación a la dirección que proporcionaste. Revisa tu bandeja de entrada y confirmá tu dirección de correo electrónico',
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
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: true
                          ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            SuccessScreen(),
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
    // Obtén el ID Token del usuario autenticado
    String? idToken = await user.getIdToken();
    return idToken;
  } else {
    throw Exception("No user is signed in");
  }
}