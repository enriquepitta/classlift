import 'package:flutter/material.dart';
import 'package:classlift/components/sign_button_row.dart';
import '../controller/login_controller.dart';

class BottomNavigation extends StatefulWidget {
  final LoginController controller;

  const BottomNavigation({super.key, required this.controller});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    final bottomSectionPadding = controller.getAdaptiveSize(
      context,
      defaultSize: 20.0,
      smallSize: 16.0,
      largeSize: 24.0,
    );

    final verticalSpacing = controller.getAdaptiveSize(
      context,
      defaultSize: 20.0,
      smallSize: 15.0,
      largeSize: 25.0,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFF4E7AB5)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: bottomSectionPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF333D86), thickness: 1)),
                  Text(' O continuá con ', style: TextStyle(color: Color(0xFF333D86))),
                  Expanded(child: Divider(color: Color(0xFF333D86), thickness: 1)),
                ],
              ),
              SizedBox(height: verticalSpacing),
              SignInButtonsRow(
                onGooglePressed: () => print("Google"),
                onFacebookPressed: () => print("Facebook"),
                onApplePressed: () => print("Apple"),
              ),
              SizedBox(height: verticalSpacing),
              TextButton(
                onPressed: () {
                  controller.isRegisteringNotifier.value = !controller.isRegisteringNotifier.value;
                },
                child: ValueListenableBuilder<bool>(
                  valueListenable: controller.isRegisteringNotifier,
                  builder: (context, isRegistering, _) {
                    return RichText(
                      text: TextSpan(
                        text: isRegistering ? '¿Ya tenés una cuenta? ' : '¿No tenés una cuenta? ',
                        style: TextStyle(
                          color: const Color(0xFF333D86),
                          fontSize: controller.getAdaptiveSize(
                            context,
                            defaultSize: 16.0,
                            smallSize: 14.0,
                            largeSize: 16.0,
                          ),
                          fontFamily: 'Poppins',
                        ),
                        children: [
                          TextSpan(
                            text: isRegistering ? 'Iniciá sesión' : 'Registrate',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}