import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';
import '../../constants/app_assets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import 'aura_icon.dart';

/// Data model representing a category filter pill in [AuraAdaptiveAppBar].
class AuraCategoryPill {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AuraCategoryPill({
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });
}

/// Netflix-style cinematic adaptive header with "A" brand glyph.
///
/// Dynamically adapts between:
/// 1. **Root State (`canPop == false`)**: Displays the 34px "A" brand glyph,
///    adjacent category switcher pills ("TV Shows", "Movies", "Categories ▾"),
///    and right-side action buttons (Cast, Search, Profile Avatar).
/// 2. **Nested / Pushed Route State (`canPop == true`)**:
///    Displays an authentic Netflix-style header with standard back navigation
///    back button (`AppIcons.arrowBackIosNew`), nested view title, and
///    search/action buttons.
/// 3. **Scroll Transparency**: Interpolates background from 100% transparent at offset 0.0
///    to solid `#141414` past offset > 50.0.
class AuraAdaptiveAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final ScrollController? scrollController;
  final double? scrollOffset;
  final double? opacity;
  final double maxScrollOffset;
  final bool? forceCanPop;
  final VoidCallback? onBackPressed;
  final List<AuraCategoryPill>? categories;
  final Widget? categorySwitcher;
  final List<Widget>? actions;
  final bool showDefaultActions;
  final VoidCallback? onCastTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  final double glyphHeight;
  final Widget? leading;
  final EdgeInsetsGeometry? padding;

  const AuraAdaptiveAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.scrollController,
    this.scrollOffset,
    this.opacity,
    this.maxScrollOffset = 50.0,
    this.forceCanPop,
    this.onBackPressed,
    this.categories,
    this.categorySwitcher,
    this.actions,
    this.showDefaultActions = true,
    this.onCastTap,
    this.onSearchTap,
    this.onProfileTap,
    this.glyphHeight = 34.0,
    this.leading,
    this.padding,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  State<AuraAdaptiveAppBar> createState() => _AuraAdaptiveAppBarState();
}

class _AuraAdaptiveAppBarState extends State<AuraAdaptiveAppBar> {
  double _internalOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_handleScroll);
      _updateOpacityFromController();
    }
  }

  @override
  void didUpdateWidget(AuraAdaptiveAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_handleScroll);
      widget.scrollController?.addListener(_handleScroll);
      _updateOpacityFromController();
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    _updateOpacityFromController();
  }

  void _updateOpacityFromController() {
    if (widget.scrollController == null ||
        !widget.scrollController!.hasClients) {
      return;
    }
    final offset = widget.scrollController!.offset;
    final target = (offset / widget.maxScrollOffset).clamp(0.0, 1.0);
    if ((target - _internalOpacity).abs() > 0.01) {
      setState(() {
        _internalOpacity = target;
      });
    }
  }

  double get _currentOpacity {
    if (widget.opacity != null) {
      return widget.opacity!.clamp(0.0, 1.0);
    }
    if (widget.scrollOffset != null) {
      return (widget.scrollOffset! / widget.maxScrollOffset).clamp(0.0, 1.0);
    }
    if (widget.scrollController != null) {
      return _internalOpacity;
    }
    return 1.0;
  }

  bool _evaluateCanPop(BuildContext context) {
    if (widget.forceCanPop != null) {
      return widget.forceCanPop!;
    }
    final modalRoute = ModalRoute.of(context);
    final canPopRoute = modalRoute?.canPop ?? false;
    return canPopRoute || Navigator.of(context).canPop();
  }

  void _showDefaultCastDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Row(
          children: [
            AuraIcon(AppIcons.cast, color: AppColors.accentPink),
            SizedBox(width: 10),
            Text(
              'Connect Device',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Searching for available Chromecast, Android TV, and DLNA display targets on your local network...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.accentPink),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = _evaluateCanPop(context);
    final opacity = _currentOpacity;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding:
          widget.padding ?? EdgeInsets.fromLTRB(14, topPadding + 6, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground.withAlpha((opacity * 255).round()),
        boxShadow: opacity > 0.4
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha((0.65 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Leading Section: Back Button (Nested) OR "A" Brand Glyph (Root)
          if (widget.leading != null)
            widget.leading!
          else if (canPop)
            _buildBackButton(context)
          else
            _buildAuraGlyph(context),

          const SizedBox(width: 10),

          // Center/Title Section: Category Switcher (Root) OR View Title (Nested)
          Expanded(
            child: canPop
                ? _buildNestedTitle(context)
                : _buildRootCategories(context),
          ),

          // Actions Section (Right)
          ..._buildActions(context),
        ],
      ),
    );
  }

  Widget _buildAuraGlyph(BuildContext context) {
    return Image.asset(
      AppAssets.auraGlyph,
      height: widget.glyphHeight,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        height: widget.glyphHeight,
        width: widget.glyphHeight * 0.75,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accentPink.withAlpha(50),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'A',
          style: TextStyle(
            color: AppColors.accentPink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.65 * 255).round()),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const AuraIcon(
          AppIcons.back,
          color: Colors.white,
          size: 18,
        ),
        onPressed: widget.onBackPressed ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildNestedTitle(BuildContext context) {
    if (widget.titleWidget != null) {
      return widget.titleWidget!;
    }
    if (widget.title != null && widget.title!.isNotEmpty) {
      return Text(
        widget.title!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.auraText.sectionTitle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildRootCategories(BuildContext context) {
    if (widget.categorySwitcher != null) {
      return widget.categorySwitcher!;
    }
    if (widget.categories != null && widget.categories!.isNotEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: widget.categories!.map((pill) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryPill(pill),
            );
          }).toList(),
        ),
      );
    }
    if (widget.titleWidget != null) {
      return widget.titleWidget!;
    }
    if (widget.title != null && widget.title!.isNotEmpty) {
      return Text(
        widget.title!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.auraText.sectionTitle,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCategoryPill(AuraCategoryPill pill) {
    return GestureDetector(
      onTap: pill.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: pill.isSelected
              ? AppColors.accentPink
              : AppColors.surfaceElevated.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pill.isSelected
                ? AppColors.accentPink
                : Colors.white.withAlpha(30),
            width: 1,
          ),
        ),
        child: Text(
          pill.label,
          style: TextStyle(
            color: pill.isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: pill.isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (widget.actions != null) {
      return widget.actions!;
    }
    if (!widget.showDefaultActions) {
      return const [];
    }

    return [
      // Cast Action Icon
      IconButton(
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
        onPressed: widget.onCastTap ?? () => _showDefaultCastDialog(context),
        icon: const AuraIcon(
          AppIcons.cast,
          color: AppColors.textPrimary,
          size: 22,
        ),
        tooltip: 'Cast screen',
      ),
      const SizedBox(width: 4),

      // Search Action Icon
      IconButton(
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
        onPressed: widget.onSearchTap ?? () => context.push('/search'),
        icon: const AuraIcon(
          AppIcons.search,
          color: AppColors.textPrimary,
          size: 23,
        ),
        tooltip: 'Search media',
      ),
      const SizedBox(width: 8),

      // Profile Avatar Action
      _buildProfileAvatar(context),
    ];
  }

  Widget _buildProfileAvatar(BuildContext context) {
    AuthState? authState;
    try {
      authState = context.watch<AuthBloc>().state;
    } catch (_) {
      authState = null;
    }

    final user = authState?.user;
    final isAuthenticated = authState?.isAuthenticated ?? false;

    return GestureDetector(
      onTap: widget.onProfileTap ?? () => context.push('/settings'),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppTokens.borderRadiusSmall,
          border: Border.all(
            color: isAuthenticated
                ? AppColors.accentPink
                : const Color(0xFF333333),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall - 1),
          child: user?.photoUrl != null
              ? CachedNetworkImage(
                  imageUrl: user!.photoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceElevated,
                  ),
                  errorWidget: (_, __, ___) => const AuraIcon(
                    AppIcons.person,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                )
              : const AuraIcon(
                  AppIcons.person,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
        ),
      ),
    );
  }
}
