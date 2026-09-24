import 'package:flutter/material.dart';

class ClassliftColors {
  // Shared Classlift blue surface for the home header and calendar.
  static const calendarSurface = Color(0xFF3B55A5);
  static const calendarInk = Color(0xFFFFFFFF);
  static const calendarMuted = Color(0xFFD7E3FF);
  static const calendarOutside = Color(0xFFADBFE8);
  static const calendarAccent = Color(0xFFDCE8FF);
  static const calendarToday = Color(0xFFBDDDFF);
  static const calendarDots = Color(0xFFB5D1FF);
  static const calendarSelectionTop = Color(0xFFE8F0FF);
  static const calendarSelectionBottom = Color(0xFFD2E1FF);
  static const calendarSelectionInk = Color(0xFF273776);
  static const calendarHandle = Color(0xFF506AB5);
  static const calendarSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PrimaryColor, Color(0xFF354998), calendarSurface],
    stops: [0, 0.55, 1],
  );

  static const Color PrimaryColor = Color(0xFF333D86); // Azul oscuro
  static const Color SecondaryColor = Color(0xFFA3C1E2); // Azul claro
  static const Color PrimaryColorVariant = Color(0xFF4E7AB5); // Azul claro
  static const Color AccentColor = Color(0xFFFF6F61); // Coral
  static const Color BackgroundColor = Color(0xFFF5F5F5); // Gris claro
  static const Color homeBackground = Color(0xFFFCFCFD);
  static const Color TextColor = Color(0xFF333333); // Gris oscuro
  static const Color White = Color(0xFFFFFFFF); // Blanco
  static const Color Black = Color(0xFF000000); // Negro

  // Tonalidades intercaladas
  static const careerColorEven = Color(0xFFEDEDED); // gris claro
  static const careerColorOdd = Color(0xFFDADADA); // gris medio claro

  static const semesterColorEven = Color(0xFFF0F0F0); // un poco más suave
  static const semesterColorOdd = Color(0xFFE0E0E0); // gris neutro

  static const subjectColorEven = Color(0xFFFFFFFF); // blanco
  static const subjectColorOdd = Color(0xFFF7F7F7); // gris muy muy claro

  static const selectAllColor =
      Color(0xFFEBF1F4); // gris azulado claro, para destacar suavemente

  // Degradados
  static LinearGradient primaryGradient = LinearGradient(
    colors: [PrimaryColor, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient secondaryGradient = LinearGradient(
    colors: [SecondaryColor, secondaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient accentGradient = LinearGradient(
    colors: [AccentColor, accentGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Extended palette: all UI color values are defined here.
  static const subjectRoseBackground = Color(0xFFFFD9DD);
  static const subjectRoseAccent = Color(0xFFAD1F35);
  static const subjectMintBackground = Color(0xFFDDF8EC);
  static const subjectMintAccent = Color(0xFF3C7960);
  static const subjectBlueBackground = Color(0xFFDCE8FA);
  static const subjectBlueAccent = Color(0xFF2F67B1);
  static const subjectApricotBackground = Color(0xFFFFEBD3);
  static const subjectApricotAccent = Color(0xFF9C5A16);
  static const subjectLavenderBackground = Color(0xFFECE2FA);
  static const subjectLavenderAccent = Color(0xFF6C4DA3);
  static const subjectYellowBackground = Color(0xFFFFF3CC);
  static const subjectYellowAccent = Color(0xFF9A7610);
  static const subjectTealBackground = Color(0xFFD8F5F3);
  static const subjectTealAccent = Color(0xFF1B7775);
  static const subjectIndigoBackground = Color(0xFFE7E6FF);
  static const subjectIndigoAccent = Color(0xFF5350A8);
  static const subjectPeachBackground = Color(0xFFFFE2D4);
  static const subjectPeachAccent = Color(0xFFAA5130);
  static const subjectPinkBackground = Color(0xFFFBE0F0);
  static const subjectPinkAccent = Color(0xFFA83D70);
  static const subjectSkyBackground = Color(0xFFDAEFFC);
  static const subjectSkyAccent = Color(0xFF267AA4);
  static const subjectGreenBackground = Color(0xFFDBF2DF);
  static const subjectGreenAccent = Color(0xFF39794A);
  static const subjectCoralBackground = Color(0xFFFFE0E8);
  static const subjectCoralAccent = Color(0xFFB33B58);
  static const subjectLimeBackground = Color(0xFFE3F3D4);
  static const subjectLimeAccent = Color(0xFF517F31);
  static const subjectPeriwinkleBackground = Color(0xFFDDEBFF);
  static const subjectPeriwinkleAccent = Color(0xFF3E649E);
  static const subjectAmberBackground = Color(0xFFFFE7C6);
  static const subjectAmberAccent = Color(0xFFA86819);
  static const subjectOrchidBackground = Color(0xFFE9DCF8);
  static const subjectOrchidAccent = Color(0xFF7654A1);
  static const subjectGoldBackground = Color(0xFFF8F0C9);
  static const subjectGoldAccent = Color(0xFF927818);
  static const subjectSeafoamBackground = Color(0xFFD5F0EC);
  static const subjectSeafoamAccent = Color(0xFF257C73);
  static const subjectVioletBackground = Color(0xFFE5E1F5);
  static const subjectVioletAccent = Color(0xFF6256A1);
  static const subjectTerracottaBackground = Color(0xFFF9DED1);
  static const subjectTerracottaAccent = Color(0xFFB05B40);
  static const subjectMauveBackground = Color(0xFFF3DDEA);
  static const subjectMauveAccent = Color(0xFFA44B7B);
  static const subjectCyanBackground = Color(0xFFD8EEF4);
  static const subjectCyanAccent = Color(0xFF2D7C93);
  static const subjectSageBackground = Color(0xFFDDEFD8);
  static const subjectSageAccent = Color(0xFF467C43);
  static const evaluationText = Color(0xFF11155C);
  static const evaluationBarrier = Color(0xFF141B46);
  static const taskText = Color(0xFF34377D);
  static const recoveryText = Color(0xFF325582);
  static const inputFocus = Color(0xFF4C9AFF);
  static const illustrationCheck = Color(0xFF5269D9);
  static const homeAction = Color(0xFF5668D9);
  static const navigationAccent = Color(0xFF3860F5);
  static const navigationAccentEnd = Color(0xFF3457EF);
  static const navigationMuted = Color(0xFF6875A5);
  static const navigationGlass = Color(0xFFEEF0FF);
  static const navigationSelected = Color(0xFFF0F4FF);
  static const navigationShadow = Color(0xFF6878B1);
  static const illustrationPrimary = Color(0xFF6176E5);
  static const inputMuted = Color(0xFF66788A);
  static const illustrationBinding = Color(0xFF687DE4);
  static const emptyScheduleText = Color(0xFF6B78B8);
  static const evaluationMuted = Color(0xFF7275B8);
  static const taskMuted = Color(0xFF747598);
  static const emptyScheduleIcon = Color(0xFF7584D8);
  static const educaMuted = Color(0xFF8A4150);
  static const socialButtonBorder = Color(0xFF91B0FE);
  static const verificationMuted = Color(0xFF979797);
  static const inputError = Color(0xFFA41E25);
  static const scheduleConflictTitle = Color(0xFFAF3030);
  static const scheduleConflictText = Color(0xFFB33333);
  static const educaDarkRed = Color(0xFFB51230);
  static const illustrationBadge = Color(0xFFB9C6FB);
  static const taskPageIndicator = Color(0xFFBDC8E6);
  static const educaRed = Color(0xFFC51F3A);
  static const homeGreetingSubtitle = Color(0xFFD3D9F4);
  static const taskOverdue = Color(0xFFD53D50);
  static const illustrationCell = Color(0xFFDCE3FF);
  static const loginTitleGradientEnd = Color(0xFFDCE4EF);
  static const evaluationDivider = Color(0xFFE0E1F6);
  static const socialButtonBackground = Color(0xFFE3F0F9);
  static const setupStepBackground = Color(0xFFE5E9FF);
  static const subjectListBorder = Color(0xFFE6EBF0);
  static const scheduleBorder = Color(0xFFE9ECEF);
  static const restMessageBackground = Color(0xFFEAF0FF);
  static const taskEmptyBackground = Color(0xFFEEEDF9);
  static const evaluationSoftBackground = Color(0xFFEEEEFA);
  static const scheduleSummaryBackground = Color(0xFFF0F2FF);
  static const setupScheduleBackground = Color(0xFFF3F6FF);
  static const educaBadge = Color(0xFFF8DDE3);
  static const listBackground = Color(0xFFF8F9FA);
  static const campusOptionBackground = Color(0xFFF9F8FA);
  static const scheduleSurface = Color(0xFFFAFAFA);
  static const evaluationBackground = Color(0xFFFAFAFF);
  static const educaSoftBackground = Color(0xFFFFF1F3);
  static const illustrationHeader = Color(0xFF9EACF3);
  static const taskPinkBackground = Color(0xFFFBE4F1);
  static const taskPinkAccent = Color(0xFFA63B77);
  static const taskMintBackground = Color(0xFFDEF5F0);
  static const taskMintAccent = Color(0xFF277C79);
  static const taskBlueBackground = Color(0xFFE6EAFC);
  static const taskBlueAccent = Color(0xFF5366AB);
  static const taskOrangeBackground = Color(0xFFFFEEDC);
  static const taskOrangeAccent = Color(0xFF9D6428);
  static const taskOverdueBackground = Color(0xFFFFDCE2);
  static const cyan = Color(0xFF00BCD4);
  static const blue = Color(0xFF2196F3);
  static const indigo = Color(0xFF3F51B5);
  static const green = Color(0xFF4CAF50);
  static const blueGrey = Color(0xFF607D8B);
  static const grey600 = Color(0xFF757575);
  static const purple = Color(0xFF9C27B0);
  static const pink = Color(0xFFE91E63);
  static const deepOrange = Color(0xFFFF5722);
  static const orange = Color(0xFFFF9800);
  static const educaAccent = Color(0xFFE46A7D);
  static const primaryGradientEnd = Color(0xFF4A569D);
  static const secondaryGradientEnd = Color(0xFFC1D9F2);
  static const accentGradientEnd = Color(0xFFFF8F81);

  // Material color equivalents used by the existing UI.
  static const deepPurple = Color(0xFF673AB7);
  static const transparent = Color(0x00000000);
  static const red = Color(0xFFF44336);
  static const white70 = Color(0xB3FFFFFF);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey = Color(0xFF9E9E9E);
  static const black87 = Color(0xDD000000);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey500 = Color(0xFF9E9E9E);
  static const blue700 = Color(0xFF1976D2);
  static const grey700 = Color(0xFF616161);
  static const red50 = Color(0xFFFFEBEE);
  static const red200 = Color(0xFFEF9A9A);
  static const red400 = Color(0xFFEF5350);
  static const red700 = Color(0xFFD32F2F);
  static const black54 = Color(0x8A000000);
  static const white54 = Color(0x8AFFFFFF);
  static const blueAccent = Color(0xFF448AFF);

  static const subjectBackgrounds = [
    ClassliftColors.subjectRoseBackground,
    ClassliftColors.subjectMintBackground,
    ClassliftColors.subjectBlueBackground,
    ClassliftColors.subjectApricotBackground,
    ClassliftColors.subjectLavenderBackground,
    ClassliftColors.subjectYellowBackground,
    ClassliftColors.subjectTealBackground,
    ClassliftColors.subjectIndigoBackground,
    ClassliftColors.subjectPeachBackground,
    ClassliftColors.subjectPinkBackground,
    ClassliftColors.subjectSkyBackground,
    ClassliftColors.subjectGreenBackground,
    ClassliftColors.subjectCoralBackground,
    ClassliftColors.subjectLimeBackground,
    ClassliftColors.subjectPeriwinkleBackground,
    ClassliftColors.subjectAmberBackground,
    ClassliftColors.subjectOrchidBackground,
    ClassliftColors.subjectGoldBackground,
    ClassliftColors.subjectSeafoamBackground,
    ClassliftColors.subjectVioletBackground,
    ClassliftColors.subjectTerracottaBackground,
    ClassliftColors.subjectMauveBackground,
    ClassliftColors.subjectCyanBackground,
    ClassliftColors.subjectSageBackground,
  ];

  static final subjectAccents = {
    ClassliftColors.subjectRoseBackground: ClassliftColors.subjectRoseAccent,
    ClassliftColors.subjectMintBackground: ClassliftColors.subjectMintAccent,
    ClassliftColors.subjectBlueBackground: ClassliftColors.subjectBlueAccent,
    ClassliftColors.subjectApricotBackground:
        ClassliftColors.subjectApricotAccent,
    ClassliftColors.subjectLavenderBackground:
        ClassliftColors.subjectLavenderAccent,
    ClassliftColors.subjectYellowBackground:
        ClassliftColors.subjectYellowAccent,
    ClassliftColors.subjectTealBackground: ClassliftColors.subjectTealAccent,
    ClassliftColors.subjectIndigoBackground:
        ClassliftColors.subjectIndigoAccent,
    ClassliftColors.subjectPeachBackground: ClassliftColors.subjectPeachAccent,
    ClassliftColors.subjectPinkBackground: ClassliftColors.subjectPinkAccent,
    ClassliftColors.subjectSkyBackground: ClassliftColors.subjectSkyAccent,
    ClassliftColors.subjectGreenBackground: ClassliftColors.subjectGreenAccent,
    ClassliftColors.subjectCoralBackground: ClassliftColors.subjectCoralAccent,
    ClassliftColors.subjectLimeBackground: ClassliftColors.subjectLimeAccent,
    ClassliftColors.subjectPeriwinkleBackground:
        ClassliftColors.subjectPeriwinkleAccent,
    ClassliftColors.subjectAmberBackground: ClassliftColors.subjectAmberAccent,
    ClassliftColors.subjectOrchidBackground:
        ClassliftColors.subjectOrchidAccent,
    ClassliftColors.subjectGoldBackground: ClassliftColors.subjectGoldAccent,
    ClassliftColors.subjectSeafoamBackground:
        ClassliftColors.subjectSeafoamAccent,
    ClassliftColors.subjectVioletBackground:
        ClassliftColors.subjectVioletAccent,
    ClassliftColors.subjectTerracottaBackground:
        ClassliftColors.subjectTerracottaAccent,
    ClassliftColors.subjectMauveBackground: ClassliftColors.subjectMauveAccent,
    ClassliftColors.subjectCyanBackground: ClassliftColors.subjectCyanAccent,
    ClassliftColors.subjectSageBackground: ClassliftColors.subjectSageAccent,
  };

  static Color subjectBackgroundFor(int index) {
    if (index < subjectBackgrounds.length) return subjectBackgrounds[index];
    final hue = (index * 137.50776405003785) % 360;
    return HSLColor.fromAHSL(1, hue, 0.58, 0.9).toColor();
  }

  static Color subjectAccentFor(Color background) {
    return subjectAccents[background] ??
        HSLColor.fromColor(background)
            .withSaturation(0.58)
            .withLightness(0.38)
            .toColor();
  }
}
