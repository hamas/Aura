import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../catalog/presentation/bloc/catalog_bloc.dart';
import '../../../../catalog/presentation/bloc/catalog_event.dart';
import '../../../../catalog/presentation/bloc/catalog_state.dart';

/// In-Player Netflix-style Slide-Up Episode Drawer.
/// Allows browsing and instantly playing any episode in a series without exiting fullscreen.
class InPlayerEpisodeDrawer extends StatefulWidget {
  final int seriesId;
  final String seriesTitle;
  final int initialSeason;
  final int currentEpisode;
  final int totalSeasons;
  final void Function(int season, int episode, String? episodeTitle) onEpisodeSelected;

  const InPlayerEpisodeDrawer({
    super.key,
    required this.seriesId,
    required this.seriesTitle,
    this.initialSeason = 1,
    this.currentEpisode = 1,
    this.totalSeasons = 1,
    required this.onEpisodeSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required int seriesId,
    required String seriesTitle,
    int initialSeason = 1,
    int currentEpisode = 1,
    int totalSeasons = 1,
    required void Function(int season, int episode, String? episodeTitle) onEpisodeSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InPlayerEpisodeDrawer(
        seriesId: seriesId,
        seriesTitle: seriesTitle,
        initialSeason: initialSeason,
        currentEpisode: currentEpisode,
        totalSeasons: totalSeasons,
        onEpisodeSelected: onEpisodeSelected,
      ),
    );
  }

  @override
  State<InPlayerEpisodeDrawer> createState() => _InPlayerEpisodeDrawerState();
}

class _InPlayerEpisodeDrawerState extends State<InPlayerEpisodeDrawer> {
  late int _selectedSeason;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.initialSeason;
    _loadSeasonEpisodes(_selectedSeason);
  }

  void _loadSeasonEpisodes(int seasonNumber) {
    context.read<CatalogBloc>().add(
          LoadSeasonDetailsEvent(
            seriesId: widget.seriesId,
            seasonNumber: seasonNumber,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: const Color(0xFF141519),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header (Title, Season Picker Dropdown, Close button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.seriesTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Season Selector Dropdown
                        PopupMenuButton<int>(
                          initialValue: _selectedSeason,
                          color: const Color(0xFF22242B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          onSelected: (season) {
                            setState(() => _selectedSeason = season);
                            _loadSeasonEpisodes(season);
                          },
                          itemBuilder: (context) {
                            final maxSeasons = widget.totalSeasons > 0 ? widget.totalSeasons : 10;
                            return List.generate(maxSeasons, (index) {
                              final sNum = index + 1;
                              return PopupMenuItem<int>(
                                value: sNum,
                                child: Text(
                                  'Season $sNum',
                                  style: TextStyle(
                                    color: sNum == _selectedSeason ? AppColors.accentPink : Colors.white,
                                    fontWeight: sNum == _selectedSeason ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Season $_selectedSeason',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // Episode List
            Expanded(
              child: BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) {
                  if (state.isLoadingSeason) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentPink,
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                  final episodes = state.currentSeason?.episodes ?? const [];
                  if (episodes.isEmpty) {
                    return Center(
                      child: Text(
                        'No episodes found for Season $_selectedSeason',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: episodes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ep = episodes[index];
                      final isPlaying = _selectedSeason == widget.initialSeason &&
                          ep.episodeNumber == widget.currentEpisode;

                      return _buildEpisodeTile(ep, isPlaying);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeTile(dynamic ep, bool isPlaying) {
    final title = ep.name as String? ?? 'Episode ${ep.episodeNumber}';
    final overview = ep.overview as String? ?? '';
    final stillPath = ep.stillPath as String?;
    final runtime = ep.runtime as int?;

    return Material(
      color: isPlaying ? AppColors.accentPink.withValues(alpha: 0.12) : const Color(0xFF1C1E24),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pop();
          widget.onEpisodeSelected(_selectedSeason, ep.episodeNumber as int? ?? 1, title);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPlaying ? AppColors.accentPink : Colors.white.withValues(alpha: 0.05),
              width: isPlaying ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Episode Thumbnail with Play icon overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: stillPath != null
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w300$stillPath',
                            width: 110,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackThumbnail(),
                          )
                        : _buildFallbackThumbnail(),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white70, width: 1.2),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isPlaying ? AppColors.accentPink : Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Episode Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${ep.episodeNumber}. ',
                          style: TextStyle(
                            color: isPlaying ? AppColors.accentPink : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isPlaying ? AppColors.accentPink : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (runtime != null && runtime > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${runtime}m',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    if (overview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        overview,
                        style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      width: 110,
      height: 68,
      color: Colors.white12,
      child: const Center(
        child: Icon(Icons.movie_outlined, color: Colors.white30, size: 28),
      ),
    );
  }
}
