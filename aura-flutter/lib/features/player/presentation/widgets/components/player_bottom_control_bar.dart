import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/player_state.dart';

class PlayerBottomControlBar extends StatelessWidget {
  final AuraPlayerState state;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onUserInteraction;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onNextEpisode;

  const PlayerBottomControlBar({
    super.key,
    required this.state,
    required this.onSeek,
    required this.onUserInteraction,
    this.onToggleFullscreen,
    this.onNextEpisode,
  });

  @override
  Widget build(BuildContext context) {
    final pos = state.position;
    final dur = state.duration;
    final maxSec = dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0;
    final curSec = pos.inSeconds.toDouble().clamp(0.0, maxSec);
    final bufSec = state.buffer.inSeconds.toDouble().clamp(0.0, maxSec);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // YouTube Style Red/Accent Scrubber with Buffer Track
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Buffer progress bar
              if (maxSec > 0 && bufSec > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FractionallySizedBox(
                    widthFactor: (bufSec / maxSec).clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                    elevation: 3,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppColors.accentPink,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: AppColors.accentPink,
                  overlayColor: AppColors.accentPink.withAlpha(40),
                ),
                child: Slider(
                  value: curSec,
                  min: 0.0,
                  max: maxSec,
                  onChanged: (val) {
                    onUserInteraction();
                    onSeek(Duration(seconds: val.toInt()));
                  },
                ),
              ),
            ],
          ),

          // Timecode and Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingSm),
            child: Row(
              children: [
                // YouTube style timecode: 04:12 / 1:48:30
                Text(
                  '${Formatters.formatDuration(pos)} / ${Formatters.formatDuration(dur)}',
                  style: context.auraText.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // Next episode button if series
                if (onNextEpisode != null)
                  IconButton(
                    icon: const AuraIcon(AppIcons.skipNext, color: Colors.white, size: 22),
                    tooltip: 'Next Episode',
                    onPressed: onNextEpisode,
                  ),
                // Fullscreen / Exit Fullscreen Button
                IconButton(
                  icon: const AuraIcon(AppIcons.fullscreen, color: Colors.white, size: 22),
                  tooltip: 'Fullscreen',
                  onPressed: onToggleFullscreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerCenterControls extends StatefulWidget {
  final AuraPlayerState state;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onUserInteraction;
  final VoidCallback? onRetry;

  const PlayerCenterControls({
    super.key,
    required this.state,
    required this.onPlayPause,
    required this.onSeek,
    required this.onUserInteraction,
    this.onRetry,
  });

  @override
  State<PlayerCenterControls> createState() => _PlayerCenterControlsState();
}

class _PlayerCenterControlsState extends State<PlayerCenterControls> {
  Timer? _bufferingTimeoutTimer;
  bool _isBufferingTimedOut = false;

  @override
  void initState() {
    super.initState();
    _checkBufferingStatus();
  }

  @override
  void didUpdateWidget(covariant PlayerCenterControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.isBuffering != oldWidget.state.isBuffering) {
      _checkBufferingStatus();
    }
  }

  void _checkBufferingStatus() {
    _bufferingTimeoutTimer?.cancel();
    if (widget.state.isBuffering) {
      // 20-second timeout for buffering
      _bufferingTimeoutTimer = Timer(const Duration(seconds: 20), () {
        if (mounted && widget.state.isBuffering) {
          setState(() => _isBufferingTimedOut = true);
        }
      });
    } else {
      if (_isBufferingTimedOut) {
        setState(() => _isBufferingTimedOut = false);
      }
    }
  }

  @override
  void dispose() {
    _bufferingTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Buffering Timeout Error with Retry action
    if (widget.state.isBuffering && _isBufferingTimedOut) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingLg,
          vertical: AppTokens.spacingMd,
        ),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          border: Border.all(color: AppColors.statusError),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.statusError, size: 36),
            const SizedBox(height: 8),
            const Text(
              'Stream took too long to load.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check your connection or try another stream.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tap to Retry'),
              onPressed: () {
                setState(() => _isBufferingTimedOut = false);
                _checkBufferingStatus();
                widget.onRetry?.call();
              },
            ),
          ],
        ),
      );
    }

    // Normal Buffering Spinner
    if (widget.state.isBuffering) {
      return const SizedBox(
        width: 52,
        height: 52,
        child: CircularProgressIndicator(
          color: AppColors.accentPink,
          strokeWidth: 3.5,
        ),
      );
    }

    // Smooth Quick-Action Controls: [Previous / -10s] [Circular Play/Pause] [Next / +10s]
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        IconButton(
          iconSize: 42,
          icon: const AuraIcon(AppIcons.replay10, color: Colors.white),
          onPressed: () {
            final target = widget.state.position - const Duration(seconds: 10);
            widget.onSeek(target < Duration.zero ? Duration.zero : target);
            widget.onUserInteraction();
          },
        ),
        const SizedBox(width: AppTokens.spacingXl),
        // Large Circular Play / Pause Button
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(160),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: IconButton(
            iconSize: 36,
            icon: AuraIcon(
              widget.state.isPlaying ? AppIcons.pause : AppIcons.play,
              color: Colors.white,
            ),
            onPressed: () {
              widget.onPlayPause();
              widget.onUserInteraction();
            },
          ),
        ),
        const SizedBox(width: AppTokens.spacingXl),
        // Forward 10s
        IconButton(
          iconSize: 42,
          icon: const AuraIcon(AppIcons.forward10, color: Colors.white),
          onPressed: () {
            final target = widget.state.position + const Duration(seconds: 10);
            widget.onSeek(target > widget.state.duration ? widget.state.duration : target);
            widget.onUserInteraction();
          },
        ),
      ],
    );
  }
}
