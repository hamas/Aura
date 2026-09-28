import 'package:flutter/material.dart';
import '../../../domain/entities/subtitle_cue.dart';
import '../../../domain/entities/subtitle_style_config.dart';

class DualSubtitleOverlay extends StatelessWidget {
  final List<SubtitleCue> primaryCues;
  final List<SubtitleCue> secondaryCues;
  final Duration currentPosition;
  final double offsetSeconds;
  final double fontScale;
  final SubtitleStyleConfig styleConfig;

  const DualSubtitleOverlay({
    super.key,
    this.primaryCues = const [],
    this.secondaryCues = const [],
    required this.currentPosition,
    this.offsetSeconds = 0.0,
    this.fontScale = 1.0,
    this.styleConfig = SubtitleStyleConfig.netflixWhite,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePositionMs =
        currentPosition.inMilliseconds - (offsetSeconds * 1000).round();

    final activePrimary = primaryCues.where((cue) {
      final startMs = cue.start.inMilliseconds;
      final endMs = cue.end.inMilliseconds;
      return effectivePositionMs >= startMs && effectivePositionMs <= endMs;
    }).toList();

    final activeSecondary = secondaryCues.where((cue) {
      final startMs = cue.start.inMilliseconds;
      final endMs = cue.end.inMilliseconds;
      return effectivePositionMs >= startMs && effectivePositionMs <= endMs;
    }).toList();

    return Stack(
      children: [
        // Secondary Subtitle Track (top or above primary)
        if (activeSecondary.isNotEmpty)
          Positioned(
            top: 48,
            left: 24,
            right: 24,
            child: Column(
              children: activeSecondary.map((cue) {
                return _SubtitleBadge(
                  text: cue.text,
                  textColor: const Color(0xFFE2C4FF),
                  borderColor: const Color(0x7FB877FF),
                  backgroundColor: const Color(0xA6000000),
                  fontSize: (styleConfig.fontSize - 3) * fontScale,
                  isBold: styleConfig.isBold,
                  hasShadow: styleConfig.hasTextShadow,
                );
              }).toList(),
            ),
          ),

        // Primary Subtitle Track (bottom of video canvas)
        if (activePrimary.isNotEmpty)
          Positioned(
            bottom: 64,
            left: 24,
            right: 24,
            child: Column(
              children: activePrimary.map((cue) {
                return _SubtitleBadge(
                  text: cue.text,
                  textColor: styleConfig.textColor,
                  borderColor: Colors.transparent,
                  backgroundColor: styleConfig.effectiveBackgroundColor,
                  isPrimary: true,
                  fontSize: styleConfig.fontSize * fontScale,
                  isBold: styleConfig.isBold,
                  hasShadow: styleConfig.hasTextShadow,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _SubtitleBadge extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;
  final bool isPrimary;
  final double fontSize;
  final bool isBold;
  final bool hasShadow;

  const _SubtitleBadge({
    required this.text,
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
    this.isPrimary = false,
    required this.fontSize,
    this.isBold = true,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: hasShadow
            ? [
                const BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

