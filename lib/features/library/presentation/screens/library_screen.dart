import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../domain/entities/library_item.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/library_state.dart';

import 'package:aura/features/downloads/presentation/screens/downloads_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<LibraryBloc>().add(LoadLibraryEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Library'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryAccent,
          labelColor: AppTheme.primaryAccent,
          unselectedLabelColor: AppTheme.textMuted,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Continue Watching'),
            Tab(text: 'Watchlist'),
            Tab(text: 'Downloads'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state.status == LibraryStatus.loading &&
              state.watchlist.isEmpty &&
              state.continueWatching.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildContinueWatchingList(context, state.continueWatching),
              _buildWatchlistGrid(context, state.watchlist),
              const DownloadsScreen(),
              _buildHistoryList(context, state.history),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContinueWatchingList(
      BuildContext context, List<LibraryItem> items) {
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
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(12)),
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
                                color: AppTheme.textSecondary, fontSize: 12),
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
  }

  Widget _buildWatchlistGrid(BuildContext context, List<LibraryItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Your watchlist is empty.',
          style: TextStyle(color: AppTheme.textMuted),
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
                      child:
                          AuraIcon(AppIcons.movie, color: AppTheme.textMuted)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(BuildContext context, List<LibraryItem> items) {
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
              context.read<LibraryBloc>().add(RemoveLibraryItemEvent(item.id));
            },
          ),
        );
      },
    );
  }
}
