import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../downloads/presentation/widgets/download_action_button.dart';
import '../../../engine/http_debrid_engine.dart';
import '../../../library/domain/entities/library_item.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../../player/presentation/widgets/stream_picker_modal.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/season_episode.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../widgets/media_poster_card.dart';

/// Netflix-style cinematic Media Details / Single screen for Aura.
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
    setState(() {
      _selectedSeasonNumber = seasonNumber;
    });
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
        // Record continue watching entry
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

        String subtitleText;
        if (item.type == MediaType.series &&
            seasonNumber != null &&
            episodeNumber != null) {
          subtitleText = episodeTitle != null && episodeTitle.isNotEmpty
              ? 'S$seasonNumber:E$episodeNumber • $episodeTitle'
              : 'Season $seasonNumber Episode $episodeNumber';
        } else {
          subtitleText = stream.resolution;
        }

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
          localFilePath: '', // Generated sandboxed path by repository
          createdAt: DateTime.now(),
        );

        context.read<DownloadsBloc>().add(StartDownloadEvent(task));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              item.type == MediaType.series && episodeNumber != null
                  ? 'Started downloading Episode $episodeNumber...'
                  : 'Started downloading "${item.title}"...',
            ),
            duration: const Duration(seconds: 2),
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
          'subtitle': item.type == MediaType.series &&
                  seasonNumber != null &&
                  episodeNumber != null
              ? (episodeTitle != null && episodeTitle.isNotEmpty
                  ? 'S$seasonNumber:E$episodeNumber • $episodeTitle'
                  : 'Season $seasonNumber Episode $episodeNumber')
              : 'Offline Download',
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

  void _launchTrailer(String? trailerUrl) {
    if (trailerUrl == null || trailerUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text('No trailer is available for this title.'),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text(
          'Trailer Available',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Trailer link: $trailerUrl',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close',
                style: TextStyle(color: AppColors.accentPink)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      body: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          final item = state.selectedMedia ?? widget.initialItem;

          if (item == null && state.isLoadingDetails) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentPink),
            );
          }

          if (item == null) {
            return Scaffold(
              backgroundColor: AppColors.surfaceBackground,
              appBar: AppBar(title: const Text('Details')),
              body: const Center(
                child: Text(
                  'Media details could not be loaded.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
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
                  // 1. Backdrop Hero Sliver
                  _buildBackdropSliver(context, item, isInWatchlist),

                  // 2. Main Content Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),

                          // Title & Metadata Badges
                          _buildTitleAndBadges(item),
                          const SizedBox(height: 14),

                          // Primary Action Buttons
                          _buildActionButtons(context, item, isInWatchlist),
                          const SizedBox(height: 18),

                          // Synopsis Section
                          _buildSynopsis(item),
                          const SizedBox(height: 20),

                          // Cast & Crew Section
                          if (item.cast.isNotEmpty) ...[
                            _buildCastSection(item),
                            const SizedBox(height: 20),
                          ],

                          // TV Series Season & Episode Breakdown
                          if (item.type == MediaType.series &&
                              item.seasons.isNotEmpty) ...[
                            _buildSeriesEpisodicSection(context, item, state),
                            const SizedBox(height: 20),
                          ],

                          // Recommendations / "More Like This"
                          if (recommendations.isNotEmpty) ...[
                            _buildRecommendationsSection(recommendations),
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

  Widget _buildBackdropSliver(
    BuildContext context,
    MediaItem item,
    bool isInWatchlist,
  ) {
    final backdropHeight = MediaQuery.of(context).size.height * 0.42;

    return SliverAppBar(
      expandedHeight: backdropHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.surfaceBackground,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.65 * 255).round()),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const AuraIcon(
            AppIcons.back,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((0.65 * 255).round()),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: AuraIcon(
              isInWatchlist ? AppIcons.bookmarkAdded : AppIcons.bookmarkAdd,
              color: isInWatchlist ? AppColors.accentPink : Colors.white,
              fill: isInWatchlist ? 1.0 : 0.0,
              size: 20,
            ),
            onPressed: () => _toggleWatchlist(item, isInWatchlist),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop Image
            item.backdropPath != null
                ? CachedNetworkImage(
                    imageUrl: item.fullBackdropUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surfaceBackground),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceBackground),
                  )
                : Container(color: AppColors.surfaceBackground),

            // Top Status Bar Vignette
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.heroTopVignette),
              ),
            ),

            // Bottom Vignette blending into dark slate canvas
            const Positioned.fill(
              child: DecoratedBox(
                decoration:
                    BoxDecoration(gradient: AppColors.heroBottomVignette),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndBadges(MediaItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.tagline != null && item.tagline!.isNotEmpty) ...[
          Text(
            item.tagline!.toUpperCase(),
            style: AppTypography.metadataPill.copyWith(
              color: AppColors.accentPink,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Main Title
        Text(
          item.title,
          style: AppTypography.displayHero.copyWith(
            fontSize: 26,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),

        // Metadata Pills Row
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AuraBadge.rating(item.formattedRating),
            const AuraBadge(
              label: '4K HDR',
              backgroundColor: Color(0x1AFFFFFF),
              borderColor: Color(0x33FFFFFF),
            ),
            if (item.releaseYear.isNotEmpty)
              AuraBadge(
                label: item.releaseYear,
                backgroundColor: AppColors.surfaceElevated,
                borderColor: const Color(0x33FFFFFF),
                textColor: AppColors.textSecondary,
              ),
            AuraBadge(
              label: item.type == MediaType.movie ? 'MOVIE' : 'SERIES',
              backgroundColor: AppColors.surfaceElevated,
              borderColor: const Color(0x33FFFFFF),
              textColor: AppColors.textMuted,
            ),
            if (item.runtimeMinutes != null && item.runtimeMinutes! > 0)
              AuraBadge(
                label: '${item.runtimeMinutes} MIN',
                backgroundColor: AppColors.surfaceElevated,
                borderColor: const Color(0x33FFFFFF),
                textColor: AppColors.textSecondary,
              ),
            if (item.type == MediaType.series && item.seasons.isNotEmpty)
              AuraBadge(
                label: '${item.seasons.length} SEASONS',
                backgroundColor: AppColors.surfaceElevated,
                borderColor: const Color(0x33FFFFFF),
                textColor: AppColors.textSecondary,
              ),
          ],
        ),

        // Genre Tags
        if (item.genres.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.genres.join(' • '),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    MediaItem item,
    bool isInWatchlist,
  ) {
    return Row(
      children: [
        // Primary Play Button (Electric Pink)
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPink,
              foregroundColor: const Color(0xFF0E0F12),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: const RoundedRectangleBorder(
                borderRadius: AppTokens.borderRadiusSmall,
              ),
              elevation: 4,
            ),
            onPressed: () => _openStreamPicker(context, item),
            icon: const AuraIcon(
              AppIcons.play,
              size: 24,
              color: Color(0xFF0E0F12),
              fill: 1.0,
            ),
            label: const Text(
              'Play',
              style: TextStyle(
                color: Color(0xFF0E0F12),
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Trailer / Secondary Button (Glass)
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              backgroundColor: AppColors.glassWhite,
              side: const BorderSide(color: Colors.white24, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: const RoundedRectangleBorder(
                borderRadius: AppTokens.borderRadiusSmall,
              ),
            ),
            onPressed: () => _launchTrailer(item.trailerUrl),
            icon: const AuraIcon(
              AppIcons.movie,
              size: 18,
              color: AppColors.textPrimary,
            ),
            label: const Text(
              'Trailer',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        if (item.type == MediaType.movie) ...[
          const SizedBox(width: 8),
          DownloadActionButton(
            mediaId: item.id,
            mediaType: MediaType.movie,
            onStartDownload: () => _initiateDownload(context, item),
            onPlayOffline: () => _playOfflineDirect(context, item),
          ),
        ],
      ],
    );
  }

  Widget _buildSynopsis(MediaItem item) {
    if (item.overview.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.overview,
          style: AppTypography.bodyOverview,
          maxLines: _isSynopsisExpanded ? null : 3,
          overflow: _isSynopsisExpanded ? null : TextOverflow.ellipsis,
        ),
        if (item.overview.length > 120) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSynopsisExpanded = !_isSynopsisExpanded;
              });
            },
            child: Text(
              _isSynopsisExpanded ? 'Show Less' : 'Read More',
              style: const TextStyle(
                color: AppColors.accentPink,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCastSection(MediaItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuraSectionHeader(
          title: 'Top Cast',
          padding: EdgeInsets.zero,
          showChevron: false,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 125,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: item.cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cast = item.cast[index];
              return SizedBox(
                width: 80,
                child: Column(
                  children: [
                    // Cast Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x1AFFFFFF),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: cast.profilePath != null
                            ? CachedNetworkImage(
                                imageUrl: cast.fullProfileUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.surfaceElevated,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surfaceElevated,
                                  child: const AuraIcon(
                                    AppIcons.person,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.surfaceElevated,
                                child: const AuraIcon(
                                  AppIcons.person,
                                  color: AppColors.textMuted,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Actor Name
                    Text(
                      cast.name,
                      style: AppTypography.itemTitle.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),

                    // Character Name
                    if (cast.character.isNotEmpty)
                      Text(
                        cast.character,
                        style: AppTypography.caption.copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeriesEpisodicSection(
    BuildContext context,
    MediaItem item,
    CatalogState state,
  ) {
    final episodes = state.currentSeason?.episodes ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuraSectionHeader(
          title: 'Episodes',
          padding: EdgeInsets.zero,
          showChevron: false,
        ),
        const SizedBox(height: 10),

        // Season Chips Selector
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: item.seasons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final season = item.seasons[index];
              final isSelected = season.seasonNumber == _selectedSeasonNumber;
              return GestureDetector(
                onTap: () => _onSeasonChanged(season.seasonNumber, item.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPink
                        : AppColors.surfaceElevated,
                    borderRadius: AppTokens.borderRadiusSmall,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentPink
                          : const Color(0x24FFFFFF),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    season.name.isNotEmpty
                        ? season.name
                        : 'Season ${season.seasonNumber}',
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0E0F12)
                          : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Episode List Breakdown
        if (state.isLoadingSeason)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accentPink),
            ),
          )
        else if (episodes.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ep = episodes[index];
              return _buildEpisodeRow(context, item, ep);
            },
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No episodes found for this season.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _buildEpisodeRow(
    BuildContext context,
    MediaItem item,
    Episode ep,
  ) {
    return AuraCard(
      padding: const EdgeInsets.all(10),
      onTap: () => _openStreamPicker(
        context,
        item,
        seasonNumber: ep.seasonNumber,
        episodeNumber: ep.episodeNumber,
        episodeTitle: ep.name,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 16:9 Thumbnail
          SizedBox(
            width: 120,
            height: 68,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: AppTokens.borderRadiusSmall,
                  child: ep.stillPath != null
                      ? CachedNetworkImage(
                          imageUrl: ep.fullStillUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceElevated),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surfaceElevated),
                        )
                      : Container(color: AppColors.surfaceElevated),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.7 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: const AuraIcon(
                      AppIcons.play,
                      color: Colors.white,
                      fill: 1.0,
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: AuraBadge.episode(
                    ep.seasonNumber,
                    ep.episodeNumber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Episode Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ep.episodeNumber}. ${ep.name}',
                  style: AppTypography.itemTitle.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ep.runtimeMinutes != null && ep.runtimeMinutes! > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${ep.runtimeMinutes}m',
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                ],
                if (ep.overview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ep.overview,
                    style: AppTypography.bodyOverview.copyWith(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Download Action for Episode
          DownloadActionButton(
            mediaId: item.id,
            mediaType: MediaType.series,
            seasonNumber: ep.seasonNumber,
            episodeNumber: ep.episodeNumber,
            iconSize: 20,
            onStartDownload: () => _initiateDownload(
              context,
              item,
              seasonNumber: ep.seasonNumber,
              episodeNumber: ep.episodeNumber,
              episodeTitle: ep.name,
            ),
            onPlayOffline: () => _playOfflineDirect(
              context,
              item,
              seasonNumber: ep.seasonNumber,
              episodeNumber: ep.episodeNumber,
              episodeTitle: ep.name,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(List<MediaItem> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return MediaPosterCard(
                item: rec,
                onTap: () {
                  context.push(
                    '/detail/${rec.type.name}/${rec.id}',
                    extra: rec,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          isInWatchlist
              ? 'Removed "${item.title}" from Watchlist'
              : 'Added "${item.title}" to Watchlist',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
