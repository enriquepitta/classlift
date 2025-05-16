import 'package:classlift/utils/responsive_utils.dart';
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

    // Utilizamos los métodos predefinidos de ResponsiveUtils
    final bottomSectionPadding = ResponsiveUtils.padding(context, 'screen');

    // Para espaciados verticales entre elementos utilizamos el método spacing
    final verticalSpacing = ResponsiveUtils.spacing(context, 'lg');

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
              // Utilizamos SizedBox con el espaciado predefinido
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
                          // Utilizamos fontStyle para textos
                          fontSize: ResponsiveUtils.fontStyle(context, 'body'),
                          fontFamily: 'Poppins',
                        ),
                        children: [
                          TextSpan(
                            text: isRegistering ? 'Iniciá sesión' : 'Registrate',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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