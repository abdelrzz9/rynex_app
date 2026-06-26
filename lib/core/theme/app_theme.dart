import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Design spec colors
  static const Color primaryPurple = Color(0xFF6C4DD3);
  static const Color primaryPurpleLight = Color(0xFFEDE5FF);
  static const Color primaryPurpleDark = Color(0xFF8E72FF);

  // Light theme
  static const Color lightBg = Color(0xFFF8F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF666666);

  // Dark theme
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF23233A);
  static const Color darkCard = Color(0xFF2A2A42);
  static const Color darkBorder = Color(0xFF3A3A52);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Legacy aliases for compatibility
  static const Color lightHover = Color(0xFFE8E8E8);
  static const Color lightSelected = Color(0xFFD0D0D0);
  static const Color darkHover = Color(0xFF303030);
  static const Color darkSelected = Color(0xFF3A3A3A);
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textDisabled = Color(0xFF757575);
  static const Color textPrimaryLight = lightTextPrimary;
  static const Color textSecondaryLight = lightTextSecondary;
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentDark = Color(0xFF2563EB);
  static const Color accentViolet = primaryPurple;
  static const Color accentVioletLight = primaryPurpleLight;
  static const Color accentVioletDark = Color(0xFF5B21B6);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryPurple,
        secondary: AppColors.primaryPurpleLight,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightBorder,
      ),
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightBorder,
      hoverColor: AppColors.lightHover,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextPrimary,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.lightTextPrimary),
        titleSmall: TextStyle(color: AppColors.lightTextSecondary),
        bodyMedium: TextStyle(color: AppColors.lightTextPrimary),
        bodySmall: TextStyle(color: AppColors.lightTextSecondary),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      canvasColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPurpleDark,
        onPrimary: Colors.white,
        secondary: AppColors.primaryPurpleLight,
        surface: AppColors.darkSurface,
        outline: AppColors.darkBorder,
      ),
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
      hoverColor: AppColors.darkHover,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkTextPrimary,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.darkTextPrimary),
        titleSmall: TextStyle(color: AppColors.darkTextSecondary),
        bodyMedium: TextStyle(color: AppColors.darkTextPrimary),
        bodySmall: TextStyle(color: AppColors.darkTextSecondary),
      ),
    );
  }
}
