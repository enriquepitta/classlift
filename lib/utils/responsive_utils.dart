// responsive_utils.dart
import 'package:flutter/material.dart';

class ResponsiveUtils {
  /// Tamaños de pantalla para diferentes dispositivos (en puntos lógicos)
  static const double kSmallScreenWidth = 375.0;   // iPhone SE, mini
  static const double kMediumScreenWidth = 393.0;  // iPhone 16, 15, 14
  static const double kMediumPlusScreenWidth = 430.0;  // iPhone 16 Pro
  static const double kLargeScreenWidth = 430.0;  // iPhone 16 Pro Max, 15 Pro Max

  /// VALORES PREDEFINIDOS DE DISEÑO

  // Fuentes predefinidas
  static const Map<String, Map<String, double>> _fontSizes = {
    'title': {'small': 32, 'medium': 54, 'large': 54},
    'heading': {'small': 24, 'medium': 28, 'large': 32},
    'subheading': {'small': 18, 'medium': 20, 'large': 22},
    'body': {'small': 14, 'medium': 16, 'large': 18},
    'caption': {'small': 12, 'medium': 13, 'large': 14},
    'button': {'small': 14, 'medium': 16, 'large': 17},
    'input': {'small': 14, 'medium': 18, 'large': 16},
    'label': {'small': 16, 'medium': 17, 'large': 18}, // Añadido para labels de TextfieldLabel
  };

  // Espaciados predefinidos
  static const Map<String, Map<String, double>> _spacings = {
    'xxs': {'small': 2, 'medium': 4, 'large': 6},
    'xs': {'small': 4, 'medium': 8, 'large': 10},
    'sm': {'small': 8, 'medium': 12, 'large': 16},
    'dm': {'small': 10, 'medium': 20, 'large': 20},
    'md': {'small': 16, 'medium': 24, 'large': 26},
    'lg': {'small': 24, 'medium': 30, 'large': 30},
    'xl': {'small': 32, 'medium': 40, 'large': 48},
    'xxl': {'small': 40, 'medium': 48, 'large': 56},
  };

  // Padding predefinido
  static const Map<String, Map<String, double>> _paddings = {
    'screen': {'small': 16, 'medium': 24, 'large': 24},
    'card': {'small': 12, 'medium': 16, 'large': 20},
    'button': {'small': 10, 'medium': 14, 'large': 16},
    'input': {'small': 12, 'medium': 14, 'large': 16},
    'icon-button': {'small': 40, 'medium': 44, 'large': 48}, // Añadido para botones de iconos
  };

  // Bordes predefinidos
  static const Map<String, Map<String, double>> _borderRadius = {
    'sm': {'small': 4, 'medium': 6, 'large': 8},
    'md': {'small': 8, 'medium': 12, 'large': 16},
    'lg': {'small': 16, 'medium': 20, 'large': 24},
    'full': {'small': 999, 'medium': 999, 'large': 999}, // Circular
  };

  // Tamaños de iconos predefinidos (NUEVO)
  static const Map<String, Map<String, double>> _iconSizes = {
    'xs': {'small': 16, 'medium': 18, 'large': 20},
    'sm': {'small': 18, 'medium': 20, 'large': 22},
    'md': {'small': 20, 'medium': 22, 'large': 24},
    'lg': {'small': 24, 'medium': 26, 'large': 28},
  };

  // Grosores de borde predefinidos (NUEVO)
  static const Map<String, Map<String, double>> _borderWidths = {
    'thin': {'small': 0.5, 'medium': 1.0, 'large': 1.0},
    'regular': {'small': 1.0, 'medium': 1.5, 'large': 1.5},
    'focus': {'small': 1.5, 'medium': 2.0, 'large': 2.0},
    'accent': {'small': 2.0, 'medium': 2.5, 'large': 3.0},
  };

  // Pesos de fuentes predefinidos (NUEVO)
  static const Map<String, FontWeight> _fontWeights = {
    'thin': FontWeight.w100,
    'extralight': FontWeight.w200,
    'light': FontWeight.w300,
    'regular': FontWeight.w400,
    'medium': FontWeight.w500,
    'semibold': FontWeight.w600,
    'bold': FontWeight.w700,
    'extrabold': FontWeight.w800,
    'black': FontWeight.w900,
  };

  /// Métodos de verificación de tamaño de pantalla

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width <= kSmallScreenWidth;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > kSmallScreenWidth && width <= kMediumScreenWidth;
  }

  static bool isMediumPlusScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > kMediumScreenWidth && width < kMediumPlusScreenWidth;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= kMediumPlusScreenWidth;
  }

  /// Obtener el tamaño de pantalla actual como string
  static String screenSizeCategory(BuildContext context) {
    if (isSmallScreen(context)) return 'small';
    if (isMediumScreen(context)) return 'medium';
    if (isMediumPlusScreen(context)) return 'medium'; // También usamos 'medium' por simplicidad
    return 'large';
  }

  /// MÉTODOS SIMPLIFICADOS CON VALORES PREDEFINIDOS

  /// Obtiene un tamaño de fuente predefinido según su tipo
  /// Ejemplo: fontStyle('heading')
  static double fontStyle(BuildContext context, String style) {
    final size = screenSizeCategory(context);
    return _fontSizes.containsKey(style)
        ? _fontSizes[style]![size]!
        : _fontSizes['body']![size]!; // Fallback a 'body' si no existe
  }

  /// Obtiene un espaciado predefinido
  /// Ejemplo: spacing('md')
  static double spacing(BuildContext context, String size) {
    final screenSize = screenSizeCategory(context);
    return _spacings.containsKey(size)
        ? _spacings[size]![screenSize]!
        : _spacings['md']![screenSize]!; // Fallback a 'md' si no existe
  }

  /// Obtiene un padding predefinido
  /// Ejemplo: padding('screen')
  static double padding(BuildContext context, String type) {
    final screenSize = screenSizeCategory(context);
    return _paddings.containsKey(type)
        ? _paddings[type]![screenSize]!
        : _paddings['screen']![screenSize]!; // Fallback a 'screen' si no existe
  }

  /// Obtiene un radio de borde predefinido
  /// Ejemplo: borderRadius('md')
  static double borderRadius(BuildContext context, String size) {
    final screenSize = screenSizeCategory(context);
    return _borderRadius.containsKey(size)
        ? _borderRadius[size]![screenSize]!
        : _borderRadius['md']![screenSize]!; // Fallback a 'md' si no existe
  }

  /// MÉTODOS NUEVOS

  /// Obtiene un tamaño de icono predefinido
  /// Ejemplo: iconSize('md')
  static double iconSize(BuildContext context, String size) {
    final screenSize = screenSizeCategory(context);
    return _iconSizes.containsKey(size)
        ? _iconSizes[size]![screenSize]!
        : _iconSizes['md']![screenSize]!; // Fallback a 'md' si no existe
  }

  /// Obtiene un grosor de borde predefinido
  /// Ejemplo: borderWidth('focus')
  static double borderWidth(BuildContext context, String type) {
    final screenSize = screenSizeCategory(context);
    return _borderWidths.containsKey(type)
        ? _borderWidths[type]![screenSize]!
        : _borderWidths['regular']![screenSize]!; // Fallback a 'regular' si no existe
  }

  /// Obtiene un peso de fuente predefinido
  /// Ejemplo: fontWeight('medium')
  static FontWeight fontWeight(BuildContext context, String weight) {
    // Nota: No depende del tamaño de pantalla, solo del tipo de peso
    return _fontWeights[weight] ?? FontWeight.w400; // Fallback a 'regular' si no existe
  }

  /// MÉTODOS FLEXIBLES (BACKWARDS COMPATIBILITY)

  /// Obtiene un valor personalizado adaptativo - para casos especiales
  static double getAdaptiveSize(
      BuildContext context, {
        required double small,
        required double medium,
        required double large,
      }) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context) || isMediumPlusScreen(context)) return medium;
    return large;
  }

  /// Obtiene el padding horizontal (usa valores predefinidos para la pantalla)
  static double getHorizontalPadding(BuildContext context) {
    return padding(context, 'screen');
  }

  /// Obtiene el padding vertical (usa valores predefinidos para la pantalla)
  static double getVerticalPadding(BuildContext context) {
    return padding(context, 'screen');
  }

  /// Información de dispositivo para debugging
  static String getDeviceInfo(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final ratio = width / height;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    String deviceType = "Desconocido";
    if (isSmallScreen(context)) deviceType = "Pequeño (iPhone SE/mini)";
    else if (isMediumScreen(context)) deviceType = "Mediano (iPhone estándar)";
    else if (isMediumPlusScreen(context)) deviceType = "Mediano Plus (iPhone Pro)";
    else if (isLargeScreen(context)) deviceType = "Grande (iPhone Pro Max)";

    return "Dispositivo: $deviceType, Dimensiones: ${width.toInt()}x${height.toInt()} pt, "
        "Ratio: ${ratio.toStringAsFixed(2)}, Escala: ${pixelRatio.toStringAsFixed(1)}x";
  }

  // Método para agregar a ResponsiveUtils
  static bool hasBottomSafeArea(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return bottomPadding > 0;
  }

  // Método para obtener el espaciado óptimo según el dispositivo
  static double getBottomSafeSpacing(BuildContext context, {
    double withSafeArea = 0.0,  // Espaciado para dispositivos con notch/home indicator
    double withoutSafeArea = 8.0,  // Espaciado para dispositivos sin notch/home indicator
  }) {
    return hasBottomSafeArea(context) ? withSafeArea : withoutSafeArea;
  }


}