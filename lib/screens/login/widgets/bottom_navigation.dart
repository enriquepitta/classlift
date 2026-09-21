import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final double verticalSpacing = ResponsiveUtils.spacing(context, 'md');

    // Detectamos si el dispositivo tiene zona segura inferior
    final bool hasBottomSafeArea =
        MediaQuery.of(context).viewPadding.bottom > 0;

    // Ajustamos el espaciado final según si tiene o no zona segura
    final double bottomSpacing = hasBottomSafeArea
        ? verticalSpacing // Reducimos el espaciado si ya tiene safe area
        : 0.0; // Mantenemos el espaciado normal si no tiene safe area

    // También podríamos usar el método propuesto
    // final double bottomSpacing = ResponsiveUtils.getBottomSafeSpacing(
    //   context,
    //   withSafeArea: verticalSpacing * 0.5,
    //   withoutSafeArea: verticalSpacing
    // );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ClassliftColors.White, ClassliftColors.PrimaryColorVariant],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: bottomSectionPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Expanded(
                    child: Divider(color: ClassliftColors.PrimaryColor, thickness: 1)),
                Text(' O continuá con ',
                    style: TextStyle(color: ClassliftColors.PrimaryColor)),
                Expanded(
                    child: Divider(color: ClassliftColors.PrimaryColor, thickness: 1)),
              ],
            ),
            // Utilizamos SizedBox con el espaciado predefinido
            SizedBox(height: verticalSpacing),
            SignInButtonsRow(
              onGooglePressed: controller.signInWithGoogle,
              onMoodlePressed: () => context.push('/login/moodle'),
              onApplePressed: () {},
            ),
            SizedBox(height: verticalSpacing - 10),
            TextButton(
              onPressed: () {
                controller.isRegisteringNotifier.value =
                    !controller.isRegisteringNotifier.value;
              },
              child: ValueListenableBuilder<bool>(
                valueListenable: controller.isRegisteringNotifier,
                builder: (context, isRegistering, _) {
                  return RichText(
                    text: TextSpan(
                      text: isRegistering
                          ? '¿Ya tenés una cuenta? '
                          : '¿No tenés una cuenta? ',
                      style: TextStyle(
                        color: ClassliftColors.PrimaryColor,
                        // Utilizamos fontStyle para textos
                        fontSize: ResponsiveUtils.fontStyle(context, 'button'),
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
            // Espaciado adaptativo al final según el tipo de dispositivo
            SizedBox(height: bottomSpacing),
          ],
        ),
      ),
    );
  }
}
