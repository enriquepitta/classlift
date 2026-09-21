import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String iconAsset;
  final String? label;
  final Color? backgroundColor;
  final Color? borderColor;
  final double iconSize;
  final double height;
  final double width;
  final bool showShadow;

  const SocialSignInButton({
    Key? key,
    required this.onPressed,
    required this.iconAsset,
    this.label,
    this.backgroundColor = ClassliftColors.socialButtonBackground,
    this.borderColor = ClassliftColors.socialButtonBorder,
    this.iconSize = 24.0,
    this.height = 50.0,
    this.width = 80.0,
    this.showShadow = false,
  }) : super(key: key);

  /// Constructor de fábrica para Google
  factory SocialSignInButton.google({
    required VoidCallback onPressed,
    double? width,
    double? height,
    bool showShadow = false,
  }) {
    return SocialSignInButton(
      onPressed: onPressed,
      iconAsset: 'assets/icons/google_icon.svg',
      iconSize: 20.0,
      width: width ?? 80.0,
      height: height ?? 50.0,
      showShadow: showShadow,
    );
  }

  /// Constructor de fábrica para Moodle
  factory SocialSignInButton.moodle({
    required VoidCallback onPressed,
    double? width,
    double? height,
    bool showShadow = false,
  }) {
    return SocialSignInButton(
      onPressed: onPressed,
      iconAsset: 'assets/icons/moodle_icon.svg',
      width: width ?? 80.0,
      height: height ?? 50.0,
      showShadow: showShadow,
    );
  }

  /// Constructor de fábrica para Apple
  factory SocialSignInButton.apple({
    required VoidCallback onPressed,
    double? width,
    double? height,
    bool showShadow = false,
  }) {
    return SocialSignInButton(
      onPressed: onPressed,
      iconAsset: 'assets/icons/apple_icon.svg',
      width: width ?? 80.0,
      height: height ?? 50.0,
      showShadow: showShadow,
    );
  }

  /// Constructor de fábrica para Twitter/X
  factory SocialSignInButton.twitter({
    required VoidCallback onPressed,
    double? width,
    double? height,
    bool showShadow = false,
  }) {
    return SocialSignInButton(
      onPressed: onPressed,
      iconAsset: 'assets/icons/twitter_icon.svg',
      width: width ?? 80.0,
      height: height ?? 50.0,
      showShadow: showShadow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: showShadow
            ? BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: borderColor!.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        )
            : null,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor!, width: 1.5),
            ),
            padding: EdgeInsets.zero,
            elevation: 0, // Sin elevación nativa
          ),
          child: label != null
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                height: iconSize,
              ),
              const SizedBox(width: 8),
              Text(
                label!,
                style: const TextStyle(
                  color: ClassliftColors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
              : SvgPicture.asset(
            iconAsset,
            height: iconSize,
          ),
        ),
      ),
    );
  }
}
