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
  int _selectedEpisodeNumber = 1;

  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(
          LoadMediaDetailsEvent(id: widget.id, type: widget.type),
        );
  }

  void _openStreamPicker(BuildContext context, MediaItem item) {
    final stremioId = item.getStremioId(
      season: item.type == MediaType.series ? _selectedSeasonNumber : null,
      episode: item.type == MediaType.series ? _selectedEpisodeNumber : null,
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
              onStreamSelected: (stream) => _launchPlayerWithStream(context, item, stream),
            );
          },
        );
      },
    );
  }

  Future<void> _launchPlayerWithStream(
    BuildContext context,
    MediaItem item,
    AddonStream stream,
  ) async {
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
        // Record continue watching
        context.read<LibraryBloc>().add(
              UpdateProgressEvent(
                mediaId: item.id.toString(),
                title: item.title,
                posterPath: item.posterPath,
                backdropPath: item.backdropPath,
                type: item.type.name,
                positionSeconds: 1,
                durationSeconds: (item.runtimeMinutes ?? 120) * 60,
                seasonNumber: item.type == MediaType.series ? _selectedSeasonNumber : null,
                episodeNumber: item.type == MediaType.series ? _selectedEpisodeNumber : null,
              ),
            );

        await context.push(
          '/player',
          extra: {
            'streamUrl': resolved.streamUrl,
            'title': item.title,
            'subtitle': item.type == MediaType.series
                ? 'Season $_selectedSeasonNumber Episode $_selectedEpisodeNumber'
                : stream.resolution,
            'headers': resolved.httpHeaders,
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

          if (item == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sliver App Bar with Backdrop Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppTheme.background,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.6 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                              Color(0x990A0D14),
                              AppTheme.background,
                            ],
                            stops: [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Details Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Meta Badges (Rating, Year, Runtime, Type)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warningAccent.withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.warningAccent),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: AppTheme.warningAccent),
                                const SizedBox(width: 4),
                                Text(
                                  item.formattedRating,
                                  style: const TextStyle(
                                    color: AppTheme.warningAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.releaseYear,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          if (item.runtimeMinutes != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              '${item.runtimeMinutes} min',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                          const SizedBox(width: 10),
                          Text(
                            item.type == MediaType.movie ? 'Movie' : 'TV Series',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons (Play Streams & Watchlist)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openStreamPicker(context, item),
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: const Text('Find Streams'),
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
                                  border: Border.all(color: const Color(0xFF232B3E)),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
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

                      // Overview
                      const Text(
                        'Overview',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.overview.isNotEmpty ? item.overview : 'No overview available.',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // TV Series Seasons / Episodes Selector
                      if (item.type == MediaType.series && item.seasons.isNotEmpty) ...[
                        const Text(
                          'Seasons',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: item.seasons.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final season = item.seasons[index];
                              final isSelected = season.seasonNumber == _selectedSeasonNumber;
                              return ChoiceChip(
                                label: Text('Season ${season.seasonNumber}'),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _selectedSeasonNumber = season.seasonNumber;
                                      _selectedEpisodeNumber = 1;
                                    });
                                  }
                                },
                                selectedColor: AppTheme.primaryAccent,
                                backgroundColor: AppTheme.surfaceCard,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Cast Carousel
                      if (item.cast.isNotEmpty) ...[
                        const Text(
                          'Top Cast',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: item.cast.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final member = item.cast[index];
                              return SizedBox(
                                width: 75,
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
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
}
