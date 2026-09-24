import 'package:flutter/material.dart';
import 'package:classlift/components/textfield_label.dart';
import '../controller/login_controller.dart';

class RegisterForm extends StatelessWidget {
  final LoginController controller;
  final double spacing;

  const RegisterForm({
    super.key,
    required this.controller,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.registerFormKey,
      child: Column(
        key: const ValueKey('register_form'),
        children: [
          const TextfieldLabel().buildLabelAndTextField(
            glassStyle: true,
            label: 'Nombre completo',
            controller: controller.nameController,
            icon: Icons.person,
            obscureText: false,
            obscureTextNotifier: controller.passwordObscureNotifier,
            focusNode: controller.nameFocusNode,
            nextFocusNode: controller.emailFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresá tu nombre';
              }
              return null;
            },
          ),
          SizedBox(height: spacing),
          const TextfieldLabel().buildLabelAndTextField(
            glassStyle: true,
            label: 'Correo electrónico',
            controller: controller.emailController,
            icon: Icons.email,
            obscureText: false,
            obscureTextNotifier: controller.passwordObscureNotifier,
            keyboardType: TextInputType.emailAddress,
            focusNode: controller.emailFocusNode,
            nextFocusNode: controller.passwordFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un correo electrónico';
              }
              if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$")
                  .hasMatch(value)) {
                return 'Por favor ingresa un correo válido';
              }
              return null;
            },
          ),
          SizedBox(height: spacing),
          const TextfieldLabel().buildLabelAndTextField(
            glassStyle: true,
            label: 'Contraseña',
            controller: controller.passwordController,
            icon: Icons.lock,
            obscureText: true,
            obscureTextNotifier: controller.passwordObscureNotifier,
            focusNode: controller.passwordFocusNode,
            nextFocusNode: controller.confirmPasswordFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa una contraseña';
              }
              return null;
            },
          ),
          SizedBox(height: spacing),
          const TextfieldLabel().buildLabelAndTextField(
            glassStyle: true,
            label: 'Confirmar contraseña',
            controller: controller.confirmPasswordController,
            icon: Icons.lock,
            obscureText: true,
            obscureTextNotifier: controller.passwordObscureNotifier,
            focusNode: controller.confirmPasswordFocusNode,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor confirma tu contraseña';
              }
              if (value != controller.passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
