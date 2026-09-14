import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../domain/entities/media_interval.dart';

class SkipIntervalPill extends StatefulWidget {
  final MediaInterval interval;
  final VoidCallback onSkip;

  const SkipIntervalPill({
    super.key,
    required this.interval,
    required this.onSkip,
  });

  @override
  State<SkipIntervalPill> createState() => _SkipIntervalPillState();
}

class _SkipIntervalPillState extends State<SkipIntervalPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _label {
    switch (widget.interval.type) {
      case MediaIntervalType.intro:
        return 'Skip Intro';
      case MediaIntervalType.recap:
        return 'Skip Recap';
      case MediaIntervalType.credits:
        return 'Skip Credits';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onSkip,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.85 * 255).round()),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFB877FF), // Signature #B877FF border
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(0xFFB877FF).withAlpha((0.35 * 255).round()),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuraIcon(
                    AppIcons.fastForward,
                    color: Color(0xFFB877FF),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NextEpisodeCountdownCard extends StatefulWidget {
  final VoidCallback onPlayNext;
  final VoidCallback onDismiss;
  final int countdownSeconds;

  const NextEpisodeCountdownCard({
    super.key,
    required this.onPlayNext,
    required this.onDismiss,
    this.countdownSeconds = 5,
  });

  @override
  State<NextEpisodeCountdownCard> createState() =>
      _NextEpisodeCountdownCardState();
}

class _NextEpisodeCountdownCardState extends State<NextEpisodeCountdownCard> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.countdownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        widget.onPlayNext();
      } else {
        if (mounted) {
          setState(() => _secondsLeft--);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryAccent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$_secondsLeft',
              style: const TextStyle(
                color: AppTheme.primaryAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next Episode',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Playing in ${_secondsLeft}s...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: widget.onPlayNext,
            icon: const AuraIcon(AppIcons.playCircle, size: 16),
            label: const Text(
              'Play Now',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const AuraIcon(AppIcons.close,
                size: 18, color: AppTheme.textMuted),
            onPressed: widget.onDismiss,
          ),
        ],
      ),
    );
  }
}
