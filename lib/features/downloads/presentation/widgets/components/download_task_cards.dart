import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/presentation/primitives/aura_badge.dart';
import '../../../../../core/presentation/primitives/aura_card.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../catalog/domain/entities/media_item.dart';
import '../../../domain/entities/download_task.dart';
import '../../bloc/downloads_bloc.dart';
import '../../bloc/downloads_event.dart';

class ActiveDownloadTaskCard extends StatelessWidget {
  final DownloadTask task;

  const ActiveDownloadTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final percentage = task.progressPercentage;

    return AuraCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Poster / Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            child: SizedBox(
              width: 50,
              height: 70,
              child: task.posterPath != null
                  ? CachedNetworkImage(
                      imageUrl:
                          '${ApiConstants.tmdbPosterW500}${task.posterPath}',
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceElevated),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.surfaceElevated),
                    )
                  : Container(color: AppColors.surfaceElevated),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: context.auraText.itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.mediaType == MediaType.series &&
                    task.seasonNumber != null &&
                    task.episodeNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.episodeTitle != null && task.episodeTitle!.isNotEmpty
                        ? 'S${task.seasonNumber}:E${task.episodeNumber} • ${task.episodeTitle}'
                        : 'Season ${task.seasonNumber} Episode ${task.episodeNumber}',
                    style: context.auraText.caption,
                  ),
                ],
                const SizedBox(height: 8),

                // Linear Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.borderSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentPink),
                  ),
                ),
                const SizedBox(height: 6),

                // Stats: size & speed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task.formattedSize,
                      style: context.auraText.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                    if (task.formattedSpeed.isNotEmpty)
                      Text(
                        task.formattedSpeed,
                        style: context.auraText.caption.copyWith(
                          color: AppColors.accentPink,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (task.isPaused)
                      Text(
                        'Paused',
                        style: context.auraText.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Pause / Resume / Cancel Controls
          Column(
            children: [
              IconButton(
                iconSize: 24,
                icon: AuraIcon(
                  task.isPaused ? AppIcons.play : AppIcons.pause,
                  color: AppColors.accentPink,
                ),
                onPressed: () {
                  if (task.isPaused) {
                    context
                        .read<DownloadsBloc>()
                        .add(ResumeDownloadEvent(task.id));
                  } else {
                    context
                        .read<DownloadsBloc>()
                        .add(PauseDownloadEvent(task.id));
                  }
                },
              ),
              IconButton(
                iconSize: 20,
                icon: const AuraIcon(
                  AppIcons.close,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  context
                      .read<DownloadsBloc>()
                      .add(CancelDownloadEvent(task.id));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompletedDownloadTaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onPlay;

  const CompletedDownloadTaskCard({
    super.key,
    required this.task,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('download_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.statusError,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
        child: const AuraIcon(AppIcons.delete, color: AppColors.textPrimary),
      ),
      onDismissed: (_) {
        context.read<DownloadsBloc>().add(DeleteDownloadEvent(task.id));
      },
      child: AuraCard(
        padding: const EdgeInsets.all(10),
        onTap: onPlay,
        child: Row(
          children: [
            // Poster / Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              child: SizedBox(
                width: 52,
                height: 74,
                child: task.posterPath != null
                    ? CachedNetworkImage(
                        imageUrl:
                            '${ApiConstants.tmdbPosterW500}${task.posterPath}',
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.surfaceElevated),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.surfaceElevated),
                      )
                    : Container(color: AppColors.surfaceElevated),
              ),
            ),
            const SizedBox(width: 14),

            // Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: context.auraText.itemTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (task.mediaType == MediaType.series &&
                      task.seasonNumber != null &&
                      task.episodeNumber != null) ...[
                    Text(
                      task.episodeTitle != null && task.episodeTitle!.isNotEmpty
                          ? 'S${task.seasonNumber}:E${task.episodeNumber} • ${task.episodeTitle}'
                          : 'Season ${task.seasonNumber} Episode ${task.episodeNumber}',
                      style: context.auraText.caption,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      const AuraIcon(
                        AppIcons.offlinePin,
                        size: 13,
                        color: AppColors.accentPink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.formattedTotalSize,
                        style: context.auraText.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                      if (task.mediaType == MediaType.series) ...[
                        const SizedBox(width: 8),
                        const AuraBadge(
                          label: 'SMART DOWNLOADS ACTIVE',
                          backgroundColor: Color(0x1EB877FF),
                          borderColor: AppColors.accentPink,
                          textColor: AppColors.accentPink,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Play Button
            IconButton(
              icon: const AuraIcon(
                AppIcons.playCircle,
                color: AppColors.accentPink,
                size: 32,
              ),
              onPressed: onPlay,
            ),
          ],
        ),
      ),
    );
  }
}
