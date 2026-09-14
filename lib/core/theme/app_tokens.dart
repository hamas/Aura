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

  // Standard Spacing Constants
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(spacingXs);
  static const EdgeInsets paddingSm = EdgeInsets.all(spacingSm);
  static const EdgeInsets paddingMd = EdgeInsets.all(spacingMd);
  static const EdgeInsets paddingLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets paddingXl = EdgeInsets.all(spacingXl);

  // Focus & Motion Transitions
  static const double focusScaleFactor = 1.06;
  static const Duration focusAnimationDuration = Duration(milliseconds: 200);
  static const Curve focusAnimationCurve = Curves.easeOutCubic;

  // TV / Desktop Focus Outline
  static const double focusBorderWidth = 2.0;
}
