import 'package:classlift/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class TextfieldLabel extends StatelessWidget {
  const TextfieldLabel({super.key});

  Widget buildLabelAndTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool obscureText,
    required ValueNotifier<bool> obscureTextNotifier,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    EdgeInsets? padding,
    double? maxWidth,
  }) {
    return Builder(
        builder: (BuildContext context) {
          // Obtenemos valores del sistema ResponsiveUtils
          final labelFontSize = ResponsiveUtils.fontStyle(context, 'label');
          final textFieldFontSize = ResponsiveUtils.fontStyle(context, 'input');
          final iconSize = ResponsiveUtils.iconSize(context, 'md');
          final spacingHeight = ResponsiveUtils.spacing(context, 'xs');
          final verticalPadding = ResponsiveUtils.padding(context, 'input');
          final horizontalPadding = ResponsiveUtils.padding(context, 'input');
          final borderRadius = ResponsiveUtils.borderRadius(context, 'md');
          final borderWidth = ResponsiveUtils.borderWidth(context, 'focus');

          // También podemos obtener el peso de fuente si lo incluimos en ResponsiveUtils
          final fontWeight = ResponsiveUtils.fontWeight(context, 'medium');
          final errorFontSize = ResponsiveUtils.fontStyle(context, 'caption');

          final Widget columnWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFA3C1E2),
                ),
              ),
              SizedBox(height: spacingHeight),
              KeyboardVisibilityBuilder(
                builder: (context, isKeyboardVisible) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: obscureTextNotifier,
                    builder: (context, isObscure, child) {
                      return TextFormField(
                        controller: controller,
                        obscureText: obscureText ? isObscure : false,
                        keyboardType: keyboardType,
                        focusNode: focusNode,
                        style: TextStyle(
                          fontSize: textFieldFontSize,
                          fontWeight: fontWeight,
                        ),
                        textInputAction: nextFocusNode != null
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (nextFocusNode != null) {
                            FocusScope.of(context).requestFocus(nextFocusNode);
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFFF0F0F0),
                          prefixIcon: Icon(
                            icon,
                            color: Color(0xFF66788A),
                            size: iconSize,
                          ),
                          suffixIcon: obscureText
                              ? IconButton(
                            icon: Icon(
                              isObscure ? Icons.visibility_off : Icons.visibility,
                              color: Color(0xFF66788A),
                              size: iconSize,
                            ),
                            constraints: BoxConstraints(
                              minWidth: ResponsiveUtils.padding(context, 'icon-button'),
                              minHeight: ResponsiveUtils.padding(context, 'icon-button'),
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              if (isKeyboardVisible) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  obscureTextNotifier.value = !isObscure;
                                });
                              } else {
                                obscureTextNotifier.value = !isObscure;
                              }
                            },
                          )
                              : null,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: verticalPadding,
                            horizontal: horizontalPadding,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide.none,
                            gapPadding: 0,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: Color(0xFF4C9AFF),
                              width: borderWidth,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: Color(0xFFA41E25),
                              width: borderWidth,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: Color(0xFFA41E25),
                              width: borderWidth,
                            ),
                          ),
                          hintText: hintText ?? 'Ingresá tu ${label.toLowerCase()}',
                          hintStyle: TextStyle(
                            color: Color(0xFF66788A).withOpacity(0.6),
                            fontSize: textFieldFontSize - 1, // Hint ligeramente más pequeño
                            fontWeight: FontWeight.w400,
                          ),
                          isDense: true,
                          errorStyle: TextStyle(
                            color: Color(0xFFA41E25),
                            fontSize: errorFontSize,
                            height: 1.4,
                          ),
                          helperText: null,
                          helperStyle: TextStyle(
                            color: Color(0xFF66788A),
                            fontSize: errorFontSize,
                            fontWeight: FontWeight.w300,
                          ),
                          errorMaxLines: 2,
                        ),
                        validator: validator,
                      );
                    },
                  );
                },
              ),
            ],
          );

          // Aplicamos restricciones de ancho máximo si se proporciona
          if (maxWidth != null) {
            return Container(
              padding: padding,
              width: maxWidth,
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: columnWidget,
            );
          }

          // Si no hay maxWidth, simplemente retornamos la columna con padding opcional
          return padding != null
              ? Padding(padding: padding, child: columnWidget)
              : columnWidget;
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Este método build se mantiene vacío para compatibilidad con el código existente
    return Container();
  }
}