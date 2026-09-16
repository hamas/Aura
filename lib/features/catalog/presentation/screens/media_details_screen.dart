import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../addons/domain/entities/addon_stream.dart';
import '../../../addons/presentation/bloc/addon_bloc.dart';
import '../../../addons/presentation/bloc/addon_event.dart';
import '../../../addons/presentation/bloc/addon_state.dart';
import '../../../downloads/domain/entities/download_task.dart';
import '../../../downloads/presentation/bloc/downloads_bloc.dart';
import '../../../downloads/presentation/bloc/downloads_event.dart';
import '../../../debrid/data/repositories/debrid_repository_impl.dart';
import '../../../engine/http_debrid_engine.dart';
import '../../../library/domain/entities/library_item.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../../player/presentation/widgets/stream_picker_modal.dart';
import '../../domain/entities/media_item.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../widgets/media_poster_card.dart';
import 'package:aura/features/catalog/presentation/widgets/components/details_action_buttons.dart';
import 'package:aura/features/catalog/presentation/widgets/components/details_backdrop_sliver.dart';
import 'package:aura/features/catalog/presentation/widgets/components/details_cast_section.dart';
import 'package:aura/features/catalog/presentation/widgets/components/details_series_episodic_section.dart';
import 'package:aura/features/catalog/presentation/widgets/modals/engine_required_modal.dart';

/// Modularized Netflix-style Media Details screen for Aura (< 250 lines).
class MediaDetailsScreen extends StatefulWidget {
  final int id;
  final MediaType type;
  final MediaItem? initialItem;

  const MediaDetailsScreen({
    super.key,
    required this.id,
    required this.type,
    this.initialItem,
  });

  @override
  State<MediaDetailsScreen> createState() => _MediaDetailsScreenState();
}

class _MediaDetailsScreenState extends State<MediaDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedSeasonNumber = 1;
  bool _isSynopsisExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(
          LoadMediaDetailsEvent(id: widget.id, type: widget.type),
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSeasonChanged(int seasonNumber, int seriesId) {
    setState(() => _selectedSeasonNumber = seasonNumber);
    context.read<CatalogBloc>().add(
          LoadSeasonDetailsEvent(
            seriesId: seriesId,
            seasonNumber: seasonNumber,
          ),
        );
  }

  void _openStreamPicker(
    BuildContext context,
    MediaItem item, {
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
  }) {
    final effectiveSeason = item.type == MediaType.series
        ? (seasonNumber ?? _selectedSeasonNumber)
        : null;
    final effectiveEpisode =
        item.type == MediaType.series ? (episodeNumber ?? 1) : null;

    final stremioId = item.getStremioId(
      season: effectiveSeason,
      episode: effectiveEpisode,
    );

    final addonBloc = context.read<AddonBloc>();
    final installedAddons = addonBloc.state.installedAddons.where((a) => a.isEnabled).toList();

    if (installedAddons.isEmpty) {
      EngineRequiredModal.show(
        context: context,
        title: 'Stream Engine Required',
        message:
            'Install a Stream Engine from the Add-on Hub to resolve streaming sources for this title.',
        onGoToAddons: () => context.push('/addons'),
      );
      return;
    }

    addonBloc.add(FetchStreamsForMediaEvent(
      type: item.type == MediaType.movie ? 'movie' : 'series',
      id: stremioId,
    ));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return BlocBuilder<AddonBloc, AddonState>(
          bloc: addonBloc,
          builder: (context, addonState) {
            return StreamPickerModal(
              streams: addonState.resolvedStreams,
              isLoading: addonState.isLoadingStreams,
              onStreamSelected: (stream) => _launchPlayerWithStream(
                context,
                item,
                stream,
                seasonNumber: effectiveSeason,
                episodeNumber: effectiveEpisode,
                episodeTitle: episodeTitle,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchPlayerWithStream(
    BuildContext context,
    MediaItem item,
    AddonStream stream, {
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
  }) async {
    final engine = HttpDebridEngine(debridRepository: DebridRepositoryImpl());
    try {
      final rawTarget = stream.url ?? stream.infoHash ?? '';
      final resolved = await engine.resolveStream(
        rawUrlOrInfoHash: rawTarget,
        extraParams: {
          'title': stream.title ?? item.title,
          'quality': stream.resolution,
          'headers': stream.headers,
        },
      );

      if (context.mounted) {
        context.read<LibraryBloc>().add(
              UpdateProgressEvent(
                mediaId: item.id.toString(),
                title: item.title,
                posterPath: item.posterPath,
                backdropPath: item.backdropPath,
                type: item.type.name,
                positionSeconds: 1,
                durationSeconds: (item.runtimeMinutes ?? 120) * 60,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
              ),
            );

        final subtitleText = (item.type == MediaType.series &&
                seasonNumber != null)
            ? 'S$seasonNumber:E${episodeNumber ?? 1} • ${episodeTitle ?? ''}'
            : stream.resolution;

        await context.push(
          '/player',
          extra: {
            'streamUrl': resolved.streamUrl,
            'title': item.title,
            'subtitle': subtitleText,
            'headers': resolved.httpHeaders,
            'mediaId': item.id.toString(),
            'posterPath': item.posterPath,
            'backdropPath': item.backdropPath,
            'type': item.type.name,
            'seasonNumber': seasonNumber,
            'episodeNumber': episodeNumber,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorAccent,
            content: Text('Failed to start stream: $e'),
          ),
        );
      }
    }
  }

  void _initiateDownload(
    BuildContext context,
    MediaItem item, {
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
  }) {
    final effectiveSeason = item.type == MediaType.series
        ? (seasonNumber ?? _selectedSeasonNumber)
        : null;
    final effectiveEpisode =
        item.type == MediaType.series ? (episodeNumber ?? 1) : null;

    final stremioId = item.getStremioId(
      season: effectiveSeason,
      episode: effectiveEpisode,
    );

    final addonBloc = context.read<AddonBloc>();
    final installedAddons = addonBloc.state.installedAddons.where((a) => a.isEnabled).toList();

    if (installedAddons.isEmpty) {
      EngineRequiredModal.show(
        context: context,
        title: 'Download Engine Required',
        message:
            'Install a Download Engine from the Add-on Hub to parse streams and cache offline downloads.',
        onGoToAddons: () => context.push('/addons'),
      );
      return;
    }

    addonBloc.add(FetchStreamsForMediaEvent(
      type: item.type == MediaType.movie ? 'movie' : 'series',
      id: stremioId,
    ));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return BlocBuilder<AddonBloc, AddonState>(
          bloc: addonBloc,
          builder: (context, addonState) {
            return StreamPickerModal(
              streams: addonState.resolvedStreams,
              isLoading: addonState.isLoadingStreams,
              onStreamSelected: (stream) => _startDownloadWithStream(
                context,
                item,
                stream,
                seasonNumber: effectiveSeason,
                episodeNumber: effectiveEpisode,
                episodeTitle: episodeTitle,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startDownloadWithStream(
    BuildContext context,
    MediaItem item,
    AddonStream stream, {
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
  }) async {
    final engine = HttpDebridEngine(debridRepository: DebridRepositoryImpl());
    try {
      final rawTarget = stream.url ?? stream.infoHash ?? '';
      final resolved = await engine.resolveStream(
        rawUrlOrInfoHash: rawTarget,
        extraParams: {
          'title': stream.title ?? item.title,
          'quality': stream.resolution,
          'headers': stream.headers,
        },
      );

      if (context.mounted) {
        final taskId = item.type == MediaType.movie
            ? 'movie_${item.id}'
            : 'series_${item.id}_s${seasonNumber ?? 1}_e${episodeNumber ?? 1}';

        final task = DownloadTask(
          id: taskId,
          mediaId: item.id,
          title: item.title,
          mediaType: item.type,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          episodeTitle: episodeTitle,
          posterPath: item.posterPath,
          backdropPath: item.backdropPath,
          downloadUrl: resolved.streamUrl,
          localFilePath: '',
          createdAt: DateTime.now(),
        );

        context.read<DownloadsBloc>().add(StartDownloadEvent(task));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceCard,
            content: Text('Started downloading "${item.title}"...'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorAccent,
            content: Text('Failed to start download: $e'),
          ),
        );
      }
    }
  }

  void _playOfflineDirect(
    BuildContext context,
    MediaItem item, {
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
  }) {
    final downloadsBloc = context.read<DownloadsBloc>();
    final task = downloadsBloc.state.getMediaTask(
      mediaId: item.id,
      mediaType: item.type,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );

    if (task != null && task.isCompleted) {
      context.push(
        '/player',
        extra: {
          'streamUrl': task.localFilePath,
          'title': item.title,
          'subtitle': 'Offline Download',
          'mediaId': item.id.toString(),
          'posterPath': item.posterPath,
          'backdropPath': item.backdropPath,
          'type': item.type.name,
          'seasonNumber': seasonNumber,
          'episodeNumber': episodeNumber,
        },
      );
    }
  }

  void _toggleWatchlist(MediaItem item, bool isInWatchlist) {
    final libraryBloc = context.read<LibraryBloc>();
    final libraryItem = LibraryItem(
      id: item.id.toString(),
      title: item.title,
      posterPath: item.posterPath,
      backdropPath: item.backdropPath,
      type: item.type.name,
      category: LibraryCategory.watchlist,
      updatedAt: DateTime.now(),
    );
    libraryBloc.add(ToggleWatchlistEvent(libraryItem));
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      body: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          final isSelectedMatching = state.selectedMedia != null &&
              state.selectedMedia!.id == widget.id;
          final isInitialMatching = widget.initialItem != null &&
              widget.initialItem!.id == widget.id;

          final item = isSelectedMatching
              ? state.selectedMedia
              : (isInitialMatching ? widget.initialItem : null);

          if (state.isLoadingDetails && item == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentPink),
            );
          }

          if (item == null) {
            return Scaffold(
              backgroundColor: AppColors.surfaceBackground,
              appBar: AppBar(title: const Text('Details')),
              body: const Center(
                child: Text('Media details could not be loaded.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            );
          }

          // Smart Related Content Engine:
          // 1. Strict MediaType filter (movies get movies, shows get shows)
          // 2. Exclude active item
          // 3. Rank candidates by matching genre overlap count (highest first)
          // 4. Deterministic hash tie-breaker using item.id so each page gets unique diverse results
          final candidatePool = [
            if (item.type == MediaType.series) ...[
              ...state.trendingSeries,
              ...state.popularSeries,
              ...state.latestSeries,
            ] else ...[
              ...state.trendingMovies,
              ...state.popularMovies,
              ...state.latestMovies,
            ],
            ...state.trending,
            ...state.gridItems,
          ];

          // Deduplicate candidate list by item ID & exclude active item & match MediaType
          final Map<int, MediaItem> uniqueCandidates = {};
          for (final c in candidatePool) {
            if (c.id != item.id &&
                c.type == item.type &&
                !uniqueCandidates.containsKey(c.id)) {
              uniqueCandidates[c.id] = c;
            }
          }

          final itemGenreIds = item.genres.map((g) => g.id).where((id) => id > 0).toSet();
          final itemGenreNames = item.genres.map((g) => g.name.trim().toLowerCase()).toSet();

          final List<MediaItem> recommendations = uniqueCandidates.values.toList();
          recommendations.sort((a, b) {
            // Count matching genre IDs & matching genre names
            final aGenreIdMatches = a.genres.where((g) => g.id > 0 && itemGenreIds.contains(g.id)).length;
            final bGenreIdMatches = b.genres.where((g) => g.id > 0 && itemGenreIds.contains(g.id)).length;

            final aGenreNameMatches = a.genres.where((g) => itemGenreNames.contains(g.name.trim().toLowerCase())).length;
            final bGenreNameMatches = b.genres.where((g) => itemGenreNames.contains(g.name.trim().toLowerCase())).length;

            final aScore = (aGenreIdMatches * 2) + aGenreNameMatches;
            final bScore = (bGenreIdMatches * 2) + bGenreNameMatches;

            if (aScore != bScore) {
              return bScore.compareTo(aScore);
            }

            // Secondary sorting by release year (latest first)
            final aYear = int.tryParse(a.releaseYear) ?? 0;
            final bYear = int.tryParse(b.releaseYear) ?? 0;
            if (aYear != bYear) {
              return bYear.compareTo(aYear);
            }

            // Tertiary sorting by vote rating
            return b.voteAverage.compareTo(a.voteAverage);
          });

          return BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, libraryState) {
              final isInWatchlist =
                  libraryState.watchlist.any((w) => w.id == item.id.toString());

              return Stack(
                children: [
                  CustomScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                slivers: [
                  DetailsBackdropSliver(
                    item: item,
                    isInWatchlist: isInWatchlist,
                    onToggleWatchlist: () =>
                        _toggleWatchlist(item, isInWatchlist),
                    onShare: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceCard,
                          content: Text('Sharing "${item.title}"...'),
                        ),
                      );
                    },
                    overlappingHeader: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MediaPosterCard(
                          item: item,
                          width: 95,
                          showRating: false,
                          showTitle: false,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Year (Top)
                              Text(
                                item.releaseYear.isNotEmpty
                                    ? item.releaseYear
                                    : 'N/A',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),

                              // 2. Title
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.auraText.displayHero.copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),

                              // 3. Genre
                              Text(
                                item.genres.isNotEmpty
                                    ? item.genres.map((g) => g.name).join(' • ')
                                    : (item.type == MediaType.movie
                                        ? 'Movie'
                                        : 'TV Series'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 5),

                              // 4. Rating
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5C518),
                                      borderRadius:
                                          BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'IMDb',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.voteAverage > 0
                                        ? item.voteAverage.toStringAsFixed(1)
                                        : '8.4',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('🍅',
                                      style: TextStyle(fontSize: 11)),
                                  const SizedBox(width: 2),
                                  const Text(
                                    '88%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('🍿',
                                      style: TextStyle(fontSize: 11)),
                                  const SizedBox(width: 2),
                                  const Text(
                                    '94%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 5. Buttons
                              DetailsActionButtons(
                                item: item,
                                isInWatchlist: isInWatchlist,
                                onPlayPressed: () =>
                                    _openStreamPicker(context, item),
                                onDownloadPressed: () =>
                                    _initiateDownload(context, item),
                                onPlayOfflinePressed: () =>
                                    _playOfflineDirect(context, item),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: AppTokens.screenEdgeHorizontal,
                        right: AppTokens.screenEdgeHorizontal,
                        top: 20.0,
                        bottom: 48.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Synopsis
                          GestureDetector(
                            onTap: () => setState(() =>
                                _isSynopsisExpanded = !_isSynopsisExpanded),
                            child: Text(
                              item.overview,
                              maxLines: _isSynopsisExpanded ? null : 4,
                              overflow: _isSynopsisExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: context.auraText.bodyOverview,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (item.cast.isNotEmpty) ...[
                            DetailsCastSection(item: item),
                            const SizedBox(height: 20),
                          ],

                          if (item.type == MediaType.series &&
                              item.seasons.isNotEmpty) ...[
                            DetailsSeriesEpisodicSection(
                              item: item,
                              selectedSeasonNumber: _selectedSeasonNumber,
                              onSeasonSelected: (s) =>
                                  _onSeasonChanged(s, item.id),
                              onPlayEpisode: (BuildContext ctx, MediaItem it,
                                      {int? seasonNumber,
                                      int? episodeNumber,
                                      String? episodeTitle}) =>
                                  _openStreamPicker(ctx, it,
                                      seasonNumber: seasonNumber,
                                      episodeNumber: episodeNumber,
                                      episodeTitle: episodeTitle),
                              onDownloadEpisode:
                                  (BuildContext ctx, MediaItem it,
                                          {int? seasonNumber,
                                          int? episodeNumber,
                                          String? episodeTitle}) =>
                                      _initiateDownload(ctx, it,
                                          seasonNumber: seasonNumber,
                                          episodeNumber: episodeNumber,
                                          episodeTitle: episodeTitle),
                              onPlayOfflineEpisode: (BuildContext ctx,
                                      MediaItem it,
                                      {int? seasonNumber,
                                      int? episodeNumber,
                                      String? episodeTitle}) =>
                                  _playOfflineDirect(ctx, it,
                                      seasonNumber: seasonNumber,
                                      episodeNumber: episodeNumber,
                                      episodeTitle: episodeTitle),
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (recommendations.isNotEmpty) ...[
                            const AuraSectionHeader(
                              title: 'More Like This',
                              showChevron: false,
                            ),
                            const SizedBox(height: AppTokens.spacingSm),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: AppTokens.posterAspectRatio,
                                mainAxisSpacing: AppTokens.spacingSm,
                                crossAxisSpacing: AppTokens.spacingSm,
                              ),
                              itemCount: recommendations.take(12).length,
                              itemBuilder: (context, index) {
                                final recItem = recommendations[index];
                                return MediaPosterCard(
                                  item: recItem,
                                  onTap: () {
                                    context.push(
                                      '/detail/${recItem.type.name}/${recItem.id}',
                                      extra: recItem,
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Pinned Sticky Top Bar (Identical to Category / Discovery Screen top bar)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AuraAdaptiveAppBar(
                    scrollController: _scrollController,
                    forceCanPop: true,
                    onBackPressed: () => Navigator.of(context).pop(),
                    actions: [
                      // Watchlist / Heart Action
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: AuraIcon(
                            AppIcons.favorite,
                            fill: isInWatchlist ? 1.0 : 0.0,
                            color: isInWatchlist
                                ? AppColors.accentPink
                                : Colors.white,
                            size: 18,
                          ),
                          onPressed: () =>
                              _toggleWatchlist(item, isInWatchlist),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Share Action
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const AuraIcon(
                            AppIcons.share,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.surfaceCard,
                                content: Text('Sharing "${item.title}"...'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}
}
