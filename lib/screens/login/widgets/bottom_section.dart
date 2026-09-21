import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/utils/responsive_utils.dart';
import 'package:classlift/widgets/primary_action_button.dart';
import 'package:flutter/material.dart';
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

    // Utilizamos valores predefinidos para el espaciado
    // Si el teclado está visible, usamos un espaciado más pequeño
    final bottomPadding = controller.isKeyboardVisible
        ? ResponsiveUtils.spacing(context, 'xs')
        : ResponsiveUtils.spacing(context, 'md');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      // Espaciado superior constante usando el método spacing
      padding: EdgeInsets.only(
        top: ResponsiveUtils.spacing(context, 'md'),
        bottom: bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: controller.isRegisteringNotifier,
            builder: (context, isRegistering, _) {
              return PrimaryButton(
                onPressed: () => controller.handleAuthAction(
                        (loading) => setState(() => controller.isLoading = loading)
                ),
                isLoading: controller.isLoading,
                text: isRegistering ? 'Regístrate' : 'Iniciá sesión',
                backgroundColor: ClassliftColors.PrimaryColorVariant,

              );
            },
          ),
        ],
      ),
    );
  }
}