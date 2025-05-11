import 'package:flutter/material.dart';
import 'package:classlift/components/textfield_label.dart';
import '../controller/login_controller.dart';
import '../../forgot_password_screen.dart';

class LoginForm extends StatelessWidget {
  final LoginController controller;
  final double spacing;

  const LoginForm({
    super.key,
    required this.controller,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.loginFormKey,
      child: Column(
        key: const ValueKey('login_form'),
        children: [
          TextfieldLabel().buildLabelAndTextField(
            label: 'Correo electrónico',
            controller: controller.emailController,
            icon: Icons.email,
            obscureText: false,
            obscureTextNotifier: ValueNotifier(false),
            keyboardType: TextInputType.emailAddress,
            focusNode: controller.emailFocusNode,
            nextFocusNode: controller.passwordFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Por favor ingresa un correo electrónico';
              if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$").hasMatch(value)) {
                return 'Por favor ingresa un correo válido';
              }
              return null;
            },
          ),
          SizedBox(height: spacing),
          TextfieldLabel().buildLabelAndTextField(
            label: 'Contraseña',
            controller: controller.passwordController,
            icon: Icons.lock,
            obscureText: true,
            obscureTextNotifier: controller.passwordObscureNotifier,
            focusNode: controller.passwordFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Por favor ingresa una contraseña';
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                );
              },
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: const Color(0xFF333D86),
                  fontSize: controller.getAdaptiveSize(context, defaultSize: 16, smallSize: 14, largeSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}