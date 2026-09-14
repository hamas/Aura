import 'package:flutter/material.dart';

/// Centralized color palette for Aura's Netflix-style cinematic design system.
class AppColors {
  AppColors._();

  // Canvas / Scaffolds (Deep Netflix dark slate)
  static const Color surfaceBackground = Color(0xFF141414);
  static const Color background = surfaceBackground;

  // Card & Container Fill
  static const Color surfaceCard = Color(0xFF1F1F1F);
  static const Color surface = surfaceCard;
  static const Color surfaceElevated = Color(0xFF262626);
  static const Color surfaceElevatedHigh = Color(0xFF333333);

  // Brand Accents
  static const Color accentPink =
      Color(0xFFB877FF); // Electric Violet/Pink Brand Accent
  static const Color primaryAccent = accentPink;
  static const Color secondaryAccent = Color(0xFF9D4EDD); // Deep Purple Accent
  static const Color warningAccent =
      Color(0xFFF59E0B); // Amber / 4K Badge / Rating
  static const Color successAccent = Color(0xFF10B981); // Emerald Green
  static const Color errorAccent = Color(0xFFEF4444); // Crimson Red
  static const Color statusSuccess = successAccent;
  static const Color statusWarning = warningAccent;
  static const Color statusError = errorAccent;
  static const Color borderSubtle = Color(0x1AFFFFFF);


  // Dark Neutral & Text Colors
  static const Color textPrimary = Color(0xFFF5F5F7); // 95% opacity white
  static const Color textSecondary = Color(0xFFA1A1AA); // Subtle metallic slate
  static const Color textMuted = Color(0xFF71717A); // Muted grey

  // Translucent / Glass Fill Tokens
  static const Color glassWhite = Color(0x33FFFFFF);
  static const Color glassBlack = Color(0x99000000);
  static const Color glassOverlay = Color(0x66141414);

  // Vignette Gradients
  static const LinearGradient heroTopVignette = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xCC000000),
      Colors.transparent,
    ],
  );

  static const LinearGradient heroBottomVignette = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x99141414),
      Color(0xFF141414),
    ],
    stops: [0.0, 0.6, 1.0],
  );
}
