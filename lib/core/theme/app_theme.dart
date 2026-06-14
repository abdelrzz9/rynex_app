import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark theme colors
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF222222);
  static const Color darkBorder = Color(0xFF2D2D2D);
  static const Color darkHover = Color(0xFF303030);
  static const Color darkSelected = Color(0xFF3A3A3A);

  // Light theme colors
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F0F0);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightHover = Color(0xFFE8E8E8);
  static const Color lightSelected = Color(0xFFD0D0D0);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFF757575);
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);

  // Accent
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentDark = Color(0xFF2563EB);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accentLight,
        surface: AppColors.lightSurface,
        onSurface: AppColors.textPrimaryLight,
        outline: AppColors.lightBorder,
      ),
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightBorder,
      hoverColor: AppColors.lightHover,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.textPrimaryLight,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryLight,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.textPrimaryLight),
        titleSmall: TextStyle(color: AppColors.textSecondaryLight),
        bodyMedium: TextStyle(color: AppColors.textPrimaryLight),
        bodySmall: TextStyle(color: AppColors.textSecondaryLight),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accentLight,
        surface: AppColors.darkSurface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.darkBorder,
      ),
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
      hoverColor: AppColors.darkHover,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: AppColors.textPrimary),
        titleSmall: TextStyle(color: AppColors.textSecondary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
