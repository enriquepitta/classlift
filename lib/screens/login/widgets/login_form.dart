import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/router/app_routes.dart';
import 'package:classlift/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:classlift/components/textfield_label.dart';
import 'package:go_router/go_router.dart';
import '../controller/login_controller.dart';

class LoginForm extends StatelessWidget {
  final LoginController controller;
  final double spacing; // Mantenemos este parámetro para compatibilidad

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
          // Campo de correo electrónico
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

          // Espaciado entre campos usando ResponsiveUtils
          SizedBox(height: ResponsiveUtils.spacing(context, 'dm')),

          // Campo de contraseña - ahora usando buildLabelAndTextField
          TextfieldLabel().buildLabelAndTextField(
            label: 'Contraseña',
            controller: controller.passwordController,
            icon: Icons.lock,
            obscureText: true,
            obscureTextNotifier: controller.passwordObscureNotifier,
            hintText: 'Ingresá tu contraseña',
            focusNode: controller.passwordFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Por favor ingresa una contraseña';
              return null;
            },
          ),

          // Enlace de contraseña olvidada
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                context.push(AppRoutes.forgotPassword);
              },
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: ClassliftColors.PrimaryColor,
                  fontSize: ResponsiveUtils.fontStyle(context, 'button'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}