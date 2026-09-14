import 'package:flutter/material.dart';

/// Standard Material Symbol Icon primitive for Aura.
///
/// Enforces:
/// - Weight: 600 (Semi-Bold) by default
/// - Fill: 0.0 (Outline) by default (set `fill: 1.0` for solid variant)
class AuraIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final double weight;
  final double fill;
  final double? grade;
  final double? opticalSize;
  final String? semanticLabel;

  const AuraIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.weight = 600.0,
    this.fill = 0.0,
    this.grade,
    this.opticalSize,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
      weight: weight,
      fill: fill,
      grade: grade,
      opticalSize: opticalSize,
      semanticLabel: semanticLabel,
    );
  }
}
