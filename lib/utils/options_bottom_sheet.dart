
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/utils/responsive_utils.dart';
import 'package:classlift/widgets/primary_action_button.dart';

class OptionsBottomSheet extends StatelessWidget {
  final VoidCallback onExcel;
  final VoidCallback onManual;

  const OptionsBottomSheet({
    required this.onExcel,
    required this.onManual,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primaryBlue = ClassliftColors.PrimaryColor;
    final secondaryBlue = ClassliftColors.PrimaryColorVariant;
    final white = ClassliftColors.White;

    // Usar ResponsiveUtils para mejor consistencia
    final bool isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    // Tamaños del modal
    final double initialChildSize = isSmallScreen ? 0.5 : 0.45;
    final double minChildSize = isSmallScreen ? 0.4 : 0.35;
    final double maxChildSize = isSmallScreen ? 0.8 : 0.7;

    // Valores responsivos con ResponsiveUtils
    final double borderRadius = ResponsiveUtils.borderRadius(context, 'lg');
    final double padding = ResponsiveUtils.padding(context, 'screen');
    final double iconSize = ResponsiveUtils.iconSize(context, 'md');
    final double borderWidth = ResponsiveUtils.borderWidth(context, 'thin');
    final double contentPadding = ResponsiveUtils.spacing(context, 'md');

    // Detectar si hay barra de inicio (home indicator)
    final bool hasHomeIndicator = MediaQuery.of(context).viewPadding.bottom > 0;
    final double bottomPadding = hasHomeIndicator ? 0 : 10;

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
                                'Seleccioná una opción',
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

                  // Contenido con las opciones
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Spacer(),

                                  // Contenido de las opciones
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: padding),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Opción Excel
                                        _buildOptionTile(
                                          context,
                                          icon: Icons.file_upload,
                                          title: 'Agregar horario por Excel',
                                          onTap: () {
                                            onExcel();
                                          },
                                          primaryBlue: primaryBlue,
                                          secondaryBlue: secondaryBlue,
                                          white: white,
                                        ),

                                        SizedBox(height: contentPadding),

                                        // Opción Manual
                                        _buildOptionTile(
                                          context,
                                          icon: Icons.edit,
                                          title: 'Agregar clases manualmente',
                                          onTap: () {
                                            Navigator.pop(context);
                                            onManual();
                                          },
                                          primaryBlue: primaryBlue,
                                          secondaryBlue: secondaryBlue,
                                          white: white,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Sección del botón cancelar con la línea divisoria
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
                                text: 'Cancelar',
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
  }

  Widget _buildOptionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        required Color primaryBlue,
        required Color secondaryBlue,
        required Color white,
      }) {
    return Material(
      color: ClassliftColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: secondaryBlue.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: secondaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontStyle(context, 'body'),
                    fontWeight: ResponsiveUtils.fontWeight(context, 'medium'),
                    color: primaryBlue,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: primaryBlue.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}