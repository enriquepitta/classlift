import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:classlift/components/background_gradient.dart';
import 'package:classlift/components/textfield_label.dart';
import 'package:classlift/screens/verify_email_screen.dart';
import 'package:go_router/go_router.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // Detecta toques en cualquier lugar fuera del teclado
        onTap: () {
          FocusScope.of(context).unfocus(); // Oculta el teclado
        },
        child: Stack(
          children: [
            const BackgroundGradient(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón de retroceso
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: ClassliftColors.White),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                  ),

                  // Espaciado adicional para mover el contenido más abajo
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: SingleChildScrollView(
                        // Permite desplazar el contenido
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40), // Aumentar el espacio superior

                            // Título
                            const Text(
                              'Recuperar Contraseña',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: ClassliftColors.White,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Descripción
                            const Text(
                              'Ingresá el correo electrónico asociado a tu cuenta y te enviaremos un enlace para que puedas restablecerla.',
                              style: TextStyle(color: ClassliftColors.White),
                            ),
                            const SizedBox(height: 20),

                            // Campo de correo electrónico
                            TextfieldLabel().buildLabelAndTextField(
                              label: 'Correo electrónico',
                              controller: _emailController,
                              icon: Icons.email,
                              obscureText: false,
                              obscureTextNotifier: ValueNotifier<bool>(false),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa un correo electrónico';
                                }
                                if (!RegExp(
                                    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$")
                                    .hasMatch(value)) {
                                  return 'Por favor ingresa un correo electrónico válido';
                                }
                                return null;
                              },
                            ),

                            // Botón "Enviar código"
                            AnimatedPadding(
                              padding: const EdgeInsets.only(top: 20.0),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ClassliftColors.PrimaryColorVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ClassliftColors.recoveryText.withOpacity(0.7),
                                      offset: const Offset(0, 4),
                                      blurRadius: 10,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Navegar a la página de verificación de correo
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VerifyEmailScreen(
                                          email: _emailController.text, // Pasar el correo ingresado
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Enviar código'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                    backgroundColor: ClassliftColors.transparent,
                                    foregroundColor: ClassliftColors.White,
                                    elevation: 0,
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
          ],
        ),
      ),
    );
  }
}