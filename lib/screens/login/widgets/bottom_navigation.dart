import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controller/login_controller.dart';

class BottomNavigation extends StatelessWidget {
  final LoginController controller;

  const BottomNavigation({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 740;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: Color(0xFFA6B5D2))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('O continuá con',
                  style: TextStyle(color: Color(0xFF7E8EAF), fontSize: 13)),
            ),
            Expanded(child: Divider(color: Color(0xFFA6B5D2))),
          ],
        ),
        SizedBox(height: compact ? 10 : 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: controller.signInWithGoogle,
            icon: SvgPicture.asset('assets/icons/google_icon.svg', height: 22),
            label: const Text('Continuar con Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF13234D),
              backgroundColor: const Color(0x99FFFFFF),
              side: const BorderSide(color: Color(0xFFD8E1F1), width: 1.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: controller.toggleRegistering,
          child: ValueListenableBuilder<bool>(
            valueListenable: controller.isRegisteringNotifier,
            builder: (context, isRegistering, _) {
              return Text.rich(
                TextSpan(
                  text: isRegistering
                      ? '¿Ya tenés una cuenta? '
                      : '¿No tenés una cuenta? ',
                  style:
                      const TextStyle(color: Color(0xFF526797), fontSize: 12),
                  children: [
                    TextSpan(
                      text: isRegistering ? 'Iniciá sesión' : 'Registrate',
                      style: const TextStyle(
                          color: Color(0xFF1555DC),
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ),
        SizedBox(height: compact ? 0 : 18),
      ],
    );
  }
}
