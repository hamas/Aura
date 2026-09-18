import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:aura/core/constants/api_constants.dart';
import 'package:aura/core/presentation/primitives/primitives.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/core/theme/app_tokens.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/downloads/presentation/widgets/download_action_button.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/catalog/domain/entities/season_episode.dart';

class DetailsSeriesEpisodicSection extends StatelessWidget {
  final MediaItem item;
  final Season? currentSeason;
  final int selectedSeasonNumber;
  final ValueChanged<int> onSeasonSelected;
  final void Function(BuildContext, MediaItem,
      {int? seasonNumber,
      int? episodeNumber,
      String? episodeTitle}) onPlayEpisode;
  final void Function(BuildContext, MediaItem,
      {int? seasonNumber,
      int? episodeNumber,
      String? episodeTitle}) onDownloadEpisode;
  final void Function(BuildContext, MediaItem,
      {int? seasonNumber,
      int? episodeNumber,
      String? episodeTitle}) onPlayOfflineEpisode;

  const DetailsSeriesEpisodicSection({
    super.key,
    required this.item,
    this.currentSeason,
    required this.selectedSeasonNumber,
    required this.onSeasonSelected,
    required this.onPlayEpisode,
    required this.onDownloadEpisode,
    required this.onPlayOfflineEpisode,
  });

  @override
  Widget build(BuildContext context) {
    final seasonToDisplay = currentSeason ??
        item.seasons.firstWhere(
          (s) => s.seasonNumber == selectedSeasonNumber,
          orElse: () => item.seasons.first,
        );

    final episodes = seasonToDisplay.episodes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Season Selector Dropdown / Pills
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: item.seasons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final season = item.seasons[index];
              final isSelected = season.seasonNumber == selectedSeasonNumber;
              return GestureDetector(
                onTap: () => onSeasonSelected(season.seasonNumber),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color:
                          isSelected ? Colors.white : const Color(0x22FFFFFF),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Season ${season.seasonNumber}',
                      style: context.auraText.caption.copyWith(
                        color: isSelected
                            ? AppColors.surfaceBackground
                            : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTokens.screenEdgeHorizontal),

        // Episodes List
        if (episodes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.accentPink,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: episodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return _buildEpisodeCard(context, episode);
            },
          ),
      ],
    );
  }

  Widget _buildEpisodeCard(BuildContext context, Episode episode) {
    final stillUrl = episode.stillPath != null
        ? '${ApiConstants.tmdbPosterW500}${episode.stillPath}'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Episode Still Thumbnail with Play Icon Overlay
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 62,
                decoration: const BoxDecoration(
                  borderRadius: AppTokens.borderRadiusSmall,
                  color: AppColors.surfaceCard,
                ),
                child: ClipRRect(
                  borderRadius: AppTokens.borderRadiusSmall,
                  child: stillUrl != null
                      ? CachedNetworkImage(
                          imageUrl: stillUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.movie,
                            color: AppColors.textMuted,
                          ),
                        )
                      : const Icon(Icons.movie, color: AppColors.textMuted),
                ),
              ),
              IconButton(
                icon: const AuraIcon(
                  AppIcons.play,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => onPlayEpisode(
                  context,
                  item,
                  seasonNumber: selectedSeasonNumber,
                  episodeNumber: episode.episodeNumber,
                  episodeTitle: episode.name,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Episode Metadata & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${episode.episodeNumber}. ${episode.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.itemTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  episode.overview.isNotEmpty
                      ? episode.overview
                      : 'No synopsis available.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Download Action Button
          DownloadActionButton(
            mediaId: item.id,
            mediaType: MediaType.series,
            seasonNumber: selectedSeasonNumber,
            episodeNumber: episode.episodeNumber,
            onStartDownload: () => onDownloadEpisode(
              context,
              item,
              seasonNumber: selectedSeasonNumber,
              episodeNumber: episode.episodeNumber,
              episodeTitle: episode.name,
            ),
            onPlayOffline: () => onPlayOfflineEpisode(
              context,
              item,
              seasonNumber: selectedSeasonNumber,
              episodeNumber: episode.episodeNumber,
              episodeTitle: episode.name,
            ),
          ),
        ],
      ),
    );
  }
}
