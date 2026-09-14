import 'package:flutter/material.dart';

/// Geometry, animation, and constraint tokens for Aura's design system.
class AppTokens {
  AppTokens._();

  // Aspect Ratios
  static const double posterAspectRatio = 2 / 3;
  static const double backdropAspectRatio = 16 / 9;

  // Standard Dimension Defaults
  static const double posterWidthMobile = 118.0;
  static const double posterHeightMobile = 177.0; // 118 * 1.5 (2:3)

  static const double continueWatchingWidth = 220.0;
  static const double continueWatchingHeight = 124.0; // ~16:9

  // Corner Radii (Clean, rectangular cinematic corners, avoiding bubble-radius M3 curves)
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 6.0;
  static const double radiusLarge = 8.0;
  static const double radiusPill = 999.0;

  static const BorderRadius borderRadiusSmall =
      BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium =
      BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge =
      BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusPill =
      BorderRadius.all(Radius.circular(radiusPill));

  // Focus & Motion Transitions
  static const double focusScaleFactor = 1.06;
  static const Duration focusAnimationDuration = Duration(milliseconds: 200);
  static const Curve focusAnimationCurve = Curves.easeOutCubic;

  // TV / Desktop Focus Outline
  static const double focusBorderWidth = 2.0;
}
