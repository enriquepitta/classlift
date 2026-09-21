import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';

class LoginTitle extends StatelessWidget {
  final Animation<double> animation;
  final double fontSize;

  const LoginTitle({
    super.key,
    required this.animation,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            colors: [ClassliftColors.PrimaryColorVariant, ClassliftColors.loginTitleGradientEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds);
        },
        child: Text(
          'ClassLift',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: ClassliftColors.White,
          ),
        ),
      ),
    );
  }
}