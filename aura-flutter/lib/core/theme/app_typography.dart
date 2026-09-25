import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized typography definitions for Aura's cinematic design system using Plus Jakarta Sans (Google Fonts).
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Plus Jakarta Sans';
  static const List<String> fontFamilyFallback = [
    'Google Sans',
    'Roboto',
    'sans-serif',
  ];

  static TextStyle _fontStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    required double letterSpacing,
    required double height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle get displayHero => _fontStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get sectionTitle => _fontStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.2,
      );

  static TextStyle get itemTitle => _fontStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
        height: 1.25,
      );

  static TextStyle get metadataPill => _fontStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
        height: 1.0,
      );

  static TextStyle get bodyOverview => _fontStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.0,
        height: 1.45,
      );

  static TextStyle get caption => _fontStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.0,
        height: 1.2,
      );

  /// Global TextTheme configured for Material 3 using Google Fonts Plus Jakarta Sans
  static TextTheme get textTheme {
    final baseTheme = TextTheme(
      displayLarge: displayHero,
      headlineMedium: sectionTitle,
      titleMedium: itemTitle,
      bodyMedium: bodyOverview,
      bodySmall: caption,
      labelSmall: metadataPill,
    );
    if (GoogleFonts.config.allowRuntimeFetching) {
      return GoogleFonts.plusJakartaSansTextTheme(baseTheme);
    }
    return baseTheme;
  }
}

/// Convenience extension on [BuildContext] for Aura typography
extension AuraTypographyExtension on BuildContext {
  TextTheme get auraText => Theme.of(this).textTheme;
  TextStyle get auraDisplayHero => AppTypography.displayHero;
}

extension TextThemeAuraExtension on TextTheme {
  TextStyle get displayHero => AppTypography.displayHero;
  TextStyle get sectionTitle => AppTypography.sectionTitle;
  TextStyle get itemTitle => AppTypography.itemTitle;
  TextStyle get metadataPill => AppTypography.metadataPill;
  TextStyle get bodyOverview => AppTypography.bodyOverview;
  TextStyle get caption => AppTypography.caption;
}
