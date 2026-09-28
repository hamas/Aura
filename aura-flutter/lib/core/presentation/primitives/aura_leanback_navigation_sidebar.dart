import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_typography.dart';
import 'aura_icon.dart';

/// 10-Foot Leanback Navigation Sidebar for Android TV and widescreen layouts.
/// Provides an auto-expanding navigation rail when focused via remote D-Pad,
/// matching the Netflix TV experience.
class AuraLeanbackNavigationSidebar extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AuraLeanbackNavigationSidebar({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<AuraLeanbackNavigationSidebar> createState() =>
      _AuraLeanbackNavigationSidebarState();
}

class _AuraLeanbackNavigationSidebarState
    extends State<AuraLeanbackNavigationSidebar> {
  bool _isExpanded = false;
  int _focusedIndex = -1;

  final List<_NavDestination> _destinations = const [
    _NavDestination(
      label: 'Search',
      icon: AppIcons.search,
      route: '/search',
    ),
    _NavDestination(
      label: 'Home',
      icon: AppIcons.home,
      route: '/',
    ),
    _NavDestination(
      label: 'Clips',
      icon: AppIcons.clips,
      route: '/clips',
    ),
    _NavDestination(
      label: 'My Library',
      icon: AppIcons.library,
      route: '/library',
    ),
    _NavDestination(
      label: 'Downloads',
      icon: AppIcons.downloads,
      route: '/downloads',
    ),
    _NavDestination(
      label: 'Settings',
      icon: AppIcons.settings,
      route: '/settings',
    ),
  ];

  void _setExpanded(bool expanded) {
    if (_isExpanded != expanded) {
      setState(() => _isExpanded = expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWidescreen = screenWidth >= 900;

    if (!isWidescreen) {
      return widget.child;
    }

    return FocusScope(
      child: Stack(
        children: [
          // 1. Content Area with left offset for compact rail
          Positioned.fill(
            left: 76.0,
            child: widget.child,
          ),

          // 2. Dim Scrim when Expanded over content
          if (_isExpanded)
            Positioned.fill(
              left: 76.0,
              child: GestureDetector(
                onTap: () => _setExpanded(false),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isExpanded ? 0.6 : 0.0,
                  child: Container(color: Colors.black),
                ),
              ),
            ),

          // 3. Collapsible Glassmorphic Sidebar Rail
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: _isExpanded ? 240.0 : 76.0,
            child: MouseRegion(
              onEnter: (_) => _setExpanded(true),
              onExit: (_) {
                if (_focusedIndex == -1) _setExpanded(false);
              },
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBackground.withValues(
                        alpha: _isExpanded ? 0.94 : 0.75,
                      ),
                      border: const Border(
                        right: BorderSide(
                          color: AppColors.borderSubtle,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App Logo Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                              vertical: 20.0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.accentPink,
                                        Color(0xFF8A2BE2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'A',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isExpanded) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'AURA',
                                      style:
                                          context.auraText.titleLarge?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 3.0,
                                              ) ??
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 3.0,
                                                fontSize: 20,
                                              ),
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 12),

                          // Navigation Items
                          Expanded(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _destinations.length,
                              itemBuilder: (context, index) {
                                final dest = _destinations[index];
                                final isSelected =
                                    widget.selectedIndex == index;
                                final isFocused = _focusedIndex == index;

                                return Focus(
                                  onFocusChange: (hasFocus) {
                                    setState(() {
                                      _focusedIndex = hasFocus ? index : -1;
                                      if (hasFocus) _isExpanded = true;
                                    });
                                  },
                                  onKeyEvent: (node, event) {
                                    if (event is KeyDownEvent &&
                                        event.logicalKey ==
                                            LogicalKeyboardKey.arrowRight) {
                                      _setExpanded(false);
                                      return KeyEventResult.ignored;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      widget.onDestinationSelected(index);
                                      context.go(dest.route);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isFocused
                                            ? AppColors.accentPink
                                                .withValues(alpha: 0.25)
                                            : isSelected
                                                ? AppColors.surfaceElevated
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isFocused
                                              ? AppColors.accentPink
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          AuraIcon(
                                            dest.icon,
                                            size: 22,
                                            color: isSelected || isFocused
                                                ? AppColors.accentPink
                                                : AppColors.textMuted,
                                          ),
                                          if (_isExpanded) ...[
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                dest.label,
                                                style: TextStyle(
                                                  color: isSelected || isFocused
                                                      ? Colors.white
                                                      : AppColors.textSecondary,
                                                  fontSize: 14,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.clip,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Bottom Profile / Status
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.surfaceElevated,
                                  child: Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                                if (_isExpanded) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Profile 1',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Standard 4K',
                                          style: context.auraText.caption
                                              .copyWith(
                                            color: AppColors.successAccent,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDestination {
  final String label;
  final IconData icon;
  final String route;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.route,
  });
}
