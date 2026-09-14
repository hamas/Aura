import 'dart:ui';
import 'package:aura/core/presentation/primitives/primitives.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/core/theme/app_tokens.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/clips/domain/entities/clip_item.dart';
import 'package:aura/features/clips/presentation/bloc/clips_bloc.dart';
import 'package:aura/features/clips/presentation/bloc/clips_event.dart';
import 'package:aura/features/library/domain/entities/library_item.dart';
import 'package:aura/features/library/presentation/bloc/library_bloc.dart';
import 'package:aura/features/library/presentation/bloc/library_event.dart';
import 'package:aura/features/library/presentation/bloc/library_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClipPageItem extends StatelessWidget {
  final ClipItem clip;
  final bool isActive;
  final bool isMuted;
  final bool isLiked;
  final VoidCallback onPlayTap;
  final VoidCallback onShareTap;

  const ClipPageItem({
    super.key,
    required this.clip,
    required this.isActive,
    this.isMuted = false,
    this.isLiked = false,
    required this.onPlayTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-Bleed 9:16 Video Canvas / Backdrop
        clip.backdropPath != null
            ? CachedNetworkImage(
                imageUrl: clip.fullBackdropUrl,
                fit: BoxFit.cover,
                width: size.width,
                height: size.height,
                placeholder: (_, __) =>
                    Container(color: AppColors.surfaceBackground),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surfaceBackground),
              )
            : Container(color: AppColors.surfaceBackground),

        // 2. High-Performance Dark Scrim Overlays (Top and Bottom)
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xD9000000),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 320,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xF2141414),
                  Color(0x99141414),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),



        // 4. Vertical Interactive Action Rail (Right Side)
        Positioned(
          right: 14,
          bottom: 120,
          child: BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, libraryState) {
              final isInWatchlist = libraryState.watchlist
                  .any((w) => w.id == clip.mediaId.toString());

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add to My List Toggle (Heart Icon)
                  _buildRailAction(
                    icon: AppIcons.favorite,
                    fill: isInWatchlist ? 1.0 : 0.0,
                    iconColor:
                        isInWatchlist ? AppColors.accentPink : Colors.white,
                    onTap: () {
                      final libraryItem = LibraryItem(
                        id: clip.mediaId.toString(),
                        title: clip.title,
                        posterPath: clip.posterPath,
                        backdropPath: clip.backdropPath,
                        type: clip.mediaType.name,
                        category: LibraryCategory.watchlist,
                        updatedAt: DateTime.now(),
                      );
                      context
                          .read<LibraryBloc>()
                          .add(ToggleWatchlistEvent(libraryItem));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surfaceElevated,
                          content: Text(
                            isInWatchlist
                                ? 'Removed "${clip.title}" from My List'
                                : 'Added "${clip.title}" to My List',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  // Share Sheet Button (Forward Icon)
                  _buildRailAction(
                    icon: AppIcons.forward,
                    onTap: onShareTap,
                  ),
                  const SizedBox(height: 18),

                  // Audio Mute Toggle (Volume Up / Volume Mute Icons)
                  _buildRailAction(
                    icon: isMuted ? AppIcons.volumeMute : AppIcons.volumeUp,
                    onTap: () {
                      context.read<ClipsBloc>().add(ToggleClipMuteEvent());
                    },
                  ),
                ],
              );
            },
          ),
        ),

        // 5. Bottom Info Scrim Overlay
        Positioned(
          left: 18,
          right: 86, // Leave clearance for right action rail
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Media Title
              Text(
                clip.title,
                style: AppTypography.displayHero.copyWith(
                  fontSize: 22,
                  height: 1.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Metadata Pills Row
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AuraBadge.rating(clip.formattedRating),
                  AuraBadge.quality('4K HDR'),
                  if (clip.releaseYear.isNotEmpty)
                    AuraBadge(
                      label: clip.releaseYear,
                      backgroundColor: AppColors.surfaceElevated,
                      borderColor: const Color(0x33FFFFFF),
                      textColor: AppColors.textSecondary,
                    ),
                  AuraBadge(
                    label:
                        clip.mediaType == MediaType.movie ? 'MOVIE' : 'SERIES',
                    backgroundColor: AppColors.surfaceElevated,
                    borderColor: const Color(0x33FFFFFF),
                    textColor: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2-line Synopsis
              if (clip.overview.isNotEmpty)
                Text(
                  clip.overview,
                  style: AppTypography.bodyOverview.copyWith(
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 14),

              // Primary Action: Full Stream Play Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPink,
                  foregroundColor: const Color(0xFF0E0F12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppTokens.borderRadiusSmall,
                  ),
                  elevation: 4,
                ),
                onPressed: onPlayTap,
                icon: const AuraIcon(
                  AppIcons.play,
                  size: 22,
                  color: Color(0xFF0E0F12),
                  fill: 1.0,
                ),
                label: const Text(
                  'Play',
                  style: TextStyle(
                    color: Color(0xFF0E0F12),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRailAction({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    double fill = 0.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 8 Blur Background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: const SizedBox.expand(),
              ),
            ),

            // 20% Opacity Surface Background Overlay & Border
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceBackground.withValues(alpha: 0.20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AuraIcon(
                icon,
                color: iconColor,
                size: 24,
                fill: fill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
