import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../router/app_routes.dart';
import '../utils/error_bottom_sheet.dart';

enum LoginProvider { google, apple }

class LoginController {
  final BuildContext context;
  final Future<void> Function()? _googleOperation;
  final Future<void> Function()? _appleOperation;
  final VoidCallback? _onSignedIn;
  final activeProvider = ValueNotifier<LoginProvider?>(null);
  bool _googleSignInInitialized = false;
  bool _disposed = false;
  late final AnimationController _titleAnimationController;
  late final Animation<double> titleAnimation;

  LoginController(
    this.context, {
    required TickerProvider vsync,
    Future<void> Function()? googleOperation,
    Future<void> Function()? appleOperation,
    VoidCallback? onSignedIn,
  })  : _googleOperation = googleOperation,
        _appleOperation = appleOperation,
        _onSignedIn = onSignedIn {
    _titleAnimationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 700),
    );
    titleAnimation = CurvedAnimation(
      parent: _titleAnimationController,
      curve: Curves.easeOutCubic,
    );
    _titleAnimationController.forward();
  }

  Future<void> signInWithGoogle() =>
      _signIn(LoginProvider.google, _googleOperation ?? _authenticateGoogle);

  Future<void> signInWithApple() =>
      _signIn(LoginProvider.apple, _appleOperation ?? _authenticateApple);

  Future<void> _authenticateGoogle() async {
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      return;
    }
    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleSignInInitialized = true;
    }
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<void> _authenticateApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(provider);
    } else {
      await FirebaseAuth.instance.signInWithProvider(provider);
    }
  }

  Future<void> _signIn(
      LoginProvider provider, Future<void> Function() operation) async {
    if (_disposed || activeProvider.value != null) return;
    activeProvider.value = provider;
    try {
      await operation();
      if (_disposed || !context.mounted) return;
      if (_onSignedIn != null) {
        _onSignedIn();
      } else {
        context.go(AppRoutes.home);
      }
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return;
      _showError('No se pudo iniciar sesión con Google. Intentá nuevamente.');
    } on FirebaseAuthException catch (error) {
      if (const {
        'canceled',
        'cancelled-popup-request',
        'popup-closed-by-user',
        'web-context-cancelled',
        'user-cancelled',
      }.contains(error.code)) {
        return;
      }
      _showError(switch (error.code) {
        'account-exists-with-different-credential' =>
          'Ya existe una cuenta con este correo. Usá la opción con la que ingresaste antes para conservar tu cuenta.',
        'network-request-failed' =>
          'No pudimos conectarnos. Revisá tu conexión e intentá nuevamente.',
        'operation-not-allowed' =>
          'Esta opción de inicio de sesión todavía no está habilitada. Probá con la otra opción.',
        'user-disabled' => 'Esta cuenta está deshabilitada.',
        _ => 'No se pudo iniciar sesión. Intentá nuevamente.',
      });
    } catch (_) {
      _showError('No se pudo iniciar sesión. Intentá nuevamente.');
    } finally {
      if (!_disposed) activeProvider.value = null;
    }
  }

  void _showError(String message) {
    if (!_disposed && context.mounted) showErrorBottomSheet(context, message);
  }

  void dispose() {
    _disposed = true;
    _titleAnimationController.dispose();
    activeProvider.dispose();
  }
}
