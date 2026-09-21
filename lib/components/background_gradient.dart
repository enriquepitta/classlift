import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';

class BackgroundGradient extends StatelessWidget {
  const BackgroundGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            // BK v2
            ClassliftColors.PrimaryColor,
            ClassliftColors.PrimaryColor,
            ClassliftColors.PrimaryColorVariant,
            ClassliftColors.White,
            ClassliftColors.White,

            // BK v3
            // ClassliftColors.PrimaryColor,
            // ClassliftColors.PrimaryColorVariant,
            // ClassliftColors.White,
          ],
        ),
      ),
    );
  }
}


