import 'package:flutter/material.dart';
import 'package:classify/components/sign_google_button.dart';
import 'package:classify/components/sign_facebook_button.dart';
import 'package:classify/components/sign_apple_button.dart';

class SignInButtonsRow extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback onFacebookPressed;
  final VoidCallback onApplePressed;

  const SignInButtonsRow({
    Key? key,
    required this.onGooglePressed,
    required this.onFacebookPressed,
    required this.onApplePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Centra los botones en el eje horizontal
      children: [
        Expanded(
          child: SignInWithFacebookButton(
            onPressed: onFacebookPressed,
          ),
        ),
        SizedBox(width: 8), // Espacio de 2 píxeles entre los botones
        Expanded(
          child: SignInWithGoogleButton(
            onPressed: onGooglePressed,
          ),
        ),
        SizedBox(width: 8), // Espacio de 2 píxeles entre los botones
        Expanded(
          child: SignInWithAppleButton(
            onPressed: onApplePressed,
          ),
        ),
      ],
    );
  }
}
