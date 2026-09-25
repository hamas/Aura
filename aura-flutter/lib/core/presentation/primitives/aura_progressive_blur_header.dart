import 'dart:ui';
import 'package:flutter/material.dart';

/// Progressive Blur Header Widget (Cross-platform: iOS, Android, Windows, macOS, Web)
/// Drop-in component for sticky headers with progressive blur — content scrolls underneath with increasing blur from bottom to top.
class AuraProgressiveBlurHeader extends StatelessWidget {
  final double height;
  final double maxBlurSigma;
  final Widget? child;
  final EdgeInsetsGeometry? padding;

  const AuraProgressiveBlurHeader({
    super.key,
    this.height = 90.0,
    this.maxBlurSigma = 24.0,
    this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: Stack(
        children: [
          // Progressive Multi-stage Blur Layer Stack
          Positioned.fill(
            child: Stack(
              children: List.generate(6, (index) {
                final progress = (index + 1) / 6.0;
                final blurSigma = maxBlurSigma * progress;
                final stopStart = index / 6.0;
                final stopEnd = (index + 1) / 6.0;

                return Positioned.fill(
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: progress),
                        ],
                        stops: [stopStart, stopEnd],
                      ).createShader(bounds);
                    },
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                      child: const ColoredBox(color: Colors.black12),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Ambient Dark Scrim Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.80),
                    Colors.black.withValues(alpha: 0.40),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.60, 1.0],
                ),
              ),
            ),
          ),

          // Header Content Foreground
          if (child != null)
            Padding(
              padding: padding ?? EdgeInsets.only(top: topPadding + 4, left: 16, right: 16),
              child: child!,
            ),
        ],
      ),
    );
  }
}
