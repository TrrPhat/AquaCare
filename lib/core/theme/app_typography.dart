import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Typography pairing from AquaCare Figma Sticker Sheet with true Variable Font (`wght`) axes
/// and generous line-heights for Vietnamese diacritics.
class AppTypography {
  const AppTypography._();

  static const String displayFont = 'PlusJakartaSans';
  static const String bodyFont = 'Quicksand';

  static List<FontVariation> wght(double value) => [
    FontVariation('wght', value),
  ];

  static TextStyle displayHero({Color color = AppColors.navyInk}) => TextStyle(
    fontFamily: displayFont,
    fontWeight: FontWeight.w800,
    fontVariations: wght(800),
    fontSize: 32,
    color: color,
    height: 1.18,
    letterSpacing: -0.4,
  );

  static TextStyle pillCta({Color color = AppColors.pureWhite}) => TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w800,
    fontVariations: wght(800),
    fontSize: 15.5,
    color: color,
    letterSpacing: 0.15,
    height: 1.25,
  );

  static TextStyle pageTitle({Color color = AppColors.navyInk}) => TextStyle(
    fontFamily: displayFont,
    fontWeight: FontWeight.w800,
    fontVariations: wght(800),
    fontSize: 20,
    color: color,
    height: 1.32,
    letterSpacing: -0.2,
  );

  static TextStyle headerTitle({Color color = AppColors.navyInk}) => TextStyle(
    fontFamily: displayFont,
    fontWeight: FontWeight.w700,
    fontVariations: wght(700),
    fontSize: 15.5,
    color: color,
    height: 1.32,
  );

  static TextStyle cardTitle({
    bool isKids = false,
    Color color = AppColors.navyInk,
  }) => TextStyle(
    fontFamily: isKids ? bodyFont : displayFont,
    fontWeight: FontWeight.w700,
    fontVariations: wght(700),
    fontSize: isKids ? 17 : 16,
    color: color,
    height: 1.34,
  );

  static TextStyle cardBody({Color color = AppColors.slateBody}) => TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w500,
    fontVariations: wght(500),
    fontSize: 13,
    color: color,
    height: 1.42,
  );

  static TextStyle metricLabel(Color color) => TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w700,
    fontVariations: wght(700),
    fontSize: 11.5,
    letterSpacing: 0.1,
    color: color,
    height: 1.32,
  );

  static TextStyle metricValue({
    bool isKids = false,
    Color color = AppColors.navyInk,
  }) => TextStyle(
    fontFamily: isKids ? bodyFont : displayFont,
    fontWeight: FontWeight.w700,
    fontVariations: wght(700),
    fontSize: 14,
    color: color,
    height: 1.32,
  );

  static TextStyle rowTitle({Color color = AppColors.navyInk}) => TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w700,
    fontVariations: wght(700),
    fontSize: 13.5,
    color: color,
    height: 1.36,
  );

  static TextStyle ctaLabel(Color color, {bool isKids = false}) => TextStyle(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w700,
    fontVariations: wght(700),
    fontSize: isKids ? 16 : 15,
    color: color,
    height: 1.3,
  );

  static TextStyle tabLabel({required bool active}) => TextStyle(
    fontFamily: bodyFont,
    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
    fontVariations: wght(active ? 700 : 600),
    fontSize: 10.5,
    color: active ? AppColors.oceanBlue : AppColors.mutedGrey,
    height: 1.25,
  );

  static TextStyle sectionCaption({Color color = AppColors.mutedGrey}) =>
      TextStyle(
        fontFamily: bodyFont,
        fontWeight: FontWeight.w700,
        fontVariations: wght(700),
        fontSize: 12,
        letterSpacing: 0.1,
        color: color,
        height: 1.34,
      );
}
