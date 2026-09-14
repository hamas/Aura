import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
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
          // 8 Blur Background (50% reduction)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: const SizedBox.expand(),
            ),
          ),

          // 20% Background Color Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceBackground.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(32.0),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),

          // Icon-Only Floating Pill Toolbar Items (Home, Clips, Library)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: AppIcons.home,
                  isSelected: currentIndex == 0,
                ),
                const SizedBox(width: 28),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: AppIcons.clips,
                  isSelected: currentIndex == 1,
                ),
                const SizedBox(width: 28),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: AppIcons.downloads,
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
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AuraIcon(
          icon,
          color: isSelected ? Colors.white : AppColors.textSecondary,
          size: 24,
          fill: isSelected ? 1.0 : 0.0,
        ),
      ),
    );
  }
}
