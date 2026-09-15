import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:aura/core/constants/api_constants.dart';
import 'package:aura/core/constants/app_assets.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/core/theme/app_tokens.dart';
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
            bufferSize: 32 * 1024 * 1024,
          ),
        );

        if (player.platform is NativePlayer) {
          try {
            final mpv = player.platform as dynamic;
            await mpv.setProperty('demuxer-max-bytes', '32MiB');
            await mpv.setProperty('demuxer-readahead-secs', '5');
            await mpv.setProperty('network-timeout', '5');
          } catch (_) {}
        }

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

    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: AppColors.surfaceBackground,
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      titleSpacing: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasNativeTrailer ? _onBackdropTap : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Base Ambient / TMDB Image Backdrop (stays underneath video for instant placeholder transition)
              if (backdropUrl != null)
                CachedNetworkImage(
                  imageUrl: backdropUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => AmbientBackdropFallback(
                    backdropUrl: null,
                    title: widget.item.title,
                  ),
                )
              else
                AmbientBackdropFallback(
                  backdropUrl: null,
                  title: widget.item.title,
                ),

              // 2. Active Native MediaKit Video Player (Zoomed & Cropped with BoxFit.cover to eliminate letterboxing)
              if (hasNativeTrailer)
                Positioned.fill(
                  child: ClipRect(
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: _player?.state.width?.toDouble() ?? 16,
                          height: _player?.state.height?.toDouble() ?? 9,
                          child: Video(
                            controller: _videoController!,
                            fit: BoxFit.cover,
                            controls: (state) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. Homepage Top Bar Style Blur & Scrim Gradient Background at Top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topPadding + 64,
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Progressive Blur
                      Positioned.fill(
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0x99FFFFFF),
                                Color(0x00FFFFFF),
                              ],
                              stops: [0.0, 0.55, 1.0],
                            ).createShader(bounds);
                          },
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                            child: const ColoredBox(color: Colors.black),
                          ),
                        ),
                      ),
                      // Scrim Gradient
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.surfaceBackground.withValues(alpha: 0.65),
                                AppColors.surfaceBackground.withValues(alpha: 0.30),
                                AppColors.surfaceBackground.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.60, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Custom Homepage Style Top Bar Row (Back button left, Heart -> Share -> App Logo right)
              Positioned(
                top: topPadding + 4,
                left: AppTokens.screenEdgeHorizontal,
                right: AppTokens.screenEdgeHorizontal,
                child: Row(
                  children: [
                    // Left Back Button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const AuraIcon(
                          AppIcons.back,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),

                    const Spacer(),

                    // Right Actions: 1. Like / Watchlist Icon (Heart)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: AuraIcon(
                          AppIcons.favorite,
                          fill: widget.isInWatchlist ? 1.0 : 0.0,
                          color: widget.isInWatchlist
                              ? AppColors.accentPink
                              : Colors.white,
                          size: 18,
                        ),
                        onPressed: widget.onToggleWatchlist,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Right Actions: 2. Share Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const AuraIcon(
                          AppIcons.share,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: widget.onShare,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Right Actions: 3. App Logo
                    ClipOval(
                      child: Image.asset(
                        AppAssets.appIcon,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.accentPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'A',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
    );
  }
}
