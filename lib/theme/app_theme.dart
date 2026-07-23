import 'package:flutter/material.dart';

class AppColors {
  static const deepGreen = Color(0xFF0B3D2E);
  static const fieldGreen = Color(0xFF146C4A);
  static const mint = Color(0xFF3D9B74);
  static const cream = Color(0xFFF3F0E6);
  static const paper = Color(0xFFFFFBF2);
  static const ink = Color(0xFF1A1F1C);
  static const muted = Color(0xFF5C6B63);
  static const redBall = Color(0xFFC62828);
  static const blueBall = Color(0xFF1565C0);
  static const emptySlot = Color(0xFF8D6E63);
  static const accent = Color(0xFFD4A017);
  static const hit = Color(0xFF2E7D32);
}

class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

ThemeData buildAppTheme() {
  const textTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      height: 1.35,
      color: AppColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      height: 1.4,
      color: AppColors.ink,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      letterSpacing: 0.3,
      height: 1.5,
      color: AppColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      letterSpacing: 0.25,
      height: 1.5,
      color: AppColors.ink,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      letterSpacing: 0.35,
      height: 1.45,
      color: AppColors.muted,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      height: 1.3,
    ),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.fieldGreen,
      brightness: Brightness.light,
      primary: AppColors.fieldGreen,
      secondary: AppColors.accent,
      surface: AppColors.paper,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    fontFamily: 'Segoe UI',
    textTheme: textTheme,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.deepGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.paper,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.deepGreen.withValues(alpha: 0.08)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.fieldGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(letterSpacing: 0.4, color: AppColors.muted),
    ),
  );
}
