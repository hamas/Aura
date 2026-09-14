import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import 'aura_icon.dart';

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

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          padding:
              widget.padding ?? EdgeInsets.fromLTRB(16, topPadding + 6, 16, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.45, 1.0],
              colors: [
                Color.lerp(
                  const Color(0xCC000000),
                  AppColors.surfaceBackground,
                  opacity,
                )!,
                Color.lerp(
                  const Color(0x66141414),
                  AppColors.surfaceBackground,
                  opacity,
                )!,
                AppColors.surfaceBackground.withValues(alpha: opacity),
              ],
            ),
            boxShadow: opacity > 0.4
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 10),
              ] else if (canPop) ...[
                _buildBackButton(context),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: canPop
                    ? _buildNestedTitle(context)
                    : _buildRootCategories(context),
              ),
              ..._buildActions(context),
            ],
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
        color: Colors.black.withValues(alpha: 0.65),
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
    return Text(
      widget.title ?? '',
      style:
          context.auraText.sectionTitle.copyWith(color: AppColors.textPrimary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
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
          children: widget.categories!.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: AppTokens.spacingSm),
              child: GestureDetector(
                onTap: cat.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: cat.isSelected
                        ? AppColors.accentPink
                        : AppColors.surfaceElevated.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                    border: Border.all(
                      color: cat.isSelected
                          ? AppColors.accentPink
                          : const Color(0x33FFFFFF),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    cat.label,
                    style: context.auraText.caption.copyWith(
                      color: cat.isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          cat.isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Text(
      widget.title ?? 'AURA',
      style:
          context.auraText.sectionTitle.copyWith(color: AppColors.accentPink),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (widget.actions != null) {
      return widget.actions!;
    }

    if (!widget.showDefaultActions) {
      return [];
    }

    return [
      IconButton(
        onPressed: widget.onCastTap ?? () => _showDefaultCastDialog(context),
        icon: const AuraIcon(AppIcons.cast,
            color: AppColors.textPrimary, size: 20),
      ),
      IconButton(
        onPressed: widget.onSearchTap ?? () => context.push('/search'),
        icon: const AuraIcon(AppIcons.search,
            color: AppColors.textPrimary, size: 20),
      ),
      const SizedBox(width: 4),
      GestureDetector(
        onTap: widget.onProfileTap ?? () => context.push('/profiles'),
        child: Builder(
          builder: (context) {
            final authBloc = _tryGetAuthBloc(context);
            final photoUrl = authBloc?.state.user?.photoUrl;
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentPink, width: 1.5),
                color: AppColors.surfaceElevated,
              ),
              child: ClipOval(
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
              ),
            );
          },
        ),
      ),
    ];
  }

  AuthBloc? _tryGetAuthBloc(BuildContext context) {
    try {
      return context.read<AuthBloc>();
    } catch (_) {
      return null;
    }
  }
}
