import 'dart:ui';
import 'package:classlift/utils/responsive_utils.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/widgets/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';

void showErrorBottomSheet(BuildContext context, String errorMessage) {
  final primaryBlue = ClassliftColors.PrimaryColor;
  final secondaryBlue = ClassliftColors.PrimaryColorVariant;
  final white = ClassliftColors.White;

  // Usar ResponsiveUtils para mejor consistencia
  final bool isSmallScreen = ResponsiveUtils.isSmallScreen(context);

  // Reducir los tamaños iniciales para que el modal sea más compacto
  final double initialChildSize = isSmallScreen ? 0.4 : 0.35;
  final double minChildSize = isSmallScreen ? 0.3 : 0.25;
  final double maxChildSize = isSmallScreen ? 0.7 : 0.6;

  // Valores responsivos con ResponsiveUtils
  final double borderRadius = ResponsiveUtils.borderRadius(context, 'lg');
  final double padding = ResponsiveUtils.padding(context, 'screen');
  final double iconSize = ResponsiveUtils.iconSize(context, 'md');

  // Ancho de borde responsivo para la línea divisoria
  final double borderWidth = ResponsiveUtils.borderWidth(context, 'thin');

  // Espaciado uniforme para el contenido
  final double contentPadding = ResponsiveUtils.spacing(context, 'md');

  // Detectar si hay barra de inicio (home indicator)
  final bool hasHomeIndicator = MediaQuery.of(context).viewPadding.bottom > 0;
  final double bottomPadding = hasHomeIndicator ? 0 : 10;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: ClassliftColors.transparent,
    barrierColor: primaryBlue.withOpacity(0.15),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: white.withOpacity(0.85),
              borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barra de arrastre con color corporativo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      decoration: BoxDecoration(
                        color: white.withOpacity(0.95),
                      ),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: secondaryBlue.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // App bar con blur y colores corporativos
                    Container(
                      decoration: BoxDecoration(
                        color: white.withOpacity(0.7),
                        border: Border(
                          bottom: BorderSide(
                            color: secondaryBlue.withOpacity(0.2),
                            width: borderWidth,
                          ),
                        ),
                      ),
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(padding, 8, padding, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Atención',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.fontStyle(context, 'subheading'),
                                    fontWeight: ResponsiveUtils.fontWeight(context, 'semibold'),
                                    color: primaryBlue,
                                  ),
                                ),
                                // Botón de cierre con colores corporativos
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: secondaryBlue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.xmark,
                                      size: iconSize - 4,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Contenido con espaciado simétrico
                    Expanded(
                      child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              controller: scrollController,
                              physics: const BouncingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight, // Forzar altura mínima igual a la disponible
                                ),
                                child: IntrinsicHeight(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center, // Centrar contenido verticalmente
                                    children: [
                                      // Espacio flexible superior (equilibra con el inferior)
                                      Spacer(),

                                      // Contenido real
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: padding,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Lottie.asset(
                                              'assets/lottie/Caution.json',
                                              height: isSmallScreen ? 80 : 90,
                                              repeat: false,
                                            ),
                                            SizedBox(height: 0),
                                            Text(
                                              errorMessage,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: primaryBlue.withOpacity(0.8),
                                                fontSize: ResponsiveUtils.fontStyle(context, 'body'),
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Espacio flexible inferior (equilibra con el superior)
                                      Spacer(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                      ),
                    ),

                    // Sección del botón CON la línea divisoria
                    Container(
                      decoration: BoxDecoration(
                        color: white.withOpacity(0.7),
                        border: Border(
                          top: BorderSide(
                            color: secondaryBlue.withOpacity(0.2),
                            width: borderWidth,
                          ),
                        ),
                      ),
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              padding,
                              8,
                              padding,
                              bottomPadding,
                            ),
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: hasHomeIndicator ? 0 : 2),
                                child: PrimaryButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  isLoading: false,
                                  text: 'Entendí',
                                  backgroundColor: secondaryBlue,
                                  textColor: white,
                                  adaptToParent: false,
                                  enableShadow: false,
                                  shadowColor: secondaryBlue.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}