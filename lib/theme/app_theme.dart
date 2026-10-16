import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // brand colors
  static const primary = Color(0xFFD6900F);
  static const onPrimary = Color(0xFF17140F);
  static const primaryContainer = Color(0xFFD6900F);

  static const secondary = Color(0xFFD6900F);
  static const secondaryContainer = Color(0xFFD6900F);
  static const onSecondaryContainer = Color(0xFF17140F);

  // light theme
  static const amberDark = Color(0xFF9A6206);
  static const amberTint = Color(0xFFFBF0DA);
  static const ink = Color(0xFF17140F);
  static const textSecondary = Color(0xFF4A463E);
  static const muted = Color(0xFF6B665B);
  static const background = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF2EEE5);
  static const border = Color(0xFFECE6D9);

  // status colors
  static const success = Color(0xFF1E7F47);
  static const successTint = Color(0xFFE2F3E8);
  static const danger = Color(0xFFB3261E);
  static const dangerTint = Color(0xFFFCE4E1);
  static const info = Color(0xFF1F5FBF);
  static const infoTint = Color(0xFFE3ECFA);
  static const warning = Color(0xFFD6900F);
  static const warningTint = Color(0xFFFBF0DA);

  // legacy aliases
  static const surfaceLow = Color(0xFFF4F2EB);
  static const surfaceContainer = Color(0xFFEDE9DF);
  static const surfaceHigh = Color(0xFFE5E0D3);
  static const surfaceHighest = Color(0xFFDCD5C4);
  static const onSurface = Color(0xFF17140F);
  static const onSurfaceVariant = Color(0xFF4A463E);
  static const outline = Color(0xFF6B665B);
  static const outlineVariant = Color(0xFFECE6D9);
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFFCE4E1);

  // theme helpers

  static Color getBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0B0C0E)
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
          : const Color(0xFF17140F);

  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9EA3AB)
          : const Color(0xFF4A463E);

  static Color getBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF282D32)
          : const Color(0xFFECE6D9);

  static Color getHeroSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1F2327)
          : const Color(0xFF17140F);

  static Color getHeroBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF30363D)
          : Colors.transparent;

  static Color getSoft(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF272C32)
          : const Color(0xFFF2EEE5);

  static Color getAmberText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF0B44A)
          : const Color(0xFF9A6206);

  static Color getAmberTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0x29D6900F)
          : const Color(0xFFFBF0DA);

  static Color getSuccess(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF6FD49A)
          : const Color(0xFF1E7F47);

  static Color getSuccessTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0x381E7F47)
          : const Color(0xFFE2F3E8);

  static Color getDanger(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFF8A80)
          : const Color(0xFFB3261E);

  static Color getDangerTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0x38B3261E)
          : const Color(0xFFFCE4E1);

  static Color getInfo(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8AB4F8)
          : const Color(0xFF1F5FBF);

  static Color getInfoTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0x381F5FBF)
          : const Color(0xFFE3ECFA);

  static Color getMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF636A73)
          : const Color(0xFF6B665B);

  static Color getInk(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF7F8F9)
          : const Color(0xFF17140F);
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
  Color get themeHeroSurface => AppColors.getHeroSurface(this);
  Color get themeHeroBorder => AppColors.getHeroBorder(this);
  Color get themeSoft => AppColors.getSoft(this);
  Color get themeAmberText => AppColors.getAmberText(this);
  Color get themeAmberTint => AppColors.getAmberTint(this);
  Color get themeSuccess => AppColors.getSuccess(this);
  Color get themeSuccessTint => AppColors.getSuccessTint(this);
  Color get themeDanger => AppColors.getDanger(this);
  Color get themeDangerTint => AppColors.getDangerTint(this);
  Color get themeInfo => AppColors.getInfo(this);
  Color get themeInfoTint => AppColors.getInfoTint(this);
  Color get themeMuted => AppColors.getMuted(this);
  Color get themeInk => AppColors.getInk(this);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.amberTint,
        onPrimaryContainer: AppColors.amberDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onPrimary,
        secondaryContainer: AppColors.amberTint,
        onSecondaryContainer: AppColors.amberDark,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        tertiary: AppColors.primary,
        onTertiary: AppColors.onPrimary,
        tertiaryContainer: AppColors.amberTint,
        onTertiaryContainer: AppColors.amberDark,
        surfaceTint: Colors.transparent,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.dangerTint,
        onErrorContainer: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: AppColors.border, width: 1.5),
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
          return AppColors.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.amberTint;
          }
          return AppColors.soft;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.border),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.muted;
        }),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.amberDark,
          minimumSize: const Size(64, 40),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          minimumSize: const Size(64, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(64, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(64, 54),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.soft,
        selectedColor: AppColors.ink,
        labelStyle: const TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13.5),
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        dragHandleColor: AppColors.border,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData dark() {
    const darkBg = Color(0xFF0B0C0E);
    const darkSurface = Color(0xFF171A1D);
    const darkBorder = Color(0xFF282D32);
    const darkText = Color(0xFFF7F8F9);
    const darkTextSecondary = Color(0xFF9EA3AB);
    const darkMuted = Color(0xFF636A73);
    const darkSoft = Color(0xFF272C32);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: Color(0x29D6900F),
        onPrimaryContainer: Color(0xFFF0B44A),
        secondary: AppColors.secondary,
        onSecondary: AppColors.onPrimary,
        secondaryContainer: Color(0x29D6900F),
        onSecondaryContainer: Color(0xFFF0B44A),
        surface: darkSurface,
        onSurface: darkText,
        onSurfaceVariant: darkTextSecondary,
        outline: darkBorder,
        outlineVariant: darkBorder,
        tertiary: AppColors.primary,
        onTertiary: AppColors.onPrimary,
        tertiaryContainer: Color(0x29D6900F),
        onTertiaryContainer: Color(0xFFF0B44A),
        surfaceTint: Colors.transparent,
        error: Color(0xFFFF8A80),
        onError: Color(0xFF17140F),
        errorContainer: Color(0x38B3261E),
        onErrorContainer: Color(0xFFFF8A80),
      ),
      scaffoldBackgroundColor: darkBg,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: darkText,
        displayColor: darkText,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: darkBorder, width: 1.5),
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
          return darkMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0x40D6900F);
          }
          return darkSoft;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(darkBorder),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return darkMuted;
        }),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFF0B44A),
          minimumSize: const Size(64, 40),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkText,
          side: const BorderSide(color: darkBorder, width: 1.5),
          minimumSize: const Size(64, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(64, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(64, 54),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: darkText,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSoft,
        selectedColor: Colors.white,
        labelStyle: const TextStyle(
          color: darkText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFF17140F),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: const TextStyle(color: darkMuted, fontSize: 13.5),
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.8),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        dragHandleColor: darkBorder,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2327),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
