import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../controller/login_controller.dart';

class BottomSection extends StatefulWidget {
  final LoginController controller;

  const BottomSection({super.key, required this.controller});

  @override
  State<BottomSection> createState() => _BottomSectionState();
}

class _BottomSectionState extends State<BottomSection> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    final bottomPadding = controller.isKeyboardVisible
        ? controller.getAdaptiveSize(context, defaultSize: 15.0, smallSize: 10.0, largeSize: 20.0)
        : controller.getAdaptiveSize(context, defaultSize: 30.0, smallSize: 20.0, largeSize: 30.0);

    final buttonHeight = controller.getAdaptiveSize(context, defaultSize: 50.0, smallSize: 45.0, largeSize: 55.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(top: 30, bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF4E7AB5),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA3C1E2).withOpacity(0.5),
                  offset: const Offset(0, 3),
                  blurRadius: 5,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => controller.handleAuthAction((loading) => setState(() => controller.isLoading = loading)),
              child: controller.isLoading
                  ? Lottie.asset('assets/lottie/spinner_4.json', width: 35, height: 35)
                  : Text(
                controller.isRegisteringNotifier.value ? 'Regístrate' : 'Iniciá sesión',
                style: TextStyle(
                  fontSize: controller.getAdaptiveSize(context, defaultSize: 16.0, smallSize: 15.0, largeSize: 17.0),
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, buttonHeight),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}