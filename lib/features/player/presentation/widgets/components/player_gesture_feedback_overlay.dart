import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';


class PlayerGestureFeedbackOverlay extends StatelessWidget {
  final bool showLeftSeekRipple;
  final bool showRightSeekRipple;
  final bool showBrightnessHud;
  final double currentBrightness;
  final bool showVolumeHud;
  final double currentVolume;
  final bool isScrubbing;
  final Duration scrubOffset;
  final Duration scrubTarget;
  final Size size;
  final String Function(Duration) formatDuration;

  const PlayerGestureFeedbackOverlay({
    super.key,
    required this.showLeftSeekRipple,
    required this.showRightSeekRipple,
    required this.showBrightnessHud,
    required this.currentBrightness,
    required this.showVolumeHud,
    required this.currentVolume,
    required this.isScrubbing,
    required this.scrubOffset,
    required this.scrubTarget,
    required this.size,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left Double-Tap Seek Animation Ripple
        if (showLeftSeekRipple)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: size.width * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.centerLeft,
                  radius: 1.0,
                  colors: [
                    AppColors.accentPink.withAlpha((0.25 * 255).round()),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AuraIcon(AppIcons.replay10,
                        color: AppColors.textPrimary, size: 48),
                    const SizedBox(height: AppTokens.spacingXs),
                    Text(
                      '-10s',
                      style: context.auraText.itemTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Right Double-Tap Seek Animation Ripple
        if (showRightSeekRipple)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: size.width * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.centerRight,
                  radius: 1.0,
                  colors: [
                    AppColors.accentPink.withAlpha((0.25 * 255).round()),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AuraIcon(AppIcons.forward10,
                        color: AppColors.textPrimary, size: 48),
                    const SizedBox(height: AppTokens.spacingXs),
                    Text(
                      '+10s',
                      style: context.auraText.itemTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Brightness HUD Overlay (Left Vertical)
        if (showBrightnessHud)
          Positioned(
            left: AppTokens.spacingXl,
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

        // Volume HUD Overlay (Right Vertical)
        if (showVolumeHud)
          Positioned(
            right: AppTokens.spacingXl,
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
                  color: AppColors.surfaceBackground
                      .withAlpha((0.85 * 255).round()),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                  border: Border.all(
                    color: AppColors.accentPink.withAlpha((0.5 * 255).round()),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.5 * 255).round()),
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
                          size: 24,
                        ),
                        const SizedBox(width: AppTokens.spacingSm),
                        Text(
                          '${scrubOffset.isNegative ? '' : '+'}${formatDuration(scrubOffset)}',
                          style: context.auraText.itemTitle.copyWith(
                            color: scrubOffset.isNegative
                                ? AppColors.statusError
                                : AppColors.statusSuccess,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spacingXs),
                    Text(
                      formatDuration(scrubTarget),
                      style: context.auraText.sectionTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
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
      width: 44,
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground.withAlpha((0.8 * 255).round()),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          AuraIcon(icon, color: AppColors.textPrimary, size: 20),
          const SizedBox(height: AppTokens.spacingSm),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  backgroundColor: AppColors.borderSubtle,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.accentPink),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            label,
            style: context.auraText.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
