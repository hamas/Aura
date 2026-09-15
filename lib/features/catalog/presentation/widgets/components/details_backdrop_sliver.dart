import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:aura/core/constants/api_constants.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/catalog/presentation/widgets/components/ambient_backdrop_fallback.dart';
import 'package:aura/features/player/data/services/trailer_stream_resolver.dart';

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
  Player? _player;
  VideoController? _videoController;
  TrailerStreamResult? _trailerResult;

  bool _isMuted = true;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _initTrailerPlayer();
  }

  @override
  void didUpdateWidget(DetailsBackdropSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.trailerUrl != widget.item.trailerUrl ||
        oldWidget.item.id != widget.item.id) {
      _initTrailerPlayer();
    }
  }

  Future<void> _initTrailerPlayer() async {
    // Avoid creating native media_kit Player instances in unit/widget test environments
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return;

    await _player?.dispose();
    _player = null;
    _videoController = null;
    _trailerResult = null;

    final resolver = TrailerStreamResolver();
    final result = await resolver.resolveTrailerStream(
      title: widget.item.title,
      year: widget.item.releaseYear,
      tmdbTrailerUrl: widget.item.trailerUrl,
      mediaType: widget.item.type.name,
    );

    if (!mounted) return;

    if (result.streamUrl != null && result.streamUrl!.isNotEmpty) {
      try {
        final player = Player(
          configuration: const PlayerConfiguration(
            logLevel: MPVLogLevel.warn,
          ),
        );
        final controller = VideoController(
          player,
          configuration: const VideoControllerConfiguration(
            enableHardwareAcceleration: true,
          ),
        );

        await player.setVolume(0);
        await player.setPlaylistMode(PlaylistMode.loop);
        await player.open(Media(result.streamUrl!));

        if (mounted) {
          setState(() {
            _player = player;
            _videoController = controller;
            _trailerResult = result;
            _isMuted = true;
            _isPlaying = true;
          });
        } else {
          await player.dispose();
        }
        return;
      } catch (e) {
        debugPrint('[DetailsBackdropSliver] Error initializing player stream: $e');
      }
    }

    // Immediately trigger AmbientBackdropFallback if no playable direct stream URL exists or open failed
    if (mounted) {
      setState(() {
        _trailerResult = result;
      });
    }
  }

  bool _showControlsOverlay = false;

  void _onBackdropTap() {
    if (_player == null) return;
    setState(() {
      _showControlsOverlay = !_showControlsOverlay;
    });
  }

  void _togglePlayPause() {
    if (_player == null) return;
    setState(() {
      _isPlaying = !_isPlaying;
      _showControlsOverlay = !_isPlaying; // Show controls if paused, hide if resumed
    });
    if (_isPlaying) {
      _player?.play();
    } else {
      _player?.pause();
    }
  }

  void _toggleMute() {
    if (_player == null) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    _player?.setVolume(_isMuted ? 0 : 100);
  }

  void _toggleFullscreen() {
    final streamUrl = _trailerResult?.streamUrl ?? widget.item.trailerUrl;
    if (streamUrl != null && streamUrl.isNotEmpty) {
      context.push(
        '/player',
        extra: {
          'streamUrl': streamUrl,
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
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backdropUrl = widget.item.backdropPath != null
        ? '${ApiConstants.tmdbImageBaseUrl}${widget.item.backdropPath}'
        : null;

    final hasNativeTrailer =
        _videoController != null && _trailerResult != null && _trailerResult!.hasStream;

    // Hide control icons while playing unless user explicitly tapped the screen to reveal controls
    final shouldShowControls = hasNativeTrailer && (!_isPlaying || _showControlsOverlay);

    return SliverAppBar(
      expandedHeight: 340.0,
      pinned: true,
      backgroundColor: AppColors.surfaceBackground,
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasNativeTrailer ? _onBackdropTap : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Ambient Ken Burns Backdrop Fallback when no direct video stream is available
              if (!hasNativeTrailer)
                AmbientBackdropFallback(
                  backdropUrl: backdropUrl,
                  title: widget.item.title,
                )
              else ...[
                // Base Backdrop Image
                if (backdropUrl != null)
                  CachedNetworkImage(
                    imageUrl: backdropUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceCard),
                  )
                else
                  Container(color: AppColors.surfaceCard),

                // Active Native MediaKit Video Player (Filled cleanly using BoxFit.cover)
                Positioned.fill(
                  child: ClipRect(
                    child: SizedBox.expand(
                      child: Video(
                        controller: _videoController!,
                        fit: BoxFit.cover,
                        controls: (state) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],

              // Center Play / Pause Single Button Overlay
              if (shouldShowControls)
                Center(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(12),
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
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Bottom Left Control: Mute / Unmute Button (Reduced size by 30%: 20px -> 14px icon, padding 10 -> 7)
              if (shouldShowControls)
                Positioned(
                  left: 16,
                  bottom: 36,
                  child: GestureDetector(
                    onTap: _toggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(7),
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
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Bottom Right Control: Fullscreen Button (Reduced size by 30%: 20px -> 14px icon, padding 10 -> 7)
              if (shouldShowControls)
                Positioned(
                  right: 16,
                  bottom: 36,
                  child: GestureDetector(
                    onTap: _toggleFullscreen,
                    child: Container(
                      padding: const EdgeInsets.all(7),
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
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
