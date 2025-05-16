import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ResponsiveActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String text;
  final Widget? icon;
  final bool adaptToParent;

  // Colores y estilos personalizables
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;

  // Control de sombra con un booleano
  final bool enableShadow;
  final Color? shadowColor;

  const ResponsiveActionButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.text,
    this.icon,
    this.adaptToParent = true,
    this.backgroundColor = const Color(0xFF4E7AB5),
    this.textColor = Colors.white,
    this.borderRadius = 12.0,
    this.enableShadow = true,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    // Usar MediaQuery para obtener información sobre el dispositivo
    final screenSize = MediaQuery.of(context).size;
    final isSmallDevice = screenSize.width < 360;
    final isLargeDevice = screenSize.width > 600;

    return adaptToParent
        ? _buildWithLayoutBuilder(context, isSmallDevice, isLargeDevice)
        : _buildWithMediaQuery(context, isSmallDevice, isLargeDevice);
  }

  Widget _buildWithLayoutBuilder(BuildContext context, bool isSmallDevice, bool isLargeDevice) {
    return LayoutBuilder(
        builder: (context, constraints) {
          // Ajustar basado en el espacio disponible en el padre
          final buttonHeight = constraints.maxWidth < 200 ? 40.0 :
          constraints.maxWidth < 300 ? 45.0 :
          constraints.maxWidth < 600 ? 50.0 : 55.0;

          final fontSize = constraints.maxWidth < 200 ? 14.0 :
          constraints.maxWidth < 300 ? 15.0 :
          constraints.maxWidth < 600 ? 16.0 : 17.0;

          final buttonWidth = constraints.maxWidth;

          return _buildButton(buttonWidth, buttonHeight, fontSize);
        }
    );
  }

  Widget _buildWithMediaQuery(BuildContext context, bool isSmallDevice, bool isLargeDevice) {
    // Ajustar basado en el tamaño de la pantalla
    final buttonHeight = isSmallDevice ? 45.0 : isLargeDevice ? 55.0 : 50.0;
    final fontSize = isSmallDevice ? 15.0 : isLargeDevice ? 17.0 : 16.0;

    return _buildButton(double.infinity, buttonHeight, fontSize);
  }

  Widget _buildButton(double width, double height, double fontSize) {
    // Definir la sombra predeterminada
    final defaultShadowColor = shadowColor ?? const Color(0xFFA3C1E2);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        // Aplicar sombra solo si enableShadow es true
        boxShadow: enableShadow
            ? [
          BoxShadow(
            color: defaultShadowColor.withOpacity(0.5),
            offset: const Offset(0, 3),
            blurRadius: 5,
          ),
        ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(width, height),
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? Lottie.asset('assets/lottie/spinner_4.json', width: 30, height: 30)
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
      ),
    );
  }
}