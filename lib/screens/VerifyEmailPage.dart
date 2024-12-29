import 'dart:async';
import 'package:flutter/material.dart';
import 'package:classify/components/background_gradient.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email; // Recibimos el correo electrónico como parámetro
  const VerifyEmailPage({super.key, required this.email});

  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final TextEditingController _otpController1 = TextEditingController();
  final TextEditingController _otpController2 = TextEditingController();
  final TextEditingController _otpController3 = TextEditingController();
  final TextEditingController _otpController4 = TextEditingController();

  bool _isResendEnabled = false; // Controla si se puede reenviar el código
  late Timer _timer;
  int _timeRemaining = 30;

  @override
  void initState() {
    super.initState();
    _startTimer(); // Inicia el temporizador para el botón de reenviar
  }

  @override
  void dispose() {
    _otpController1.dispose();
    _otpController2.dispose();
    _otpController3.dispose();
    _otpController4.dispose();
    _timer.cancel();
    super.dispose();
  }

  // Función para iniciar el temporizador
  void _startTimer() {
    _timeRemaining = 30;
    _isResendEnabled = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _isResendEnabled = true;
          _timer.cancel();
        }
      });
    });
  }

  // Función para verificar si todos los campos están completos
  bool _isOtpComplete() {
    return _otpController1.text.isNotEmpty &&
        _otpController2.text.isNotEmpty &&
        _otpController3.text.isNotEmpty &&
        _otpController4.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // Obtiene la altura del teclado visible
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            const Text(
                              'Por favor verificá tu correo',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Hemos enviado un código al correo ${widget.email}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildOtpTextField(controller: _otpController1),
                                _buildOtpTextField(controller: _otpController2, previousController: _otpController1),
                                _buildOtpTextField(controller: _otpController3, previousController: _otpController2),
                                _buildOtpTextField(controller: _otpController4, previousController: _otpController3),
                              ],
                            ),
                            const SizedBox(height: 0),
                            AnimatedPadding(
                              padding: const EdgeInsets.only(top: 20.0),
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: _isOtpComplete()
                                      ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: const Offset(0, 4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isOtpComplete()
                                      ? () {
                                    print("Verificar código OTP");
                                  }
                                      : null,
                                  child: const Text('Verificar'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                    backgroundColor: _isOtpComplete()
                                        ? const Color(0xFF4E7AB5)
                                        : const Color(0xFFA3C1E2),
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(fontSize: 16.0),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: 20.0,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _isResendEnabled
                          ? () {
                        _startTimer();
                      }
                          : null,
                      child: Text.rich(
                        TextSpan(
                          text: _isResendEnabled ? "Reenviar código" : "Reenviar en ",
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
                                color: Colors.black, // Color negro para los segundos
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

  Widget _buildOtpTextField({
    required TextEditingController controller,
    TextEditingController? previousController,
  }) {
    return SizedBox(
      width: 70,
      height: 70, // Incrementamos la altura
      child: TextField(
        controller: controller,
        maxLength: 1,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        onChanged: (value) {
          setState(() {}); // Actualiza la UI para habilitar o deshabilitar el botón
          if (value.length == 1) {
            FocusScope.of(context).nextFocus(); // Avanza al siguiente campo
          } else if (value.isEmpty && previousController != null) {
            FocusScope.of(context).previousFocus(); // Retrocede al campo anterior si está vacío
          }
        },
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26, // Aumenta el tamaño del texto
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF0F0F0), // Fondo claro
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4C9AFF), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(15), // Espaciado interno
          hintText: '',
          hintStyle: const TextStyle(
            fontSize: 20,
            color: Color(0xFF979797),
          ),
        ),
      ),
    );
  }
}