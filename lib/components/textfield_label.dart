import 'package:classlift/utils/classlift_colors.dart';
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
    bool glassStyle = false,
  }) {
    return Builder(builder: (BuildContext context) {
      // Obtenemos valores del sistema ResponsiveUtils
      final labelFontSize = ResponsiveUtils.fontStyle(context, 'label');
      final textFieldFontSize = ResponsiveUtils.fontStyle(context, 'input');
      final iconSize = ResponsiveUtils.iconSize(context, 'md');
      final spacingHeight = ResponsiveUtils.spacing(context, 'xs');
      final verticalPadding = ResponsiveUtils.padding(context, 'input');
      final horizontalPadding = ResponsiveUtils.padding(context, 'input');
      final borderRadius =
          glassStyle ? 18.0 : ResponsiveUtils.borderRadius(context, 'md');
      final borderWidth = ResponsiveUtils.borderWidth(context, 'focus');

      // También podemos obtener el peso de fuente si lo incluimos en ResponsiveUtils
      final fontWeight = ResponsiveUtils.fontWeight(context, 'medium');
      final errorFontSize = ResponsiveUtils.fontStyle(context, 'caption');

      final Widget columnWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!glassStyle)
            Text(
              label,
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: FontWeight.w500,
                color: ClassliftColors.SecondaryColor,
              ),
            ),
          if (!glassStyle) SizedBox(height: spacingHeight),
          KeyboardVisibilityBuilder(
            builder: (context, isKeyboardVisible) {
              return ValueListenableBuilder<bool>(
                valueListenable: obscureTextNotifier,
                builder: (context, isObscure, child) {
                  final field = TextFormField(
                    controller: controller,
                    obscureText: obscureText ? isObscure : false,
                    keyboardType: keyboardType,
                    focusNode: focusNode,
                    style: TextStyle(
                      fontSize: glassStyle ? 14 : textFieldFontSize,
                      color: glassStyle ? const Color(0xFF182750) : null,
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
                      fillColor: glassStyle
                          ? const Color(0xBBFFFFFF)
                          : ClassliftColors.semesterColorEven,
                      prefixIcon: Icon(
                        icon,
                        color: glassStyle
                            ? const Color(0xFF8D9AB6)
                            : ClassliftColors.inputMuted,
                        size: iconSize,
                      ),
                      suffixIcon: obscureText
                          ? IconButton(
                              tooltip: isObscure
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              icon: Icon(
                                isObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: glassStyle
                                    ? const Color(0xFF8D9AB6)
                                    : ClassliftColors.inputMuted,
                                size: iconSize,
                              ),
                              constraints: BoxConstraints(
                                minWidth: ResponsiveUtils.padding(
                                    context, 'icon-button'),
                                minHeight: ResponsiveUtils.padding(
                                    context, 'icon-button'),
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (isKeyboardVisible) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    obscureTextNotifier.value = !isObscure;
                                  });
                                } else {
                                  obscureTextNotifier.value = !isObscure;
                                }
                              },
                            )
                          : null,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: glassStyle ? 18 : verticalPadding,
                        horizontal: horizontalPadding,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: glassStyle
                            ? const BorderSide(
                                color: Color(0xE6FFFFFF), width: 1.2)
                            : BorderSide.none,
                        gapPadding: 0,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(
                          color: ClassliftColors.inputFocus,
                          width: borderWidth,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(
                          color: ClassliftColors.inputError,
                          width: borderWidth,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(
                          color: ClassliftColors.inputError,
                          width: borderWidth,
                        ),
                      ),
                      hintText: hintText ?? 'Ingresá tu ${label.toLowerCase()}',
                      hintStyle: TextStyle(
                        color: glassStyle
                            ? const Color(0xFF919DB9)
                            : ClassliftColors.inputMuted.withOpacity(0.6),
                        fontSize: glassStyle
                            ? 13
                            : textFieldFontSize -
                                1, // Hint ligeramente más pequeño
                        fontWeight: FontWeight.w400,
                      ),
                      isDense: true,
                      errorStyle: TextStyle(
                        color: ClassliftColors.inputError,
                        fontSize: errorFontSize,
                        height: 1.4,
                      ),
                      helperText: null,
                      helperStyle: TextStyle(
                        color: glassStyle
                            ? const Color(0xFF8D9AB6)
                            : ClassliftColors.inputMuted,
                        fontSize: errorFontSize,
                        fontWeight: FontWeight.w300,
                      ),
                      errorMaxLines: 2,
                    ),
                    validator: validator,
                  );
                  if (!glassStyle) return field;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D5276B0),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Semantics(label: label, child: field),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    // Este método build se mantiene vacío para compatibilidad con el código existente
    return Container();
  }
}
