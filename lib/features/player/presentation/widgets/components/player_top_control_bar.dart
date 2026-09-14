import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/player_state.dart';

class PlayerTopControlBar extends StatelessWidget {
  final AuraPlayerState state;
  final VoidCallback onBack;
  final VoidCallback? onWatchTogether;
  final VoidCallback? onPictureInPicture;
  final ValueChanged<BoxFit> onAspectRatioChange;
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
          IconButton(
            icon: const AuraIcon(AppIcons.arrowBackIosNew,
                color: AppColors.textPrimary),
            onPressed: onBack,
          ),
          const SizedBox(width: AppTokens.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.title ?? 'Aura Player',
                  style: context.auraText.itemTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.subtitle != null)
                  Text(
                    state.subtitle!,
                    style: context.auraText.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Watch Together Multi-User Sync Button
          IconButton(
            icon: const AuraIcon(AppIcons.group, color: AppColors.textPrimary),
            tooltip: 'Watch Together',
            onPressed: onWatchTogether,
          ),
          // Picture-in-Picture (PiP) Button
          IconButton(
            icon: const AuraIcon(AppIcons.pip, color: AppColors.textPrimary),
            tooltip: 'Picture-in-Picture',
            onPressed: () {
              if (onPictureInPicture != null) {
                onPictureInPicture!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entering Picture-in-Picture mode...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          // Aspect Ratio Toggle
          IconButton(
            icon: const AuraIcon(AppIcons.aspectRatio,
                color: AppColors.textPrimary),
            tooltip: 'Aspect Ratio',
            onPressed: () {
              final nextFit = state.fit == BoxFit.contain
                  ? BoxFit.cover
                  : state.fit == BoxFit.cover
                      ? BoxFit.fill
                      : BoxFit.contain;
              onAspectRatioChange(nextFit);
            },
          ),
          // Ambient Aura Glow Toggle Button
          IconButton(
            icon: AuraIcon(
              AppIcons.autoAwesome,
              color: state.enableAuraGlow
                  ? AppColors.accentPink
                  : AppColors.textMuted,
            ),
            tooltip: 'Ambient Aura Glow',
            onPressed: onToggleAuraGlow,
          ),
          // Subtitle Track Selector
          IconButton(
            icon: const AuraIcon(AppIcons.subtitles,
                color: AppColors.textPrimary),
            tooltip: 'Subtitles',
            onPressed: onShowSubtitlePicker,
          ),
          // Audio Track Selector
          IconButton(
            icon: const AuraIcon(AppIcons.audiotrack,
                color: AppColors.textPrimary),
            tooltip: 'Audio Tracks',
            onPressed: onShowAudioPicker,
          ),
        ],
      ),
    );
  }
}
