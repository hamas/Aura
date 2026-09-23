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
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLarge)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
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
                      'Primary Subtitles',
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
                        ? const AuraIcon(AppIcons.check, color: AppColors.accentPink)
                        : null,
                    onTap: () {
                      onSelectSubtitleTrack(null);
                      setModalState(() {});
                    },
                  ),
                  ...state.subtitleTracks.map((s) {
                    final isSelected = state.selectedSubtitleTrack?.id == s.id;
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.title ?? s.language ?? 'Track ${s.id}',
                              style: context.auraText.bodyOverview
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                          if (s.isExternal) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentPink.withAlpha(40),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.accentPink,
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'EXT ADD-ON',
                                style: TextStyle(
                                  color: AppColors.accentPink,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: isSelected
                          ? const AuraIcon(AppIcons.check, color: AppColors.accentPink)
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
                        ? const AuraIcon(AppIcons.check, color: AppColors.accentPink)
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
                          ? const AuraIcon(AppIcons.check, color: AppColors.accentPink)
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
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLarge)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppTokens.spacingSm),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
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
                final rawName = a.title ?? a.language ?? 'Audio Track ${a.id}';
                final langLabel = (a.language != null && a.language!.isNotEmpty)
                    ? a.language!.toUpperCase()
                    : 'UND';

                return ListTile(
                  title: Row(
                    children: [
                      Text(
                        rawName,
                        style: context.auraText.bodyOverview
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          langLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: isSelected
                      ? const AuraIcon(AppIcons.check, color: AppColors.accentPink)
                      : null,
                  onTap: () {
                    onSelectAudioTrack(a);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  static void showPlaybackSpeedPicker({
    required BuildContext context,
    required double currentSpeed,
    required ValueChanged<double> onSelectSpeed,
  }) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLarge)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppTokens.spacingSm),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTokens.spacingMd),
                child: Text(
                  'Playback Speed',
                  style: context.auraText.itemTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ...speeds.map((speed) {
                final isSelected = (currentSpeed - speed).abs() < 0.01;
                final label = speed == 1.0 ? 'Normal (1.0x)' : '${speed}x';
                return ListTile(
                  title: Text(
                    label,
                    style: context.auraText.bodyOverview.copyWith(
                      color: isSelected ? AppColors.accentPink : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const AuraIcon(AppIcons.check, color: AppColors.accentPink)
                      : null,
                  onTap: () {
                    onSelectSpeed(speed);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  static void showStatsForNerds({
    required BuildContext context,
    required AuraPlayerState state,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          ),
          title: Text(
            'Stats for Nerds',
            style: context.auraText.itemTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatRow(context, 'Title', state.title ?? 'N/A'),
                _buildStatRow(context, 'Engine', 'Direct HTTP Debrid Engine'),
                _buildStatRow(context, 'Status', state.status.name.toUpperCase()),
                _buildStatRow(context, 'Speed', '${state.rate}x'),
                _buildStatRow(context, 'Volume', '${state.volume.toInt()}%'),
                _buildStatRow(context, 'Aspect Ratio', state.fit.name),
                _buildStatRow(context, 'Hardware Accel', 'Active (libmpv / Impeller)'),
                _buildStatRow(
                  context,
                  'Audio Track',
                  state.selectedAudioTrack?.title ??
                      state.selectedAudioTrack?.language ??
                      'Default',
                ),
                _buildStatRow(
                  context,
                  'Subtitles',
                  state.selectedSubtitleTrack?.title ??
                      state.selectedSubtitleTrack?.language ??
                      'None',
                ),
                _buildStatRow(
                  context,
                  'Stream URL',
                  state.currentStreamUrl ?? 'N/A',
                  isUrl: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.accentPink)),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildStatRow(BuildContext context, String key, String value,
      {bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: context.auraText.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.auraText.bodyOverview.copyWith(
              color: AppColors.textPrimary,
              fontSize: isUrl ? 11 : 13,
            ),
            maxLines: isUrl ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
