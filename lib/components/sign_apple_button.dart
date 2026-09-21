import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignInWithAppleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SignInWithAppleButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80, // Tamaño cuadrado o ligeramente rectangular
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ClassliftColors.socialButtonBackground, // Fondo negro de Apple
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Bordes ligeramente redondeados
            side: BorderSide(color: ClassliftColors.socialButtonBorder, width: 1.5), // Borde negro
          ),
          padding: EdgeInsets.zero, // Sin relleno
        ),
        child: SvgPicture.asset(
          'assets/icons/apple_icon.svg', // Asegúrate de tener el ícono de Apple
          height: 24, // Ajusta el tamaño del ícono
        ),
      ),
    );
  }
}
