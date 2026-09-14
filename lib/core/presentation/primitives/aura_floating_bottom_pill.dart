import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_typography.dart';
import 'aura_icon.dart';

/// Floating pill-style toolbar navigation primitive for Aura.
class AuraFloatingBottomPill extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AuraFloatingBottomPill({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progressive Backdrop Blur matching topbar style
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
                    Color(0x66FFFFFF),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ),

          // Translucent Scrim Gradient overlay matching topbar
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceBackground.withValues(alpha: 0.65),
                    AppColors.surfaceBackground.withValues(alpha: 0.40),
                  ],
                ),
                borderRadius: BorderRadius.circular(32.0),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),

          // Floating Pill Row Content (Home, Clips, Library)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: AppIcons.home,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                ),
                const SizedBox(width: 12),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: AppIcons.clips,
                  label: 'Clips',
                  isSelected: currentIndex == 1,
                ),
                const SizedBox(width: 12),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: AppIcons.library,
                  label: 'Library',
                  isSelected: currentIndex == 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPink.withValues(alpha: 0.20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
          border: isSelected
              ? Border.all(
                  color: AppColors.accentPink.withValues(alpha: 0.5),
                  width: 1.0)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuraIcon(
              icon,
              color:
                  isSelected ? AppColors.accentPink : AppColors.textSecondary,
              size: 20,
              fill: isSelected ? 1.0 : 0.0,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: context.auraText.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
