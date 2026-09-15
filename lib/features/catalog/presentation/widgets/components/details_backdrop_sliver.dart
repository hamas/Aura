import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:aura/core/constants/api_constants.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';

class DetailsBackdropSliver extends StatefulWidget {
  final MediaItem item;
  final bool isInWatchlist;
  final VoidCallback onToggleWatchlist;
  final VoidCallback onShare;

  const DetailsBackdropSliver({
    super.key,
    required this.item,
    required this.isInWatchlist,
    required this.onToggleWatchlist,
    required this.onShare,
  });

  @override
  State<DetailsBackdropSliver> createState() => _DetailsBackdropSliverState();
}

class _DetailsBackdropSliverState extends State<DetailsBackdropSliver> {
  bool _isMuted = true;
  bool _isPlaying = true;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _initYoutubePlayer();
  }

  @override
  void didUpdateWidget(DetailsBackdropSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.trailerUrl != widget.item.trailerUrl) {
      _initYoutubePlayer();
    }
  }

  void _initYoutubePlayer() {
    final rawTrailerUrl = widget.item.trailerUrl;
    if (rawTrailerUrl == null || rawTrailerUrl.isEmpty) {
      return;
    }

    final videoId =
        YoutubePlayerController.convertUrlToId(rawTrailerUrl) ?? rawTrailerUrl;
    if (videoId.isEmpty) return;

    _youtubeController?.close();
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        mute: true,
        showControls: false,
        showFullscreenButton: false,
        loop: true,
        strictRelatedVideos: true,
      ),
    );

    if (mounted) {
      setState(() {
        _isPlaying = true;
        _isMuted = true;
      });
    }
  }

  void _togglePlayPause() {
    if (_youtubeController == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _youtubeController?.playVideo();
    } else {
      _youtubeController?.pauseVideo();
    }
  }

  void _toggleMute() {
    if (_youtubeController == null) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isMuted) {
      _youtubeController?.mute();
    } else {
      _youtubeController?.unMute();
    }
  }

  void _toggleFullscreen() {
    final rawTrailerUrl = widget.item.trailerUrl;
    if (rawTrailerUrl != null && rawTrailerUrl.isNotEmpty) {
      context.push(
        '/player',
        extra: {
          'streamUrl': rawTrailerUrl,
          'title': widget.item.title,
          'subtitle': 'Official Trailer',
          'mediaId': widget.item.id.toString(),
          'posterPath': widget.item.posterPath,
          'backdropPath': widget.item.backdropPath,
        },
      );
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backdropUrl = widget.item.backdropPath != null
        ? '${ApiConstants.tmdbImageBaseUrl}${widget.item.backdropPath}'
        : null;

    final hasTrailer = _youtubeController != null;

    return SliverAppBar(
      expandedHeight: 340.0,
      pinned: true,
      backgroundColor: AppColors.surfaceBackground,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Base Backdrop Image Layer
            if (backdropUrl != null)
              CachedNetworkImage(
                imageUrl: backdropUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surfaceCard),
              )
            else
              Container(color: AppColors.surfaceCard),

            // 2. Active YouTube Trailer Player Layer (Scaled to crop YouTube title chrome, zero bleed)
            if (_youtubeController != null)
              Positioned.fill(
                child: ClipRect(
                  child: Transform.scale(
                    scale: 1.35,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: 1280,
                        height: 720,
                        child: IgnorePointer(
                          child: YoutubePlayer(
                            controller: _youtubeController!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 3. Top gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),

            // 4. Bottom cinematic gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.surfaceBackground,
                  ],
                  stops: [0.3, 1.0],
                ),
              ),
            ),

            // 5. Center Play / Pause Single Button Overlay
            if (hasTrailer)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: AuraIcon(
                      _isPlaying ? AppIcons.pause : AppIcons.play,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // 6. Bottom Left Control: Mute / Unmute Button
            if (hasTrailer)
              Positioned(
                left: 20,
                bottom: 40,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: AuraIcon(
                      _isMuted ? AppIcons.volumeOff : AppIcons.volumeUp,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // 7. Bottom Right Control: Fullscreen Button
            if (hasTrailer)
              Positioned(
                right: 20,
                bottom: 40,
                child: GestureDetector(
                  onTap: _toggleFullscreen,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const AuraIcon(
                      AppIcons.fullscreen,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: AuraIcon(
            AppIcons.favorite,
            fill: widget.isInWatchlist ? 1.0 : 0.0,
            color:
                widget.isInWatchlist ? AppColors.accentPink : AppColors.textPrimary,
          ),
          onPressed: widget.onToggleWatchlist,
        ),
        IconButton(
          icon: const AuraIcon(AppIcons.share, color: AppColors.textPrimary),
          onPressed: widget.onShare,
        ),
      ],
    );
  }
}
