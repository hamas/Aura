import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/deep_link_service.dart';
import '../../../features/addons/presentation/bloc/addon_bloc.dart';
import '../../../features/addons/presentation/bloc/addon_state.dart';
import 'aura_floating_bottom_pill.dart';

class MainNavigationScaffold extends StatefulWidget {
  final Widget child;

  const MainNavigationScaffold({super.key, required this.child});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  late final DeepLinkService _deepLinkService;

  @override
  void initState() {
    super.initState();
    _deepLinkService = DeepLinkService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addonBloc = context.read<AddonBloc>();
      _deepLinkService.init(addonBloc);
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/clips')) {
      return 1;
    }
    if (location.startsWith('/downloads') || location.startsWith('/library')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/clips');
        break;
      case 2:
        context.go('/downloads');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalBottomBlurHeight = bottomPadding + 100.0;

    return BlocListener<AddonBloc, AddonState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.successMessage != current.successMessage ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.accentPink,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.status == AddonStatus.failure &&
            state.errorMessage != null &&
            state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.surfaceBackground,
        body: Stack(
          children: [
            Positioned.fill(child: widget.child),

            // Bottom Bar Background Blur Overlay (matching top bar!)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: totalBottomBlurHeight,
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0x99FFFFFF),
                              Color(0x00FFFFFF),
                            ],
                            stops: [0.0, 0.60, 1.0],
                          ).createShader(bounds);
                        },
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                          child: const ColoredBox(color: Colors.black),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.surfaceBackground.withValues(alpha: 0.51),
                              AppColors.surfaceBackground.withValues(alpha: 0.21),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.60, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Pill Toolbar
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding + 8,
              child: Center(
                child: AuraFloatingBottomPill(
                  currentIndex: currentIndex,
                  onTap: (idx) => _onItemTapped(idx, context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
