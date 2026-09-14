import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../core/presentation/primitives/aura_page_scaffold.dart';
import '../../../../core/presentation/primitives/aura_section_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../catalog/domain/entities/media_item.dart';
import '../../domain/entities/download_task.dart';
import '../bloc/downloads_bloc.dart';
import '../bloc/downloads_event.dart';
import '../bloc/downloads_state.dart';
import '../widgets/components/download_task_cards.dart';
import '../widgets/components/downloads_storage_banner.dart';

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
        title: Text(
          'Delete All Downloads?',
          style:
              context.auraText.itemTitle.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will permanently delete all downloaded offline movies and episodes from this device.',
          style: context.auraText.bodyOverview
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: context.auraText.caption
                    .copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: AppColors.textPrimary,
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
            title: Text(
              'Downloads',
              style: context.auraText.sectionTitle.copyWith(
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
                    icon: const AuraIcon(
                      AppIcons.deleteSweep,
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
                  return const DownloadsEmptyState();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingMd,
                    vertical: AppTokens.spacingSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Storage Consumption & Smart Downloads Banner
                      DownloadsStorageBanner(state: state),
                      const SizedBox(height: AppTokens.spacingLg),

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
                            return ActiveDownloadTaskCard(task: task);
                          },
                        ),
                        const SizedBox(height: AppTokens.spacingLg),
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
                            return CompletedDownloadTaskCard(
                              task: task,
                              onPlay: () => _playOffline(context, task),
                            );
                          },
                        ),
                        const SizedBox(height: AppTokens.spacingLg),
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
                            return CompletedDownloadTaskCard(
                              task: task,
                              onPlay: () => _playOffline(context, task),
                            );
                          },
                        ),
                        const SizedBox(height: AppTokens.spacingXl),
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
}
