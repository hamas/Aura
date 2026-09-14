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

  const PlayerBottomControlBar({
    super.key,
    required this.state,
    required this.onSeek,
    required this.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final pos = state.position;
    final dur = state.duration;
    final maxSec = dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0;
    final curSec = pos.inSeconds.toDouble().clamp(0.0, maxSec);
    final remaining = dur > pos ? dur - pos : Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                Formatters.formatDuration(pos),
                style: context.auraText.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: AppColors.accentPink,
                    inactiveTrackColor: AppColors.borderSubtle,
                    thumbColor: AppColors.accentPink,
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
              ),
              Text(
                '-${Formatters.formatDuration(remaining)}',
                style: context.auraText.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PlayerCenterControls extends StatelessWidget {
  final AuraPlayerState state;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onUserInteraction;

  const PlayerCenterControls({
    super.key,
    required this.state,
    required this.onPlayPause,
    required this.onSeek,
    required this.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isBuffering) {
      return const CircularProgressIndicator(
        color: AppColors.accentPink,
        strokeWidth: 3.5,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        IconButton(
          iconSize: 36,
          icon: const AuraIcon(AppIcons.replay10, color: AppColors.textPrimary),
          onPressed: () {
            final target = state.position - const Duration(seconds: 10);
            onSeek(target < Duration.zero ? Duration.zero : target);
            onUserInteraction();
          },
        ),
        const SizedBox(width: AppTokens.spacingXl),
        // Play / Pause
        Container(
          decoration: BoxDecoration(
            color: AppColors.accentPink.withAlpha((0.9 * 255).round()),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPink.withAlpha((0.4 * 255).round()),
                blurRadius: 16,
              ),
            ],
          ),
          child: IconButton(
            iconSize: 48,
            icon: AuraIcon(
              state.isPlaying ? AppIcons.pause : AppIcons.play,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              onPlayPause();
              onUserInteraction();
            },
          ),
        ),
        const SizedBox(width: AppTokens.spacingXl),
        // Forward 10s
        IconButton(
          iconSize: 36,
          icon:
              const AuraIcon(AppIcons.forward10, color: AppColors.textPrimary),
          onPressed: () {
            final target = state.position + const Duration(seconds: 10);
            onSeek(target > state.duration ? state.duration : target);
            onUserInteraction();
          },
        ),
      ],
    );
  }
}
