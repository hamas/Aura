import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../addons/domain/entities/addon_stream.dart';
import '../../../addons/presentation/bloc/addon_bloc.dart';
import '../../../addons/presentation/bloc/addon_event.dart';
import '../../../addons/presentation/bloc/addon_state.dart';
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

class DetailScreen extends StatefulWidget {
  final int id;
  final MediaType type;
  final MediaItem? initialItem;

  const DetailScreen({
    super.key,
    required this.id,
    required this.type,
    this.initialItem,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _selectedSeasonNumber = 1;

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
          LoadSeasonDetailsEvent(seriesId: seriesId, seasonNumber: seasonNumber),
        );
  }

  void _openStreamPicker(
    BuildContext context,
    MediaItem item, {
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
  }) {
    final effectiveSeason = item.type == MediaType.series ? (seasonNumber ?? _selectedSeasonNumber) : null;
    final effectiveEpisode = item.type == MediaType.series ? (episodeNumber ?? 1) : null;

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
        if (item.type == MediaType.series && seasonNumber != null && episodeNumber != null) {
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
            backgroundColor: AppTheme.errorAccent,
            content: Text('Failed to start stream: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          final item = state.selectedMedia ?? widget.initialItem;

          if (item == null && state.isLoadingDetails) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            );
          }

          if (item == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Details')),
              body: const Center(
                child: Text(
                  'Media details could not be loaded.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Expansive Backdrop Header
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppTheme.background,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.65 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.backdropPath != null
                          ? CachedNetworkImage(
                              imageUrl: item.fullBackdropUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(color: AppTheme.surfaceCard),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x800A0D14),
                              Color(0xD90A0D14),
                              AppTheme.background,
                            ],
                            stops: [0.0, 0.45, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Details Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster and Meta Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster Thumbnail
                          if (item.posterPath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: item.fullPosterUrl,
                                width: 100,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 16),

                          // Titles and Badges
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.4,
                                    height: 1.2,
                                  ),
                                ),
                                if (item.tagline != null && item.tagline!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.tagline!,
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 10),

                                // Meta Pills
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // Rating
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warningAccent.withAlpha((0.2 * 255).round()),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppTheme.warningAccent, width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 13, color: AppTheme.warningAccent),
                                          const SizedBox(width: 3),
                                          Text(
                                            item.formattedRating,
                                            style: const TextStyle(
                                              color: AppTheme.warningAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Release Year
                                    if (item.releaseYear.isNotEmpty)
                                      Text(
                                        item.releaseYear,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                    // Runtime
                                    if (item.runtimeMinutes != null)
                                      Text(
                                        '${item.runtimeMinutes} min',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                    // Type Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E2638),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.type == MediaType.movie ? 'Movie' : 'TV Series',
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Genre Pills
                      if (item.genres.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: item.genres.map((g) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF1E283E)),
                              ),
                              child: Text(
                                g.name,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      // Action Buttons (Play Streams & Watchlist)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openStreamPicker(context, item),
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: Text(
                                item.type == MediaType.series ? 'Play S1:E1' : 'Play / Find Streams',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          BlocBuilder<LibraryBloc, LibraryState>(
                            builder: (context, libState) {
                              final isInWatchlist = libState.isInWatchlist(item.id.toString());
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isInWatchlist ? AppTheme.primaryAccent : const Color(0xFF232B3E),
                                  ),
                                ),
                                child: IconButton(
                                  tooltip: isInWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
                                  icon: Icon(
                                    isInWatchlist ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                                    color: isInWatchlist ? AppTheme.primaryAccent : Colors.white,
                                  ),
                                  onPressed: () {
                                    context.read<LibraryBloc>().add(
                                          ToggleWatchlistEvent(
                                            LibraryItem(
                                              id: item.id.toString(),
                                              title: item.title,
                                              posterPath: item.posterPath,
                                              backdropPath: item.backdropPath,
                                              type: item.type.name,
                                              category: LibraryCategory.watchlist,
                                              updatedAt: DateTime.now(),
                                            ),
                                          ),
                                        );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Overview Section
                      const Text(
                        'Synopsis',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.overview.isNotEmpty ? item.overview : 'No synopsis available.',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13.5,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Cast Carousel
                      if (item.cast.isNotEmpty) ...[
                        const Text(
                          'Cast & Crew',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: item.cast.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final member = item.cast[index];
                              return SizedBox(
                                width: 72,
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppTheme.surfaceElevated,
                                      backgroundImage: member.profilePath != null
                                          ? CachedNetworkImageProvider(
                                              '${ApiConstants.tmdbPosterW500}${member.profilePath}')
                                          : null,
                                      child: member.profilePath == null
                                          ? const Icon(Icons.person, color: AppTheme.textMuted)
                                          : null,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      member.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      member.character,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 10,
                                      ),
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
                        const SizedBox(height: 24),
                      ],

                      // TV Series Seasons & Episodes Breakdown
                      if (item.type == MediaType.series) ...[
                        _buildSeriesSeasonsAndEpisodes(context, item, state),
                        const SizedBox(height: 32),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeriesSeasonsAndEpisodes(
    BuildContext context,
    MediaItem item,
    CatalogState state,
  ) {
    final seasons = item.seasons.isNotEmpty
        ? item.seasons
        : const [Season(id: 1, seasonNumber: 1, name: 'Season 1', overview: '')];

    final currentSeason = state.currentSeason;
    final episodes = currentSeason?.episodes ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Seasons & Episodes',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            if (state.isLoadingSeason)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryAccent),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Season Chips Selector
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final season = seasons[index];
              final isSelected = season.seasonNumber == _selectedSeasonNumber;
              return ChoiceChip(
                label: Text('Season ${season.seasonNumber}'),
                selected: isSelected,
                onSelected: (sel) {
                  if (sel) {
                    _onSeasonChanged(season.seasonNumber, item.id);
                  }
                },
                selectedColor: AppTheme.primaryAccent,
                backgroundColor: AppTheme.surfaceCard,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Episode List
        if (state.isLoadingSeason && episodes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            ),
          )
        else if (episodes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No episode breakdown available for this season.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return _buildEpisodeTile(context, item, episode);
            },
          ),
      ],
    );
  }

  Widget _buildEpisodeTile(BuildContext context, MediaItem item, Episode episode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openStreamPicker(
          context,
          item,
          seasonNumber: episode.seasonNumber,
          episodeNumber: episode.episodeNumber,
          episodeTitle: episode.name,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard.withAlpha((0.9 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E283E)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Episode Thumbnail
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: episode.stillPath != null
                        ? CachedNetworkImage(
                            imageUrl: '${ApiConstants.tmdbPosterW500}${episode.stillPath}',
                            width: 100,
                            height: 64,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 100,
                            height: 64,
                            color: const Color(0xFF1B2335),
                            child: const Icon(Icons.movie, color: AppTheme.textMuted),
                          ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.6 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Episode Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'E${episode.episodeNumber}',
                          style: const TextStyle(
                            color: AppTheme.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            episode.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      episode.overview.isNotEmpty ? episode.overview : 'No description provided.',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
