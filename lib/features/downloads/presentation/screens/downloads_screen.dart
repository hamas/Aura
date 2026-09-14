import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/primitives/aura_adaptive_app_bar.dart';
import '../../../../core/presentation/primitives/aura_page_scaffold.dart';
import '../../../../core/presentation/primitives/aura_section_header.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../catalog/domain/entities/media_item.dart';
import '../../domain/entities/download_task.dart';
import '../bloc/downloads_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: 70),
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
                              title: 'Downloading Now',
                              subtitle: 'Active background transfers',
                            ),
                            const SizedBox(height: AppTokens.spacingSm),
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

                          // Completed Offline Movies Section
                          if (state.completedMovies.isNotEmpty) ...[
                            const AuraSectionHeader(
                              title: 'Offline Movies',
                              subtitle: 'Ready for full offline playback',
                            ),
                            const SizedBox(height: AppTokens.spacingSm),
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

                          // Completed Offline Series Episodes Section
                          if (state.completedSeriesEpisodes.isNotEmpty) ...[
                            const AuraSectionHeader(
                              title: 'Offline Episodes',
                              subtitle: 'Saved TV show episodes',
                            ),
                            const SizedBox(height: AppTokens.spacingSm),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.completedSeriesEpisodes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final task =
                                    state.completedSeriesEpisodes[index];
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
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              title: 'Downloads',
              opacity: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
