import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized typography definitions for Aura's cinematic design system.
class AppTypography {
  AppTypography._();

  /// Billboard hero main titles (28-32sp, heavy off-white)
  static const TextStyle displayHero = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.1,
  );

  /// Shelf and section category titles (20-22sp, bold off-white)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.2,
  );

  /// Media card and item titles (15-16sp, semi-bold)
  static const TextStyle itemTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.25,
  );

  /// Metadata tags, quality pills (11-12sp, bold uppercase)
  static const TextStyle metadataPill = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.0,
  );

  /// Synopsis, overview, and cast descriptions (14sp, slate-metallic)
  static const TextStyle bodyOverview = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.0,
    height: 1.45,
  );

  /// Captions, timestamps, and subtle hints (12sp, muted slate)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.0,
    height: 1.2,
  );

  /// Global TextTheme configured for Material 3
  static TextTheme get textTheme => const TextTheme(
        displayLarge: displayHero,
        headlineMedium: sectionTitle,
        titleMedium: itemTitle,
        bodyMedium: bodyOverview,
        bodySmall: caption,
        labelSmall: metadataPill,
      );
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
