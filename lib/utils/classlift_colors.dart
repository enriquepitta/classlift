import 'package:flutter/material.dart';

class ClassliftColors {
  static const Color PrimaryColor = Color(0xFF333D86); // Azul oscuro
  static const Color SecondaryColor = Color(0xFFA3C1E2); // Azul claro
  static const Color AccentColor = Color(0xFFFF6F61); // Coral
  static const Color BackgroundColor = Color(0xFFF5F5F5); // Gris claro
  static const Color TextColor = Color(0xFF333333); // Gris oscuro
  static const Color White = Color(0xFFFFFFFF); // Blanco
  static const Color Black = Color(0xFF000000); // Negro

  // Tonalidades intercaladas
  static const careerColorEven = Color(0xFFEDEDED); // gris claro
  static const careerColorOdd = Color(0xFFDADADA);  // gris medio claro

  static const semesterColorEven = Color(0xFFF0F0F0); // un poco más suave
  static const semesterColorOdd = Color(0xFFE0E0E0);  // gris neutro

  static const subjectColorEven = Color(0xFFFFFFFF);  // blanco
  static const subjectColorOdd = Color(0xFFF7F7F7);   // gris muy muy claro

  static const selectAllColor = Color(0xFFEBF1F4);    // gris azulado claro, para destacar suavemente

  // Degradados
  static LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF333D86), Color(0xFF4A569D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFA3C1E2), Color(0xFFC1D9F2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6F61), Color(0xFFFF8F81)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}