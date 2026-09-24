import 'dart:async';

import 'package:classlift/components/textfield_label.dart';
import 'package:classlift/router/app_routes.dart';
import 'package:classlift/screens/login/widgets/login_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final FirebaseAuth? auth;

  const ForgotPasswordScreen({super.key, this.auth});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _obscureNotifier = ValueNotifier(false);
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;
  String? _sentEmail;
  String? _error;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _emailFocusNode.dispose();
    _obscureNotifier.dispose();
    super.dispose();
  }

  void _returnToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _sendResetEmail() async {
    if (_isSending || _resendSeconds > 0) return;
    if (_sentEmail == null && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final email = _sentEmail ?? _emailController.text.trim();
    FocusScope.of(context).unfocus();
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final auth = widget.auth ?? FirebaseAuth.instance;
      await auth.setLanguageCode('es');
      await auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showConfirmation(email);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      // Give the same response whether or not this address has an account.
      if (error.code == 'user-not-found') {
        _showConfirmation(email);
      } else {
        setState(() => _error = switch (error.code) {
              'invalid-email' =>
                'Revisá el correo electrónico e intentá de nuevo.',
              'network-request-failed' =>
                'No pudimos conectarnos. Revisá tu conexión e intentá de nuevo.',
              'too-many-requests' =>
                'Hubo demasiados intentos. Esperá unos minutos antes de volver a intentar.',
              _ => 'No pudimos enviar el enlace. Intentá nuevamente más tarde.',
            });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error =
          'No pudimos enviar el enlace. Intentá nuevamente más tarde.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showConfirmation(String email) {
    _resendTimer?.cancel();
    setState(() {
      _sentEmail = email;
      _resendSeconds = 30;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds = (30 - timer.tick).clamp(0, 30));
      if (_resendSeconds == 0) timer.cancel();
    });
  }

  void _changeEmail() {
    _resendTimer?.cancel();
    setState(() {
      _sentEmail = null;
      _error = null;
      _resendSeconds = 0;
    });
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Correo electrónico',
              style: TextStyle(
                color: Color(0xFF8D9AB6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          AbsorbPointer(
            absorbing: _isSending,
            child: const TextfieldLabel().buildLabelAndTextField(
              glassStyle: true,
              label: 'Correo electrónico',
              controller: _emailController,
              focusNode: _emailFocusNode,
              icon: Icons.email,
              obscureText: false,
              obscureTextNotifier: _obscureNotifier,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Ingresá tu correo electrónico';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return 'Ingresá un correo electrónico válido';
                }
                return null;
              },
            ),
          ),
          if (_error != null) _buildError(),
          const SizedBox(height: 24),
          _RecoveryButton(
            onPressed: _isSending ? null : _sendResetEmail,
            text: 'Enviar enlace',
            isLoading: _isSending,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Semantics(
        liveRegion: true,
        child: Text(_error!,
            style: const TextStyle(color: Color(0xFFA52D40), fontSize: 13)),
      ),
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xBBFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white),
          ),
          child: const Text(
            'Abrí el enlace del correo y elegí una nueva contraseña. Después, volvé a ClassLift para iniciar sesión.\n\nSi no lo encontrás, revisá la carpeta de spam.',
            style:
                TextStyle(color: Color(0xFF526797), fontSize: 14, height: 1.5),
          ),
        ),
        if (_error != null) _buildError(),
        const SizedBox(height: 24),
        _RecoveryButton(onPressed: _returnToLogin, text: 'Volver al login'),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF1555DC)),
          onPressed: _isSending || _resendSeconds > 0 ? null : _sendResetEmail,
          child: Text(_isSending
              ? 'Enviando enlace…'
              : _resendSeconds > 0
                  ? 'Reenviar en ${_resendSeconds}s'
                  : 'Reenviar enlace'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF1555DC)),
          onPressed: _isSending ? null : _changeEmail,
          child: const Text('Usar otro correo'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 740;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFEDF4FF),
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              // The keyboard only changes the scrollable viewport, not the art.
              Positioned.fill(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: size.height,
                  child: SizedBox(
                    height: size.height,
                    child: const Stack(
                      children: [LoginBackground(recovery: true)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: IconButton(
                        tooltip: 'Volver',
                        onPressed: _returnToLogin,
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 26),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 424),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: compact ? 22 : 42),
                                const Text(
                                  'Volvé al\nritmo de tus clases',
                                  style: TextStyle(
                                    color: Color(0xDDEAF3FF),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 40,
                                    child: Divider(
                                      color: Color(0xB3FFFFFF),
                                      thickness: 1.5,
                                    ),
                                  ),
                                ),
                                SizedBox(height: compact ? 32 : 48),
                                Text.rich(
                                  TextSpan(
                                    text: _sentEmail == null
                                        ? 'Recuperar\n'
                                        : 'Revisá tu\n',
                                    children: [
                                      TextSpan(
                                        text: _sentEmail == null
                                            ? 'Contraseña'
                                            : 'correo',
                                        style: const TextStyle(
                                            color: Color(0xFF3479F6)),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    color: const Color(0xFF0A173E),
                                    fontFamily: 'Poppins',
                                    fontSize: size.width < 360 ? 30 : 34,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.8,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _sentEmail == null
                                      ? 'Ingresá el correo electrónico asociado a tu cuenta y te enviaremos un enlace para que puedas restablecerla.'
                                      : 'Si hay una cuenta asociada a $_sentEmail, recibirás un enlace para restablecer tu contraseña.',
                                  style: const TextStyle(
                                    color: Color(0xFF7A8BA8),
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                if (_sentEmail == null)
                                  _buildForm()
                                else
                                  _buildConfirmation(),
                              ],
                            ),
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
      ),
    );
  }
}

class _RecoveryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;

  const _RecoveryButton(
      {required this.onPressed, required this.text, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF539FF5), Color(0xFF518BFF)],
        ),
        border: Border.all(color: const Color(0xFF88B7FC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x335D96EC),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: const StadiumBorder(),
        ),
        child: isLoading
            ? Semantics(
                label: 'Enviando enlace',
                child: const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(text,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: Color(0x337EB4FF),
                      child: Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
