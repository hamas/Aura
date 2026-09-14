import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/player_state.dart';
import '../../../domain/entities/stream_track.dart';
import '../../subtitles/widgets/subtitle_sync_hud.dart';



class PlayerTrackPickers {
  static void showSubtitlePicker({
    required BuildContext context,
    required AuraPlayerState state,
    required ValueChanged<SubtitleTrackInfo?> onSelectSubtitleTrack,
    ValueChanged<SubtitleTrackInfo?>? onSelectSecondarySubtitleTrack,
    ValueChanged<double>? onSubtitleOffsetChanged,
    ValueChanged<double>? onNudgeSubtitleOffset,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Subtitle Sync Offset HUD
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingMd,
                      vertical: AppTokens.spacingSm,
                    ),
                    child: SubtitleSyncHud(
                      currentOffset: state.subtitleOffset,
                      onOffsetChanged: (val) {
                        onSubtitleOffsetChanged?.call(val);
                        setModalState(() {});
                      },
                      onNudgeOffset: (delta) {
                        onNudgeSubtitleOffset?.call(delta);
                        setModalState(() {});
                      },
                      onReset: () {
                        onSubtitleOffsetChanged?.call(0.0);
                        setModalState(() {});
                      },
                    ),
                  ),
                  const Divider(color: AppColors.borderSubtle),

                  // Primary Subtitle Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingMd,
                      vertical: AppTokens.spacingSm,
                    ),
                    child: Text(
                      'Primary Subtitle (Bottom)',
                      style: context.auraText.itemTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Off',
                      style: context.auraText.bodyOverview
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    trailing: state.selectedSubtitleTrack == null
                        ? const AuraIcon(AppIcons.check,
                            color: AppColors.accentPink)
                        : null,
                    onTap: () {
                      onSelectSubtitleTrack(null);
                      setModalState(() {});
                    },
                  ),
                  ...state.subtitleTracks.map((s) {
                    final isSelected = state.selectedSubtitleTrack?.id == s.id;
                    return ListTile(
                      title: Text(
                        s.title ?? s.language ?? 'Track ${s.id}',
                        style: context.auraText.bodyOverview
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      trailing: isSelected
                          ? const AuraIcon(AppIcons.check,
                              color: AppColors.accentPink)
                          : null,
                      onTap: () {
                        onSelectSubtitleTrack(s);
                        setModalState(() {});
                      },
                    );
                  }),

                  const Divider(color: AppColors.borderSubtle),

                  // Secondary Subtitle Selector (Dual Track)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingMd,
                      vertical: AppTokens.spacingSm,
                    ),
                    child: Text(
                      'Secondary Subtitle (Top Accent)',
                      style: context.auraText.itemTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentPink,
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'None',
                      style: context.auraText.bodyOverview
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    trailing: state.selectedSecondarySubtitleTrack == null
                        ? const AuraIcon(AppIcons.check,
                            color: AppColors.accentPink)
                        : null,
                    onTap: () {
                      onSelectSecondarySubtitleTrack?.call(null);
                      setModalState(() {});
                    },
                  ),
                  ...state.subtitleTracks.map((s) {
                    final isSelected =
                        state.selectedSecondarySubtitleTrack?.id == s.id;
                    return ListTile(
                      title: Text(
                        s.title ?? s.language ?? 'Track ${s.id}',
                        style: context.auraText.bodyOverview
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      trailing: isSelected
                          ? const AuraIcon(AppIcons.check,
                              color: AppColors.accentPink)
                          : null,
                      onTap: () {
                        onSelectSecondarySubtitleTrack?.call(s);
                        setModalState(() {});
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showAudioPicker({
    required BuildContext context,
    required AuraPlayerState state,
    required ValueChanged<AudioTrackInfo> onSelectAudioTrack,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTokens.spacingMd),
              child: Text(
                'Audio Tracks',
                style: context.auraText.itemTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ...state.audioTracks.map((a) {
              final isSelected = state.selectedAudioTrack?.id == a.id;
              return ListTile(
                title: Text(
                  a.title ?? a.language ?? 'Audio Track ${a.id}',
                  style: context.auraText.bodyOverview
                      .copyWith(color: AppColors.textPrimary),
                ),
                trailing: isSelected
                    ? const AuraIcon(AppIcons.check,
                        color: AppColors.accentPink)
                    : null,
                onTap: () {
                  onSelectAudioTrack(a);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }
}
