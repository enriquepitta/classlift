// Archivo: lib/components/sign_in_buttons_row.dart
import 'package:classlift/screens/login/widgets/social_sign_button.dart';
import 'package:flutter/material.dart';

class SignInButtonsRow extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback onMoodlePressed;
  final VoidCallback onApplePressed;
  final bool showShadow;
  final double spacing;

  const SignInButtonsRow({
    Key? key,
    required this.onGooglePressed,
    required this.onMoodlePressed,
    required this.onApplePressed,
    this.showShadow = false,
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Tooltip(
            message: 'Iniciar sesión con Moodle',
            child: SocialSignInButton.moodle(
              onPressed: onMoodlePressed,
              showShadow: showShadow,
            ),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: SocialSignInButton.google(
            onPressed: onGooglePressed,
            showShadow: showShadow,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: SocialSignInButton.apple(
            onPressed: onApplePressed,
            showShadow: showShadow,
          ),
        ),
      ],
    );
  }
}
