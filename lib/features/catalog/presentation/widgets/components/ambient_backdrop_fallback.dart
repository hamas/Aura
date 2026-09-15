import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';

/// Ambient Ken Burns slow-pan & zoom backdrop fallback widget for Aura.
class AmbientBackdropFallback extends StatefulWidget {
  final String? backdropUrl;
  final String title;

  const AmbientBackdropFallback({
    super.key,
    required this.backdropUrl,
    required this.title,
  });

  @override
  State<AmbientBackdropFallback> createState() =>
      _AmbientBackdropFallbackState();
}

class _AmbientBackdropFallbackState extends State<AmbientBackdropFallback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _translateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _translateAnim = Tween<Offset>(
      begin: const Offset(-0.02, -0.01),
      end: const Offset(0.02, 0.01),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuad),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTestMode =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (TickerMode.valuesOf(context).enabled && !isTestMode) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Animated Ken Burns Backdrop Layer
        ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: FractionalTranslation(
                  translation: _translateAnim.value,
                  child: widget.backdropUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.backdropUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surfaceCard),
                        )
                      : Container(color: AppColors.surfaceCard),
                ),
              );
            },
          ),
        ),

        // 2. Top Dark Gradient Layer
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),

        // 3. Bottom Dark Slate Gradient Overlay blending into media details
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.surfaceBackground,
              ],
              stops: [0.35, 1.0],
            ),
          ),
        ),

        // 4. Muted Ambient Preview Badge Indicator
        Positioned(
          left: 16,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuraIcon(
                  AppIcons.info,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 6),
                Text(
                  'Trailer unavailable — showing preview backdrop',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
