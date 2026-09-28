import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../library/domain/entities/library_item.dart';
import '../../../../library/presentation/bloc/library_bloc.dart';
import '../../../../library/presentation/bloc/library_event.dart';
import '../../../../library/presentation/bloc/library_state.dart';
import '../../../domain/entities/media_item.dart';

/// Netflix-style Quick Action Preview Modal.
/// Triggered on long-pressing any media card in the feed.
/// Offers instant 1-tap playback, watchlist toggle, rating feedback, and info navigation.
class NetflixQuickActionModal extends StatefulWidget {
  final MediaItem item;
  final void Function(MediaItem item)? onPlayTap;
  final void Function(MediaItem item)? onInfoTap;

  const NetflixQuickActionModal({
    super.key,
    required this.item,
    this.onPlayTap,
    this.onInfoTap,
  });

  static Future<void> show({
    required BuildContext context,
    required MediaItem item,
    void Function(MediaItem item)? onPlayTap,
    void Function(MediaItem item)? onInfoTap,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => NetflixQuickActionModal(
        item: item,
        onPlayTap: onPlayTap,
        onInfoTap: onInfoTap,
      ),
    );
  }

  @override
  State<NetflixQuickActionModal> createState() => _NetflixQuickActionModalState();
}

class _NetflixQuickActionModalState extends State<NetflixQuickActionModal> {
  int _userRating = 0; // 0 = none, 1 = thumbs down, 2 = thumbs up, 3 = love it (double thumbs up)

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isTv = item.type == MediaType.series;
    final year = item.releaseDate != null && item.releaseDate!.length >= 4
        ? item.releaseDate!.substring(0, 4)
        : '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F24),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLarge),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Row: Poster & Core Metadata
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media Poster Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 90,
                    height: 130,
                    child: item.posterPath != null
                        ? CachedNetworkImage(
                            imageUrl: item.fullPosterUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.surfaceElevated),
                            errorWidget: (_, __, ___) => Container(color: AppColors.surfaceElevated),
                          )
                        : Container(color: AppColors.surfaceElevated),
                  ),
                ),
                const SizedBox(width: 14),

                // Title, Year, Match & Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: context.auraText.itemTitle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Year & Match Badge Row
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          if (item.voteAverage > 0)
                            Text(
                              '${(item.voteAverage * 10).round()}% Match',
                              style: const TextStyle(
                                color: Color(0xFF46D369), // Netflix Match Green
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          if (year.isNotEmpty)
                            Text(
                              year,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              isTv ? 'TV-MA' : 'PG-13',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white38, width: 0.8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'HD',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Overview / Logline
                      if (item.overview.isNotEmpty)
                        Text(
                          item.overview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Primary Full-Width Play Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onPlayTap?.call(item);
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 28, color: Colors.black),
                label: const Text(
                  'Play',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Secondary Quick Actions Grid (My List, Rate, Share, Details)
            BlocBuilder<LibraryBloc, LibraryState>(
              builder: (context, libState) {
                final isInWatchlist = libState.watchlist.any(
                  (w) => w.id == item.id.toString(),
                );

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 1. My List Toggle
                    _ActionButton(
                      icon: isInWatchlist ? Icons.check : Icons.add,
                      label: 'My List',
                      isActive: isInWatchlist,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<LibraryBloc>().add(
                              ToggleWatchlistEvent(
                                LibraryItem(
                                  id: item.id.toString(),
                                  title: item.title,
                                  type: isTv ? 'series' : 'movie',
                                  category: LibraryCategory.watchlist,
                                  posterPath: item.posterPath,
                                  backdropPath: item.backdropPath,
                                  updatedAt: DateTime.now(),
                                ),
                              ),
                            );
                      },
                    ),

                    // 2. Rating (I Like This)
                    _ActionButton(
                      icon: _userRating == 2 ? Icons.thumb_up : Icons.thumb_up_outlined,
                      label: _userRating == 2 ? 'Liked' : 'Rate',
                      isActive: _userRating == 2,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _userRating = _userRating == 2 ? 0 : 2;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceElevated,
                            duration: const Duration(seconds: 2),
                            content: Text(
                              _userRating == 2
                                  ? 'Thanks for the feedback! We will suggest similar titles.'
                                  : 'Feedback removed.',
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        );
                      },
                    ),

                    // 3. Share
                    _ActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final shareText = 'Watch "${item.title}" on Aura: https://aura.tv/media/${item.id}';
                        Clipboard.setData(ClipboardData(text: shareText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.surfaceElevated,
                            duration: Duration(seconds: 2),
                            content: Text(
                              'Link copied to clipboard!',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        );
                      },
                    ),

                    // 4. Details / Info
                    _ActionButton(
                      icon: Icons.info_outline,
                      label: 'Details',
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onInfoTap?.call(item);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.accentPink : Colors.white,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.accentPink : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
