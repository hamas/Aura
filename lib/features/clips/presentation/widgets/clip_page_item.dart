import 'dart:ui';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/core/theme/app_tokens.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/clips/domain/entities/clip_item.dart';
import 'package:aura/features/clips/presentation/bloc/clips_bloc.dart';
import 'package:aura/features/clips/presentation/bloc/clips_event.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ClipPageItem extends StatefulWidget {
  final ClipItem clip;
  final bool isActive;
  final bool isPreloadNext;
  final bool isMuted;
  final bool isLiked;
  final VoidCallback onShareTap;

  const ClipPageItem({
    super.key,
    required this.clip,
    required this.isActive,
    this.isPreloadNext = false,
    this.isMuted = false,
    this.isLiked = false,
    required this.onShareTap,
  });

  @override
  State<ClipPageItem> createState() => _ClipPageItemState();
}

class _ClipPageItemState extends State<ClipPageItem>
    with SingleTickerProviderStateMixin {
  double _progress = 0.35;
  bool _isPlaying = true;
  BoxFit _fitMode = BoxFit.cover;
  bool _showHeartAnim = false;
  late final AnimationController _heartAnimController;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _showHeartAnim = false);
        }
      });
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _triggerDoubleTapLike() {
    if (!widget.isLiked) {
      context.read<ClipsBloc>().add(ToggleClipLikeEvent(widget.clip.id));
    }
    setState(() => _showHeartAnim = true);
    _heartAnimController.forward(from: 0.0);
  }

  void _navigateToDetails() {
    final item = widget.clip.mediaItem;
    context.push('/detail/${item.type.name}/${item.id}', extra: item);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomNavHeight = MediaQuery.of(context).padding.bottom + 64.0;
    final genresLine = widget.clip.genres.isNotEmpty
        ? widget.clip.genres.join(' • ')
        : 'Trailer';
    final genresAndYear = widget.clip.releaseYear.isNotEmpty
        ? '$genresLine • ${widget.clip.releaseYear}'
        : genresLine;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-Bleed 9:16 Video Canvas / Backdrop
        GestureDetector(
          onTap: () {
            setState(() => _isPlaying = !_isPlaying);
          },
          onDoubleTap: _triggerDoubleTapLike,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_fitMode == BoxFit.contain &&
                  widget.clip.backdropPath != null)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: CachedNetworkImage(
                      imageUrl: widget.clip.fullBackdropUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              widget.clip.backdropPath != null
                  ? CachedNetworkImage(
                      imageUrl: widget.clip.fullBackdropUrl,
                      fit: _fitMode,
                      width: size.width,
                      height: size.height,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceBackground),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.surfaceBackground),
                    )
                  : Container(color: AppColors.surfaceBackground),
              if (!_isPlaying && widget.isActive)
                const Center(
                  child: AuraIcon(
                    AppIcons.play,
                    size: 64,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),

        // 2. High-Performance Dark Scrim Overlays (Top & Bottom)
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
                colors: [Color(0xD9000000), Colors.transparent],
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 360,
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

        // 3. Right Action Rail (Like, Share, Fit Toggle, Volume)
        Positioned(
          right: AppTokens.spacingMd,
          bottom: bottomNavHeight + 110.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRailAction(
                icon: AppIcons.favorite,
                iconColor: widget.isLiked ? AppColors.accentPink : Colors.white,
                fill: widget.isLiked ? 1.0 : 0.0,
                onTap: () {
                  context
                      .read<ClipsBloc>()
                      .add(ToggleClipLikeEvent(widget.clip.id));
                },
              ),
              const SizedBox(height: 14),
              _buildRailAction(
                icon: AppIcons.forward,
                onTap: widget.onShareTap,
              ),
              const SizedBox(height: 14),
              _buildRailAction(
                icon: _fitMode == BoxFit.cover
                    ? AppIcons.fullscreen
                    : AppIcons.fullscreenExit,
                onTap: () {
                  setState(() {
                    _fitMode = _fitMode == BoxFit.cover
                        ? BoxFit.contain
                        : BoxFit.cover;
                  });
                },
              ),
              const SizedBox(height: 14),
              _buildRailAction(
                icon: widget.isMuted ? AppIcons.volumeMute : AppIcons.volumeUp,
                onTap: () {
                  context.read<ClipsBloc>().add(ToggleClipMuteEvent());
                },
              ),
            ],
          ),
        ),

        // 4. Bottom Metadata Layer & Interactive Scrubbing Slider
        Positioned(
          left: AppTokens.screenEdgeHorizontal,
          right: AppTokens.screenEdgeHorizontal + 56.0,
          bottom: bottomNavHeight + 8.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _navigateToDetails,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.clip.title,
                      style: context.auraText.sectionTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      genresAndYear,
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (widget.clip.overview.isNotEmpty)
                      Text(
                        widget.clip.overview,
                        style: context.auraText.bodyOverview.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13.0,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Real-time Interactive Scrubber
              SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 2.5,
                  activeTrackColor: AppColors.accentPink,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.accentPink,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4.5),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 8.0),
                ),
                child: Slider(
                  value: _progress,
                  onChanged: (val) {
                    setState(() => _progress = val);
                  },
                ),
              ),
            ],
          ),
        ),

        // 5. Animated Heart Double-Tap Overlay
        if (_showHeartAnim)
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _heartAnimController,
                curve: Curves.elasticOut,
              ),
              child: const AuraIcon(
                AppIcons.favorite,
                size: 96,
                color: AppColors.accentPink,
                fill: 1.0,
              ),
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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceBackground.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          child: AuraIcon(
            icon,
            color: iconColor,
            size: 22,
            fill: fill,
          ),
        ),
      ),
    );
  }
}
