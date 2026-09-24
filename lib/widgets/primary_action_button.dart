import 'package:flutter/material.dart';
import 'package:classlift/utils/responsive_utils.dart';
import 'package:classlift/utils/classlift_colors.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final bool adaptToParent;
  final EdgeInsets? padding;
  final bool enableShadow;
  final Color? shadowColor;
  final double? minWidth;
  final double? minHeight;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  const PrimaryButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.adaptToParent = true,
    this.padding,
    this.enableShadow = false,
    this.shadowColor,
    this.minWidth,
    this.minHeight,
    this.leadingIcon,
    this.trailingIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Colores predeterminados desde el tema de ClassLift
    final Color bgColor = backgroundColor ?? ClassliftColors.PrimaryColor;
    final Color txtColor = textColor ?? ClassliftColors.White;
    final Color btnShadowColor = shadowColor ?? bgColor.withOpacity(0.4);

    // Valores responsivos para los diversos elementos
    final double btnBorderRadius = borderRadius ?? ResponsiveUtils.borderRadius(context, 'md');
    final double btnFontSize = ResponsiveUtils.fontStyle(context, 'button');
    final double btnHeight = minHeight ?? ResponsiveUtils.getAdaptiveSize(
      context,
      small: 44.0,
      medium: 55.0,
      large: 55.0,
    );

    // Padding interno responsivo
    final EdgeInsets btnPadding = padding ?? EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.padding(context, 'element'),
      vertical: ResponsiveUtils.spacing(context, 'xs'),
    );

    // Espacio entre iconos y texto
    final double iconSpacing = ResponsiveUtils.spacing(context, 'xs');

    // Tamaño responsivo del spinner de carga
    final double loaderSize = ResponsiveUtils.iconSize(context, 'sm');

    // Elevación basada en si el sombreado está habilitado
    final double elevation = enableShadow ? 4.0 : 0.0;

    // Fuente para el texto del botón
    final FontWeight fontWeight = ResponsiveUtils.fontWeight(context, 'semibold');

    return Container(
      width: double.infinity,
      height: btnHeight,
      decoration: enableShadow ? BoxDecoration(
        borderRadius: BorderRadius.circular(btnBorderRadius),
        boxShadow: [
          BoxShadow(
            color: btnShadowColor,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ) : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: txtColor,
          disabledBackgroundColor: bgColor.withOpacity(0.7),
          disabledForegroundColor: txtColor.withOpacity(0.7),
          padding: btnPadding,
          elevation: elevation,
          shadowColor: enableShadow ? btnShadowColor : ClassliftColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnBorderRadius),
          ),
          minimumSize: Size(0, btnHeight),
        ),
        child: isLoading
            ? SizedBox(
          width: loaderSize,
          height: loaderSize,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(txtColor),
          ),
        )
            : Row(
          mainAxisSize: adaptToParent ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              leadingIcon!,
              SizedBox(width: iconSpacing),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: btnFontSize,
                fontWeight: fontWeight,
              ),
            ),
            if (trailingIcon != null) ...[
              SizedBox(width: iconSpacing),
              trailingIcon!,
            ],
          ],
        ),
      ),
    );
  }
}