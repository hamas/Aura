import 'package:flutter/material.dart';
import '../../core/theme/aura_theme.dart';

export '../../core/theme/app_colors.dart';
export '../../core/theme/app_tokens.dart';
export '../../core/theme/app_typography.dart';
export '../../core/theme/aura_theme.dart';
export '../../core/theme/aura_theme_extension.dart';

class AppTheme {
  AppTheme._();

  // Canvas / Scaffolds
  static const Color background = AppColors.surfaceBackground;
  static const Color surface = AppColors.surfaceCard;
  static const Color surfaceElevated = AppColors.surfaceElevated;
  static const Color surfaceCard = AppColors.surfaceCard;

  // Accents
  static const Color primaryAccent = AppColors.accentPink;
  static const Color secondaryAccent = AppColors.secondaryAccent;
  static const Color warningAccent = AppColors.warningAccent;
  static const Color successAccent = AppColors.successAccent;
  static const Color errorAccent = AppColors.errorAccent;

  // Typography
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textMuted;

  // Theme builder
  static ThemeData get darkTheme => AuraTheme.darkTheme;
}
