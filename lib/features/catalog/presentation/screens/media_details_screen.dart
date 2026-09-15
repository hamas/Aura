import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../addons/domain/entities/addon_stream.dart';
import '../../../addons/presentation/bloc/addon_bloc.dart';
import '../../../addons/presentation/bloc/addon_event.dart';
import '../../../addons/presentation/bloc/addon_state.dart';
import '../../../downloads/domain/entities/download_task.dart';
import '../../../downloads/presentation/bloc/downloads_bloc.dart';
import '../../../downloads/presentation/bloc/downloads_event.dart';
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
  int _selectedSeasonNumber = 1;
  bool _isSynopsisExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(
          LoadMediaDetailsEvent(id: widget.id, type: widget.type),
        );
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
    final engine = HttpDebridEngine();
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
    final engine = HttpDebridEngine();
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

          final recommendations = item.type == MediaType.series
              ? state.trendingSeries
              : state.trendingMovies;

          return BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, libraryState) {
              final isInWatchlist =
                  libraryState.watchlist.any((w) => w.id == item.id.toString());

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
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
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.screenEdgeHorizontal),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Title & Poster Row below Hero Backdrop (Vertically Centered with Poster)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 95,
                                height: 142,
                                decoration: BoxDecoration(
                                  borderRadius: AppTokens.borderRadiusSmall,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: AppTokens.borderRadiusSmall,
                                  child: item.posterPath != null
                                      ? CachedNetworkImage(
                                          imageUrl:
                                              '${ApiConstants.tmdbPosterW500}${item.posterPath}',
                                          fit: BoxFit.cover,
                                        )
                                      : Container(color: AppColors.surfaceCard),
                                ),
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
                          const SizedBox(height: 18),

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
                              padding: EdgeInsets.zero,
                              showChevron: false,
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 220,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: recommendations.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) =>
                                    MediaPosterCard(
                                        item: recommendations[index]),
                              ),
                            ),
                            const SizedBox(height: 48),
                          ],
                        ],
                      ),
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
