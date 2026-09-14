import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/presentation/primitives/aura_badge.dart';
import '../../../../core/presentation/primitives/aura_card.dart';
import '../../../../core/presentation/primitives/aura_page_scaffold.dart';
import '../../../../core/presentation/primitives/aura_section_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../catalog/domain/entities/media_item.dart';
import '../../domain/entities/download_task.dart';
import '../bloc/downloads_bloc.dart';
import '../bloc/downloads_event.dart';
import '../bloc/downloads_state.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  void _playOffline(BuildContext context, DownloadTask task) {
    context.push(
      '/player',
      extra: {
        'streamUrl': task.localFilePath,
        'title': task.title,
        'subtitle': task.mediaType == MediaType.series &&
                task.seasonNumber != null &&
                task.episodeNumber != null
            ? (task.episodeTitle != null && task.episodeTitle!.isNotEmpty
                ? 'S${task.seasonNumber}:E${task.episodeNumber} • ${task.episodeTitle}'
                : 'Season ${task.seasonNumber} Episode ${task.episodeNumber}')
            : 'Offline Download',
        'mediaId': task.mediaId.toString(),
        'posterPath': task.posterPath,
        'backdropPath': task.backdropPath,
        'type': task.mediaType.name,
        'seasonNumber': task.seasonNumber,
        'episodeNumber': task.episodeNumber,
      },
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text(
          'Delete All Downloads?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will permanently delete all downloaded offline movies and episodes from this device.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<DownloadsBloc>().add(ClearAllDownloadsEvent());
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Top App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surfaceBackground,
            title: const Text(
              'Downloads',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            actions: [
              BlocBuilder<DownloadsBloc, DownloadsState>(
                builder: (context, state) {
                  if (state.tasks.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Clear All Downloads',
                    onPressed: () => _confirmClearAll(context),
                  );
                },
              ),
            ],
          ),

          // 2. Storage Header Banner & Main Body
          SliverToBoxAdapter(
            child: BlocBuilder<DownloadsBloc, DownloadsState>(
              builder: (context, state) {
                if (state.tasks.isEmpty) {
                  return _buildEmptyState(context);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Storage Consumption Card
                      _buildStorageBar(context, state),
                      const SizedBox(height: 20),

                      // In-Progress / Active Queue Section
                      if (state.activeTasks.isNotEmpty) ...[
                        const AuraSectionHeader(
                          title: 'Downloading',
                          padding: EdgeInsets.zero,
                          showChevron: false,
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.activeTasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = state.activeTasks[index];
                            return _buildActiveDownloadCard(context, task);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Completed Movies Section
                      if (state.completedMovies.isNotEmpty) ...[
                        const AuraSectionHeader(
                          title: 'Movies',
                          padding: EdgeInsets.zero,
                          showChevron: false,
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.completedMovies.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = state.completedMovies[index];
                            return _buildCompletedItemCard(context, task);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Completed Series Episodes Section
                      if (state.completedSeriesEpisodes.isNotEmpty) ...[
                        const AuraSectionHeader(
                          title: 'TV Shows',
                          padding: EdgeInsets.zero,
                          showChevron: false,
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.completedSeriesEpisodes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = state.completedSeriesEpisodes[index];
                            return _buildCompletedItemCard(context, task);
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 80.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x24FFFFFF)),
              ),
              child: const Icon(
                Icons.download_for_offline_outlined,
                size: 56,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Offline Downloads',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Download movies and episodes to watch seamlessly without an internet connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageBar(BuildContext context, DownloadsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppTokens.borderRadiusSmall,
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_special_rounded,
            color: AppColors.accentPink,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Private Vault Storage',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.completedTasks.length} offline titles • ${state.formattedTotalStorage}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const AuraBadge(
            label: 'SANDBOXED',
            backgroundColor: Color(0x1EB877FF),
            borderColor: AppColors.accentPink,
            textColor: AppColors.accentPink,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDownloadCard(BuildContext context, DownloadTask task) {
    final percentage = task.progressPercentage;

    return AuraCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Poster / Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
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
                  style: AppTypography.itemTitle.copyWith(fontSize: 14),
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
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                ],
                const SizedBox(height: 8),

                // Linear Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: const Color(0x33FFFFFF),
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
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (task.formattedSpeed.isNotEmpty)
                      Text(
                        task.formattedSpeed,
                        style: const TextStyle(
                          color: AppColors.accentPink,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (task.isPaused)
                      const Text(
                        'Paused',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
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
                icon: Icon(
                  task.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
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
                icon: const Icon(
                  Icons.close_rounded,
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

  Widget _buildCompletedItemCard(BuildContext context, DownloadTask task) {
    return Dismissible(
      key: Key('download_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: const BoxDecoration(
          color: AppColors.errorAccent,
          borderRadius: AppTokens.borderRadiusSmall,
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<DownloadsBloc>().add(DeleteDownloadEvent(task.id));
      },
      child: AuraCard(
        padding: const EdgeInsets.all(10),
        onTap: () => _playOffline(context, task),
        child: Row(
          children: [
            // Poster / Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
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
                    style: AppTypography.itemTitle.copyWith(fontSize: 14),
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
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      const Icon(
                        Icons.offline_pin_rounded,
                        size: 13,
                        color: AppColors.accentPink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.formattedTotalSize,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Play Button
            IconButton(
              icon: const Icon(
                Icons.play_circle_filled_rounded,
                color: AppColors.accentPink,
                size: 32,
              ),
              onPressed: () => _playOffline(context, task),
            ),
          ],
        ),
      ),
    );
  }
}
