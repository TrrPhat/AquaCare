import 'package:material_ui/material_ui.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.bodyFont,
      scaffoldBackgroundColor: AppColors.iceCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.cyanVivid,
        primary: AppColors.cyanVivid,
        secondary: AppColors.freshMint,
        tertiary: AppColors.sunnyButter,
        surface: AppColors.pureWhite,
        error: AppColors.softCoral,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navyInk,
        contentTextStyle: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontWeight: FontWeight.w700,
          color: AppColors.pureWhite,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.iceCanvas,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.cyanVivid, width: 1.8),
        ),
      ),
    );
  }
}
