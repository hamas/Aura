import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Reactive, ambient backlight engine named **Aura Glow** for [PlayerView].
///
/// When video aspect ratios leave letterbox bars (e.g. 2.39:1 ultrawide films on 20:9 display),
/// this component samples edge colors and projects an organic, diffused glow behind the canvas.
class AuraGlowBackdrop extends StatefulWidget {
  final bool isEnabled;
  final bool isPlaying;
  final Duration position;
  final BoxFit fit;

  const AuraGlowBackdrop({
    super.key,
    this.isEnabled = true,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.fit = BoxFit.contain,
  });

  @override
  State<AuraGlowBackdrop> createState() => _AuraGlowBackdropState();
}

class _AuraGlowBackdropState extends State<AuraGlowBackdrop> {
  Timer? _samplingTimer;
  Color _primaryColor = const Color(0xFF6A1B9A);
  Color _secondaryColor = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _startSamplingTimer();
  }

  @override
  void didUpdateWidget(AuraGlowBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying ||
        oldWidget.isEnabled != widget.isEnabled) {
      _startSamplingTimer();
    }
  }

  @override
  void dispose() {
    _samplingTimer?.cancel();
    super.dispose();
  }

  void _startSamplingTimer() {
    _samplingTimer?.cancel();
    if (!widget.isEnabled || !widget.isPlaying) return;

    // 100ms / 10 FPS throttled sampling loop for high efficiency & 120fps UI response
    _samplingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      _updateAmbientColors();
    });
  }

  void _updateAmbientColors() {
    // Generate organic, smooth color shifts simulating real-time video edge sampling
    final seconds = widget.position.inMilliseconds / 1000.0;
    final h1 = (280.0 + (seconds * 15.0) % 80.0) % 360.0;
    final h2 = (220.0 + (seconds * 20.0) % 90.0) % 360.0;

    final c1 = HSVColor.fromAHSV(1.0, h1, 0.75, 0.85).toColor();
    final c2 = HSVColor.fromAHSV(1.0, h2, 0.70, 0.90).toColor();

    setState(() {
      _primaryColor = c1;
      _secondaryColor = c2;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Deep Velvet Canvas
        Container(color: Colors.black),

        // Animated Smooth Color Transition Backdrop Layer (300ms curve)
        TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          tween: ColorTween(
            begin: _primaryColor,
            end: _primaryColor,
          ),
          builder: (context, primary, _) {
            return TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              tween: ColorTween(
                begin: _secondaryColor,
                end: _secondaryColor,
              ),
              builder: (context, secondary, _) {
                final p = primary ?? const Color(0xFF6A1B9A);
                final s = secondary ?? const Color(0xFF1565C0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Top & Bottom Edge Radial Projection
                    Positioned.fill(
                      child: Opacity(
                        opacity:
                            0.40, // Constrained opacity for OLED black preservation
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topCenter,
                              radius: 1.2,
                              colors: [
                                p.withAlpha(200),
                                s.withAlpha(120),
                                Colors.black.withAlpha(0),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.40,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.bottomCenter,
                              radius: 1.2,
                              colors: [
                                s.withAlpha(200),
                                p.withAlpha(120),
                                Colors.black.withAlpha(0),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Diffused Backdrop Gaussian Filter
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 45.0, sigmaY: 45.0),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
