import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';

class PlayerGestureFeedbackOverlay extends StatelessWidget {
  final bool showLeftSeekRipple;
  final bool showRightSeekRipple;
  final int leftSeekSeconds;
  final int rightSeekSeconds;
  final bool showBrightnessHud;
  final double currentBrightness;
  final bool showVolumeHud;
  final double currentVolume;
  final bool isScrubbing;
  final Duration scrubOffset;
  final Duration scrubTarget;
  final String? zoomToastMessage;
  final Size size;
  final String Function(Duration) formatDuration;

  const PlayerGestureFeedbackOverlay({
    super.key,
    required this.showLeftSeekRipple,
    required this.showRightSeekRipple,
    this.leftSeekSeconds = 10,
    this.rightSeekSeconds = 10,
    required this.showBrightnessHud,
    required this.currentBrightness,
    required this.showVolumeHud,
    required this.currentVolume,
    required this.isScrubbing,
    required this.scrubOffset,
    required this.scrubTarget,
    this.zoomToastMessage,
    required this.size,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left Double-Tap Seek Animation Ripple (YouTube style circular badge + ripple)
        if (showLeftSeekRipple)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: size.width * 0.42,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(100)),
              child: Container(
                color: Colors.white.withAlpha(25),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AuraIcon(
                          AppIcons.replay10,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '-${leftSeekSeconds}s',
                          style: context.auraText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Right Double-Tap Seek Animation Ripple (YouTube style circular badge + ripple)
        if (showRightSeekRipple)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: size.width * 0.42,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(100)),
              child: Container(
                color: Colors.white.withAlpha(25),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AuraIcon(
                          AppIcons.forward10,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${rightSeekSeconds}s',
                          style: context.auraText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Zoom-to-Fill / Original Aspect Ratio Toast (Centered)
        if (zoomToastMessage != null)
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingMd,
                  vertical: AppTokens.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(200),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AuraIcon(AppIcons.aspectRatio, color: Colors.white, size: 16),
                    const SizedBox(width: AppTokens.spacingSm),
                    Text(
                      zoomToastMessage!,
                      style: context.auraText.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Brightness HUD Overlay (Left Vertical slider)
        if (showBrightnessHud)
          Positioned(
            left: AppTokens.spacingLg,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildHudIndicator(
                context: context,
                icon: currentBrightness > 0.5
                    ? AppIcons.brightnessHigh
                    : AppIcons.brightnessMedium,
                percent: currentBrightness,
                label: '${(currentBrightness * 100).toInt()}%',
              ),
            ),
          ),

        // Volume HUD Overlay (Right Vertical slider)
        if (showVolumeHud)
          Positioned(
            right: AppTokens.spacingLg,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildHudIndicator(
                context: context,
                icon: currentVolume == 0
                    ? AppIcons.volumeOff
                    : currentVolume > 50
                        ? AppIcons.volumeUp
                        : AppIcons.volumeDown,
                percent: currentVolume / 100.0,
                label: '${currentVolume.toInt()}%',
              ),
            ),
          ),

        // Horizontal Scrub Timeline Preview HUD
        if (isScrubbing)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingLg,
                  vertical: AppTokens.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(210),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                  border: Border.all(
                    color: AppColors.accentPink.withAlpha(140),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(120),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AuraIcon(
                          scrubOffset.isNegative
                              ? AppIcons.fastRewind
                              : AppIcons.fastForward,
                          color: AppColors.accentPink,
                          size: 20,
                        ),
                        const SizedBox(width: AppTokens.spacingSm),
                        Text(
                          '${scrubOffset.isNegative ? '' : '+'}${formatDuration(scrubOffset)}',
                          style: context.auraText.itemTitle.copyWith(
                            color: scrubOffset.isNegative
                                ? AppColors.statusError
                                : AppColors.statusSuccess,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spacingXs),
                    Text(
                      formatDuration(scrubTarget),
                      style: context.auraText.sectionTitle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHudIndicator({
    required BuildContext context,
    required IconData icon,
    required double percent,
    required String label,
  }) {
    return Container(
      width: 42,
      height: 150,
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(190),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          AuraIcon(icon, color: Colors.white, size: 18),
          const SizedBox(height: AppTokens.spacingSm),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPink),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            label,
            style: context.auraText.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
