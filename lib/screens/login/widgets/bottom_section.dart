import 'package:flutter/material.dart';
import 'package:classlift/utils/classlift_colors.dart';
import '../controller/login_controller.dart';

class BottomSection extends StatefulWidget {
  final LoginController controller;
  final bool keyboardVisible;

  const BottomSection(
      {super.key, required this.controller, this.keyboardVisible = false});

  @override
  State<BottomSection> createState() => _BottomSectionState();
}

class _BottomSectionState extends State<BottomSection> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final keyboardVisible = widget.keyboardVisible;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
          top: keyboardVisible ? 8 : 16, bottom: keyboardVisible ? 10 : 26),
      child: ValueListenableBuilder<bool>(
        valueListenable: controller.isRegisteringNotifier,
        builder: (context, isRegistering, _) {
          return Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ClassliftColors.PrimaryColor,
                  ClassliftColors.primaryGradientEnd,
                ],
              ),
              border: Border.all(color: ClassliftColors.calendarSurface),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33333D86),
                    blurRadius: 24,
                    offset: Offset(0, 12)),
              ],
            ),
            child: ElevatedButton(
              onPressed: controller.isLoading
                  ? null
                  : () => controller.handleAuthAction((loading) {
                        if (mounted) {
                          setState(() => controller.isLoading = loading);
                        }
                      }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: const StadiumBorder(),
              ),
              child: controller.isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Text(
                            isRegistering ? 'Regístrate' : 'Iniciá sesión',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: Color(0x26FFFFFF),
                            child: Icon(Icons.chevron_right_rounded,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
