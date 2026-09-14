import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/presentation/primitives/aura_adaptive_app_bar.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../core/presentation/primitives/aura_section_header.dart';
import '../../../catalog/domain/entities/media_item.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../domain/entities/download_task.dart';
import '../bloc/downloads_bloc.dart';
import '../bloc/downloads_event.dart';
import '../bloc/downloads_state.dart';
import '../widgets/components/download_task_cards.dart';
import '../widgets/components/downloads_storage_banner.dart';

class DownloadsScreen extends StatefulWidget {
  final int initialTabIndex;

  const DownloadsScreen({
    super.key,
    this.initialTabIndex = 1, // Default to Downloads tab
  });

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    context.read<LibraryBloc>().add(LoadLibraryEvent());
    context.read<DownloadsBloc>().add(LoadDownloadsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 4;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.accentPink,
                  labelColor: AppColors.accentPink,
                  unselectedLabelColor: AppColors.textMuted,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'Wishlist'),
                    Tab(text: 'Downloads'),
                    Tab(text: 'Watchlist'),
                    Tab(text: 'Continue Watching'),
                    Tab(text: 'History'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWishlistTab(context),
                      _buildDownloadsTab(context),
                      _buildWatchlistTab(context),
                      _buildContinueWatchingTab(context),
                      _buildHistoryTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              title: 'My Library & Downloads',
              opacity: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Wishlist Tab ---
  Widget _buildWishlistTab(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        final items = state.wishlist;
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AuraIcon(AppIcons.bookmark,
                    color: AppColors.textMuted, size: 48),
                SizedBox(height: 12),
                Text(
                  'Your wishlist is empty.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Save movies and shows you want to watch later.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () => context.push('/detail/${item.type}/${item.id}'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: AppTheme.surfaceCard,
                  child: item.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl:
                              '${ApiConstants.tmdbPosterW500}${item.posterPath}',
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: AuraIcon(AppIcons.movie,
                              color: AppTheme.textMuted)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 2. Downloads Tab ---
  Widget _buildDownloadsTab(BuildContext context) {
    return BlocBuilder<DownloadsBloc, DownloadsState>(
      builder: (context, state) {
        if (state.tasks.isEmpty) {
          return const DownloadsEmptyState();
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingMd,
                  vertical: AppTokens.spacingSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Storage Banner
                    DownloadsStorageBanner(state: state),
                    const SizedBox(height: AppTokens.spacingLg),

                    if (state.tasks.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'OFFLINE VAULT',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surfaceCard,
                                  title: const Text('Delete All Downloads?',
                                      style: TextStyle(
                                          color: AppColors.textPrimary)),
                                  content: const Text(
                                    'This will permanently delete all downloaded movies and episodes from your sandboxed vault.',
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancel',
                                          style: TextStyle(
                                              color: AppColors.textMuted)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context
                                            .read<DownloadsBloc>()
                                            .add(ClearAllDownloadsEvent());
                                        Navigator.of(ctx).pop();
                                      },
                                      child: const Text('Delete All',
                                          style: TextStyle(
                                              color: AppColors.statusError)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text(
                              'Delete All',
                              style: TextStyle(
                                color: AppColors.statusError,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spacingSm),
                    ],

                    // Active Downloads
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
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final task = state.activeTasks[index];
                          return ActiveDownloadTaskCard(task: task);
                        },
                      ),
                      const SizedBox(height: AppTokens.spacingLg),
                    ],

                    // Offline Movies
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
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
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

                    // Offline Episodes
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
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
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
              ),
            ),
          ],
        );
      },
    );
  }

  // --- 3. Watchlist Tab ---
  Widget _buildWatchlistTab(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        final items = state.watchlist;
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AuraIcon(AppIcons.bookmark,
                    color: AppColors.textMuted, size: 48),
                SizedBox(height: 12),
                Text(
                  'Your watchlist is empty.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () => context.push('/detail/${item.type}/${item.id}'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: AppTheme.surfaceCard,
                  child: item.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl:
                              '${ApiConstants.tmdbPosterW500}${item.posterPath}',
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: AuraIcon(AppIcons.movie,
                              color: AppTheme.textMuted)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 4. Continue Watching Tab ---
  Widget _buildContinueWatchingTab(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        final items = state.continueWatching;
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No in-progress media.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            final progress = item.progress;
            final percentage = progress?.percentage ?? 0.0;

            return GestureDetector(
              onTap: () => context.push('/detail/${item.type}/${item.id}'),
              child: Card(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12)),
                      child: SizedBox(
                        width: 110,
                        height: 90,
                        child: item.backdropPath != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    '${ApiConstants.tmdbBackdropW1280}${item.backdropPath}',
                                fit: BoxFit.cover,
                              )
                            : Container(color: AppTheme.surfaceElevated),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (progress?.seasonNumber != null &&
                                progress?.episodeNumber != null)
                              Text(
                                'S${progress!.seasonNumber} E${progress.episodeNumber}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 4,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const AuraIcon(AppIcons.playCircle,
                          color: AppTheme.primaryAccent, size: 32),
                      onPressed: () =>
                          context.push('/detail/${item.type}/${item.id}'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 5. History Tab ---
  Widget _buildHistoryTab(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        final items = state.history;
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No watch history yet.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(color: Color(0xFF1F293D)),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              onTap: () => context.push('/detail/${item.type}/${item.id}'),
              title: Text(item.title,
                  style: const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(
                item.type.toUpperCase(),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const AuraIcon(AppIcons.close,
                    color: AppTheme.textMuted, size: 18),
                onPressed: () {
                  context
                      .read<LibraryBloc>()
                      .add(RemoveLibraryItemEvent(item.id));
                },
              ),
            );
          },
        );
      },
    );
  }
}
