import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/player_state.dart';
import 'player_track_pickers.dart';

class PlayerTopControlBar extends StatelessWidget {
  final AuraPlayerState state;
  final VoidCallback onBack;
  final VoidCallback? onWatchTogether;
  final VoidCallback? onPictureInPicture;
  final ValueChanged<BoxFit> onAspectRatioChange;
  final ValueChanged<double> onSpeedChange;
  final VoidCallback? onToggleAuraGlow;
  final VoidCallback onShowSubtitlePicker;
  final VoidCallback onShowAudioPicker;

  const PlayerTopControlBar({
    super.key,
    required this.state,
    required this.onBack,
    this.onWatchTogether,
    this.onPictureInPicture,
    required this.onAspectRatioChange,
    required this.onSpeedChange,
    this.onToggleAuraGlow,
    required this.onShowSubtitlePicker,
    required this.onShowAudioPicker,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const AuraIcon(AppIcons.arrowBackIosNew, color: Colors.white),
            onPressed: onBack,
          ),
          const SizedBox(width: AppTokens.spacingSm),
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.title ?? 'Aura Player',
                  style: context.auraText.itemTitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.subtitle != null && state.subtitle!.isNotEmpty)
                  Text(
                    state.subtitle!,
                    style: context.auraText.caption.copyWith(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Aspect Ratio / Zoom Toggle
          IconButton(
            icon: AuraIcon(
              AppIcons.aspectRatio,
              color: state.fit == BoxFit.cover ? AppColors.accentPink : Colors.white,
            ),
            tooltip: state.fit == BoxFit.cover ? 'Zoomed to fill' : 'Original aspect ratio',
            onPressed: () {
              final nextFit = state.fit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
              onAspectRatioChange(nextFit);
            },
          ),
          // Subtitle Track Button
          IconButton(
            icon: AuraIcon(
              AppIcons.subtitles,
              color: state.selectedSubtitleTrack != null
                  ? AppColors.accentPink
                  : Colors.white,
            ),
            tooltip: 'Subtitles & Audio',
            onPressed: onShowSubtitlePicker,
          ),
          // Audio & Speed picker
          IconButton(
            icon: const AuraIcon(AppIcons.speed, color: Colors.white),
            tooltip: 'Playback Speed',
            onPressed: () {
              PlayerTrackPickers.showPlaybackSpeedPicker(
                context: context,
                currentSpeed: state.rate,
                onSelectSpeed: onSpeedChange,
              );
            },
          ),
          // Overflow Menu (Stats for nerds, Watch together, Audio Tracks, PiP, Ambient Glow)
          PopupMenuButton<String>(
            icon: const AuraIcon(AppIcons.moreVert, color: Colors.white),
            color: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            ),
            onSelected: (val) {
              switch (val) {
                case 'stats':
                  PlayerTrackPickers.showStatsForNerds(context: context, state: state);
                  break;
                case 'audio':
                  onShowAudioPicker();
                  break;
                case 'watch_together':
                  onWatchTogether?.call();
                  break;
                case 'pip':
                  onPictureInPicture?.call();
                  break;
                case 'glow':
                  onToggleAuraGlow?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'audio',
                child: Row(
                  children: [
                    AuraIcon(AppIcons.audiotrack, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Audio Tracks', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'watch_together',
                child: Row(
                  children: [
                    AuraIcon(AppIcons.group, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Watch Together', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'glow',
                child: Row(
                  children: [
                    AuraIcon(
                      AppIcons.autoAwesome,
                      color: state.enableAuraGlow ? AppColors.accentPink : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Ambient Backlight: ${state.enableAuraGlow ? "ON" : "OFF"}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    AuraIcon(AppIcons.info, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Stats for Nerds', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
