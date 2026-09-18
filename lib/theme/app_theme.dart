import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF00685F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF008378);

  static const secondaryContainer = Color(0xFFFEA619);
  static const onSecondaryContainer = Color(0xFF684000);

  static const background = Color(0xFFFAF8FF);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF2F3FF);
  static const surfaceContainer = Color(0xFFEAEDFF);
  static const surfaceHigh = Color(0xFFE2E7FF);
  static const surfaceHighest = Color(0xFFDAE2FD);

  static const onSurface = Color(0xFF131B2E);
  static const onSurfaceVariant = Color(0xFF3D4947);
  static const outline = Color(0xFF6D7A77);
  static const outlineVariant = Color(0xFFBCC9C6);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondaryContainer,
        surface: AppColors.surfaceLowest,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.onSurface,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.surfaceHighest),
    );
  }
}
