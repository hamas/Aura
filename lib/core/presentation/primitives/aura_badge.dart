import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import '../../theme/aura_theme_extension.dart';

/// Universal pill badge for quality indicators (4K, HDR), ratings, episodes, and tags.
class AuraBadge extends StatelessWidget {
  final String label;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final double? fontSize;

  const AuraBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
    this.borderRadius,
    this.fontSize,
  });

  /// Factory for IMDb or TMDB star rating badge
  factory AuraBadge.rating(
    String rating, {
    Key? key,
    Color color = AppColors.warningAccent,
  }) {
    return AuraBadge(
      key: key,
      label: rating,
      icon: Icon(Icons.star_rounded, color: color, size: 12),
      backgroundColor: color.withAlpha((0.18 * 255).round()),
      borderColor: color.withAlpha((0.6 * 255).round()),
      textColor: color,
    );
  }

  /// Factory for 4K, HDR, 1080p, or Audio quality tags
  factory AuraBadge.quality(
    String text, {
    Key? key,
    Color textColor = AppColors.textPrimary,
  }) {
    return AuraBadge(
      key: key,
      label: text,
      backgroundColor: const Color(0x1AFFFFFF),
      borderColor: const Color(0x33FFFFFF),
      textColor: textColor,
    );
  }

  /// Factory for TV episode codes (e.g. S1:E3)
  factory AuraBadge.episode(
    int season,
    int episode, {
    Key? key,
  }) {
    return AuraBadge(
      key: key,
      label: 'S$season:E$episode',
      backgroundColor: Colors.black.withAlpha((0.85 * 255).round()),
      borderColor: Colors.white24,
      textColor: AppColors.textPrimary,
    );
  }

  /// Factory for Debrid or Account status pills
  factory AuraBadge.status(
    String label, {
    Key? key,
    bool active = true,
  }) {
    final color = active ? AppColors.successAccent : AppColors.textMuted;
    return AuraBadge(
      key: key,
      label: label,
      icon: Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      backgroundColor: color.withAlpha((0.15 * 255).round()),
      borderColor: color.withAlpha((0.4 * 255).round()),
      textColor: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeExt = context.auraTheme;
    final effectiveBg = backgroundColor ?? themeExt.badgeBackground;
    final effectiveBorder = borderColor ?? themeExt.badgeBorder;
    final effectiveTextColor = textColor ?? AppColors.textPrimary;
    final effectiveRadius = borderRadius ?? AppTokens.borderRadiusSmall;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: Border.all(color: effectiveBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 3),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.metadataPill.copyWith(
              color: effectiveTextColor,
              fontSize: fontSize ?? AppTypography.metadataPill.fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
