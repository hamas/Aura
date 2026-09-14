import 'dart:async';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_tokens.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class NextEpisodeCard extends StatefulWidget {
  final String nextEpisodeTitle;
  final VoidCallback onPlayNow;
  final int countdownSeconds;

  const NextEpisodeCard({
    super.key,
    required this.nextEpisodeTitle,
    required this.onPlayNow,
    this.countdownSeconds = 5,
  });

  @override
  State<NextEpisodeCard> createState() => _NextEpisodeCardState();
}

class _NextEpisodeCardState extends State<NextEpisodeCard> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > 1) {
        setState(() => _remaining--);
      } else {
        _timer?.cancel();
        widget.onPlayNow();
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
    final progress = _remaining / widget.countdownSeconds;

    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppTokens.spacingSm + 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.46),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white24,
                  color: AppColors.accentPink,
                ),
              ),
              Text(
                '$_remaining',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Next Episode',
                  style: context.auraText.caption
                      .copyWith(color: AppColors.textMuted),
                ),
                Text(
                  widget.nextEpisodeTitle,
                  style: context.auraText.bodyOverview.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.play_circle_fill,
                color: AppColors.accentPink, size: 30),
            onPressed: widget.onPlayNow,
          ),
        ],
      ),
    );
  }
}
