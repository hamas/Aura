import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ThemeExtension for Aura surface cards, focus rings, and badge styling.
class AuraThemeExtension extends ThemeExtension<AuraThemeExtension> {
  final Color cardBackground;
  final Color cardElevated;
  final Color focusBorder;
  final Color unfocusedBorder;
  final Color badgeBackground;
  final Color badgeBorder;

  const AuraThemeExtension({
    required this.cardBackground,
    required this.cardElevated,
    required this.focusBorder,
    required this.unfocusedBorder,
    required this.badgeBackground,
    required this.badgeBorder,
  });

  /// Default dark theme values
  static const AuraThemeExtension dark = AuraThemeExtension(
    cardBackground: AppColors.surfaceCard,
    cardElevated: AppColors.surfaceElevated,
    focusBorder: AppColors.accentPink,
    unfocusedBorder: Color(0x0FFFFFFF), // 6% white opacity
    badgeBackground: Color(0x14FFFFFF), // 8% white opacity
    badgeBorder: Color(0x26FFFFFF), // 15% white opacity
  );

  @override
  AuraThemeExtension copyWith({
    Color? cardBackground,
    Color? cardElevated,
    Color? focusBorder,
    Color? unfocusedBorder,
    Color? badgeBackground,
    Color? badgeBorder,
  }) {
    return AuraThemeExtension(
      cardBackground: cardBackground ?? this.cardBackground,
      cardElevated: cardElevated ?? this.cardElevated,
      focusBorder: focusBorder ?? this.focusBorder,
      unfocusedBorder: unfocusedBorder ?? this.unfocusedBorder,
      badgeBackground: badgeBackground ?? this.badgeBackground,
      badgeBorder: badgeBorder ?? this.badgeBorder,
    );
  }

  @override
  AuraThemeExtension lerp(
    ThemeExtension<AuraThemeExtension>? other,
    double t,
  ) {
    if (other is! AuraThemeExtension) {
      return this;
    }
    return AuraThemeExtension(
      cardBackground:
          Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
      cardElevated:
          Color.lerp(cardElevated, other.cardElevated, t) ?? cardElevated,
      focusBorder: Color.lerp(focusBorder, other.focusBorder, t) ?? focusBorder,
      unfocusedBorder: Color.lerp(unfocusedBorder, other.unfocusedBorder, t) ??
          unfocusedBorder,
      badgeBackground: Color.lerp(badgeBackground, other.badgeBackground, t) ??
          badgeBackground,
      badgeBorder: Color.lerp(badgeBorder, other.badgeBorder, t) ?? badgeBorder,
    );
  }
}

/// Convenience extension on [BuildContext] to access [AuraThemeExtension]
extension AuraThemeExtensionHelper on BuildContext {
  AuraThemeExtension get auraTheme =>
      Theme.of(this).extension<AuraThemeExtension>() ?? AuraThemeExtension.dark;
}
