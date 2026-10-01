import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Primary brand colors.
  static const primary = Color(0xFFD6900F);
  static const onPrimary = Color(0xFF000000);
  static const primaryContainer = Color(0xFFD6900F);

  static const secondary = Color(0xFFD6900F);
  static const secondaryContainer = Color(0xFFD6900F);
  static const onSecondaryContainer = Color(0xFF000000);

  static const background = Color(0xFFFAF9F5);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF4F2EB);
  static const surfaceContainer = Color(0xFFEDE9DF);
  static const surfaceHigh = Color(0xFFE5E0D3);
  static const surfaceHighest = Color(0xFFDCD5C4);

  static const onSurface = Color(0xFF000000);
  static const onSurfaceVariant = Color(0xFF4A463E);
  static const outline = Color(0xFF7A7569);
  static const outlineVariant = Color(0xFFCAC4B5);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);

  static Color getBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF000000)
          : const Color(0xFFFAF9F5);

  static Color getSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF171A1D)
          : const Color(0xFFFFFFFF);

  static Color getSurfaceLow(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1F2327)
          : const Color(0xFFF4F2EB);

  static Color getSurfaceContainer(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF272C32)
          : const Color(0xFFEDE9DF);

  static Color getSurfaceHigh(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF30363D)
          : const Color(0xFFE5E0D3);

  static Color getSurfaceHighest(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3B424B)
          : const Color(0xFFDCD5C4);

  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF7F8F9)
          : const Color(0xFF000000);

  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9EA3AB)
          : const Color(0xFF4A463E);

  static Color getBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF282D32)
          : const Color(0xFFDCD5C4);
}

extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get themeBg => AppColors.getBackground(this);
  Color get themeSurface => AppColors.getSurface(this);
  Color get themeSurfaceLow => AppColors.getSurfaceLow(this);
  Color get themeSurfaceContainer => AppColors.getSurfaceContainer(this);
  Color get themeSurfaceHigh => AppColors.getSurfaceHigh(this);
  Color get themeSurfaceHighest => AppColors.getSurfaceHighest(this);
  Color get themeTextPrimary => AppColors.getTextPrimary(this);
  Color get themeTextSecondary => AppColors.getTextSecondary(this);
  Color get themeBorder => AppColors.getBorder(this);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onPrimary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        surface: AppColors.surfaceLowest,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        tertiary: AppColors.primary,
        onTertiary: AppColors.onPrimary,
        tertiaryContainer: AppColors.primary,
        onTertiaryContainer: AppColors.onPrimary,
        surfaceTint: Colors.transparent,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
        fontFamilyFallback: [
          GoogleFonts.notoSansSinhala().fontFamily ?? 'NotoSansSinhala',
          GoogleFonts.notoSansTamil().fontFamily ?? 'NotoSansTamil',
        ],
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x66D6900F),
        selectionHandleColor: AppColors.primary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.onSurface,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceHighest),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLowest,
        hintStyle: const TextStyle(color: AppColors.outline, fontSize: 13.5),
        labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceHighest),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceHighest),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLowest,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.surfaceHighest),
    );
  }

  static ThemeData dark() {
    const darkBg = Color(0xFF000000);
    const darkSurface = Color(0xFF171A1D);
    const darkBorder = Color(0xFF282D32);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onPrimary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        surface: darkSurface,
        onSurface: Color(0xFFF7F8F9),
        onSurfaceVariant: Color(0xFF9EA3AB),
        outline: Color(0xFF636A73),
        outlineVariant: Color(0xFF282D32),
        tertiary: AppColors.primary,
        onTertiary: AppColors.onPrimary,
        tertiaryContainer: AppColors.primary,
        onTertiaryContainer: AppColors.onPrimary,
        surfaceTint: Colors.transparent,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: darkBg,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFF7F8F9),
        displayColor: const Color(0xFFF7F8F9),
        fontFamilyFallback: [
          GoogleFonts.notoSansSinhala().fontFamily ?? 'NotoSansSinhala',
          GoogleFonts.notoSansTamil().fontFamily ?? 'NotoSansTamil',
        ],
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: Color(0x66D6900F),
        selectionHandleColor: AppColors.primary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return null;
        }),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFFF7F8F9),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: const TextStyle(color: Color(0xFF636A73), fontSize: 13.5),
        labelStyle: const TextStyle(color: Color(0xFF9EA3AB)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: darkBorder),
    );
  }
}

