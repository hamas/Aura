import 'package:flutter/material.dart';

/// Configuration model for customizable subtitle appearance.
class SubtitleStyleConfig {
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final double backgroundOpacity;
  final bool hasTextShadow;
  final bool isBold;

  const SubtitleStyleConfig({
    this.fontSize = 18.0,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.backgroundOpacity = 0.75,
    this.hasTextShadow = true,
    this.isBold = true,
  });

  /// Preset for Netflix Standard White
  static const SubtitleStyleConfig netflixWhite = SubtitleStyleConfig(
    fontSize: 18.0,
    textColor: Colors.white,
    backgroundColor: Colors.black,
    backgroundOpacity: 0.75,
    hasTextShadow: true,
    isBold: true,
  );

  /// Preset for Netflix High Contrast Yellow
  static const SubtitleStyleConfig netflixYellow = SubtitleStyleConfig(
    fontSize: 18.0,
    textColor: Color(0xFFFFEB3B),
    backgroundColor: Colors.black,
    backgroundOpacity: 0.85,
    hasTextShadow: true,
    isBold: true,
  );

  /// Preset for Minimalist Transparent Box
  static const SubtitleStyleConfig cleanOutline = SubtitleStyleConfig(
    fontSize: 18.0,
    textColor: Colors.white,
    backgroundColor: Colors.transparent,
    backgroundOpacity: 0.0,
    hasTextShadow: true,
    isBold: true,
  );

  SubtitleStyleConfig copyWith({
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    double? backgroundOpacity,
    bool? hasTextShadow,
    bool? isBold,
  }) {
    return SubtitleStyleConfig(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      hasTextShadow: hasTextShadow ?? this.hasTextShadow,
      isBold: isBold ?? this.isBold,
    );
  }

  Color get effectiveBackgroundColor =>
      backgroundColor.withValues(alpha: backgroundOpacity);
}
