import 'dart:async';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class PlayerGestureOverlay extends StatefulWidget {
  final Widget child;
  final Duration currentPosition;
  final Duration totalDuration;
  final ValueChanged<Duration> onSeekTo;
  final ValueChanged<bool> onToggleHud;
  final ValueChanged<double>? onVolumeChanged;
  final ValueChanged<double>? onBrightnessChanged;

  const PlayerGestureOverlay({
    super.key,
    required this.child,
    required this.currentPosition,
    required this.totalDuration,
    required this.onSeekTo,
    required this.onToggleHud,
    this.onVolumeChanged,
    this.onBrightnessChanged,
  });

  @override
  State<PlayerGestureOverlay> createState() => _PlayerGestureOverlayState();
}

class _PlayerGestureOverlayState extends State<PlayerGestureOverlay> {
  double _volume = 0.8;
  double _brightness = 0.7;
  bool _showLeftHud = false;
  bool _showRightHud = false;
  bool _isScrubbing = false;
  Duration _scrubTarget = Duration.zero;
  int _scrubDeltaSeconds = 0;
  bool _showDoubleTapLeft = false;
  bool _showDoubleTapRight = false;
  Timer? _doubleTapTimer;

  void _onVerticalDragUpdate(DragUpdateDetails details, double screenWidth) {
    final dx = details.localPosition.dx;
    final delta = details.primaryDelta ?? 0;

    if (dx < screenWidth * 0.4) {
      // Left Zone: Brightness
      setState(() {
        _brightness = (_brightness - (delta / 250.0)).clamp(0.0, 1.0);
        _showLeftHud = true;
      });
      widget.onBrightnessChanged?.call(_brightness);
    } else if (dx > screenWidth * 0.6) {
      // Right Zone: Volume
      setState(() {
        _volume = (_volume - (delta / 250.0)).clamp(0.0, 1.0);
        _showRightHud = true;
      });
      widget.onVolumeChanged?.call(_volume);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showLeftHud = false;
          _showRightHud = false;
        });
      }
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isScrubbing = true;
      _scrubTarget = widget.currentPosition;
      _scrubDeltaSeconds = 0;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double screenWidth) {
    final deltaPixels = details.primaryDelta ?? 0;
    final secondsPerPixel =
        widget.totalDuration.inSeconds / (screenWidth * 1.5);
    final deltaSeconds = (deltaPixels * secondsPerPixel).round();

    setState(() {
      _scrubDeltaSeconds += deltaSeconds;
      final newTargetMs =
          (widget.currentPosition.inMilliseconds + (_scrubDeltaSeconds * 1000))
              .clamp(0, widget.totalDuration.inMilliseconds);
      _scrubTarget = Duration(milliseconds: newTargetMs);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    widget.onSeekTo(_scrubTarget);
    setState(() {
      _isScrubbing = false;
      _scrubDeltaSeconds = 0;
    });
  }

  void _handleTapPosition(Offset localPosition, double screenWidth) {
    final dx = localPosition.dx;
    if (dx < screenWidth * 0.3) {
      _triggerDoubleTapSeek(isForward: false);
    } else if (dx > screenWidth * 0.7) {
      _triggerDoubleTapSeek(isForward: true);
    } else {
      widget.onToggleHud(true);
    }
  }

  void _triggerDoubleTapSeek({required bool isForward}) {
    final delta =
        isForward ? const Duration(seconds: 10) : const Duration(seconds: -10);
    final target = Duration(
      milliseconds:
          (widget.currentPosition.inMilliseconds + delta.inMilliseconds)
              .clamp(0, widget.totalDuration.inMilliseconds),
    );
    widget.onSeekTo(target);

    setState(() {
      if (isForward) {
        _showDoubleTapRight = true;
      } else {
        _showDoubleTapLeft = true;
      }
    });

    _doubleTapTimer?.cancel();
    _doubleTapTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showDoubleTapLeft = false;
          _showDoubleTapRight = false;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = duration.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, screenWidth),
      onVerticalDragEnd: _onVerticalDragEnd,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: (d) => _onHorizontalDragUpdate(d, screenWidth),
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onDoubleTapDown: (d) => _handleTapPosition(d.localPosition, screenWidth),
      onTap: () => widget.onToggleHud(true),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,

          // Left Brightness HUD Pill
          if (_showLeftHud)
            Positioned(
              left: 24,
              top: 100,
              bottom: 100,
              child: _buildHudPill(
                icon: Icons.brightness_medium_rounded,
                value: _brightness,
              ),
            ),

          // Right Volume HUD Pill
          if (_showRightHud)
            Positioned(
              right: 24,
              top: 100,
              bottom: 100,
              child: _buildHudPill(
                icon: Icons.volume_up_rounded,
                value: _volume,
              ),
            ),

          // Center Scrubbing Badge
          if (_isScrubbing)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentPink, width: 1.5),
                ),
                child: Text(
                  '${_formatDuration(_scrubTarget)} / ${_formatDuration(widget.totalDuration)} (${_scrubDeltaSeconds >= 0 ? "+" : ""}${_scrubDeltaSeconds}s)',
                  style: context.auraText.bodyOverview.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Double Tap Seeking Ripple Feedback
          if (_showDoubleTapLeft)
            const Positioned(
              left: 40,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_rewind_rounded,
                        size: 48, color: Colors.white70),
                    Text('-10s',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          if (_showDoubleTapRight)
            const Positioned(
              right: 40,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_forward_rounded,
                        size: 48, color: Colors.white70),
                    Text('+10s',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHudPill({required IconData icon, required double value}) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 12),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white24,
                color: AppColors.accentPink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
