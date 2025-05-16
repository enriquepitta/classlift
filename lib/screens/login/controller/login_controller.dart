import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../utils/error_bottom_sheet.dart';
import '../../home_screen.dart';
import '../../verification_email_screen.dart';

class LoginController {
  final BuildContext context;
  final TickerProvider vsync;

  // Text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Focus nodes
  final nameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  final confirmPasswordFocusNode = FocusNode();

  // Obscure password toggle
  final passwordObscureNotifier = ValueNotifier<bool>(true);

  // Form keys
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();

  // Estado
  final ValueNotifier<bool> isRegisteringNotifier = ValueNotifier(false);
  bool isLoading = false;
  bool isKeyboardVisible = false;

  // Animación
  late final AnimationController _titleAnimationController;
  late final Animation<double> titleAnimation;
  late final KeyboardVisibilityController _keyboardController;
  late final StreamSubscription<bool> _keyboardSubscription;

  LoginController(this.context, {required this.vsync}) {
    _keyboardController = KeyboardVisibilityController();
    isKeyboardVisible = _keyboardController.isVisible;

    _keyboardSubscription = _keyboardController.onChange.listen((visible) {
      isKeyboardVisible = visible;
    });

    _titleAnimationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1000),
    );

    titleAnimation = CurvedAnimation(
      parent: _titleAnimationController,
      curve: Curves.easeInOut,
    );

    _titleAnimationController.forward();
  }

  void dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> handleAuthAction(Function(bool) setLoading) async {
    final isValid = isRegisteringNotifier.value
        ? registerFormKey.currentState?.validate() ?? false
        : loginFormKey.currentState?.validate() ?? false;

    if (!isValid) return;

    setLoading(true);

    try {
      if (isRegisteringNotifier.value) {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await userCredential.user?.updateDisplayName(nameController.text.trim());
        await sendVerificationEmail(userCredential.user);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VerificationScreen()));
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      final message = _getErrorMessage(e.code);
      showErrorBottomSheet(context, message);
    } finally {
      setLoading(false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'El correo ingresado ya está registrado.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      default:
        return 'Ocurrió un error inesperado.';
    }
  }

  void dispose() {
    _keyboardSubscription.cancel();
    _titleAnimationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
  }

  void toggleRegistering() {
    isRegisteringNotifier.value = !isRegisteringNotifier.value;
  }
}

Future<void> sendVerificationEmail(User? user) async {
  if (user != null && !user.emailVerified) {
    await user.sendEmailVerification();
  }
}