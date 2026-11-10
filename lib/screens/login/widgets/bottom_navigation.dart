import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controller/login_controller.dart';

class BottomNavigation extends StatelessWidget {
  final LoginController controller;

  const BottomNavigation({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LoginProvider?>(
      valueListenable: controller.activeProvider,
      builder: (context, active, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _button(
            provider: LoginProvider.google,
            active: active,
            label: 'Continuar con Google',
            icon: SvgPicture.asset('assets/icons/google_icon.svg', height: 22),
            onPressed: controller.signInWithGoogle,
          ),
          const SizedBox(height: 12),
          _button(
            provider: LoginProvider.apple,
            active: active,
            label: 'Continuar con Apple',
            icon: SvgPicture.asset(
              'assets/icons/apple_icon.svg',
              height: 22,
              color: Colors.white,
            ),
            onPressed: controller.signInWithApple,
          ),
        ],
      ),
    );
  }

  Widget _button({
    required LoginProvider provider,
    required LoginProvider? active,
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    final apple = provider == LoginProvider.apple;
    return OutlinedButton.icon(
      onPressed: active == null ? onPressed : null,
      icon: active == provider
          ? Semantics(
              label: 'Iniciando sesión',
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: apple ? Colors.white : const Color(0xFF333D86),
                ),
              ),
            )
          : icon,
      label: Text(label, textAlign: TextAlign.center),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        foregroundColor: apple ? Colors.white : const Color(0xFF13234D),
        disabledForegroundColor:
            apple ? Colors.white70 : const Color(0xFF526797),
        backgroundColor:
            apple ? const Color(0xFF111111) : const Color(0xDDFFFFFF),
        side: BorderSide(
            color: apple ? const Color(0xFF111111) : const Color(0xFFD8E1F1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(
            fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
