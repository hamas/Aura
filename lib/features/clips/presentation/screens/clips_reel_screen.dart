import 'package:aura/core/presentation/primitives/primitives.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/features/clips/domain/entities/clip_item.dart';
import 'package:aura/features/clips/presentation/bloc/clips_bloc.dart';
import 'package:aura/features/clips/presentation/bloc/clips_event.dart';
import 'package:aura/features/clips/presentation/bloc/clips_state.dart';
import 'package:aura/features/clips/presentation/widgets/clip_page_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen vertical swipe video reel with 3-Controller Window memory management.
class ClipsReelScreen extends StatefulWidget {
  const ClipsReelScreen({super.key});

  @override
  State<ClipsReelScreen> createState() => _ClipsReelScreenState();
}

class _ClipsReelScreenState extends State<ClipsReelScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  bool _isRouteActive = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    context.read<ClipsBloc>().add(LoadClipsEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      setState(() => _isRouteActive = false);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _isRouteActive = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      body: BlocBuilder<ClipsBloc, ClipsState>(
        builder: (context, state) {
          if (state.status == ClipsStatus.loading && state.clips.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentPink),
            );
          }

          if (state.status == ClipsStatus.failure && state.clips.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuraIcon(
                    AppIcons.clips,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load clips.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPink,
                      foregroundColor: const Color(0xFF0E0F12),
                    ),
                    onPressed: () =>
                        context.read<ClipsBloc>().add(LoadClipsEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.clips.isEmpty) {
            return const Center(
              child: Text(
                'No preview clips available at this moment.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const PageScrollPhysics(),
                itemCount: state.clips.length,
                onPageChanged: (index) {
                  context
                      .read<ClipsBloc>()
                      .add(ChangeActiveClipIndexEvent(index));
                },
                itemBuilder: (context, index) {
                  final clip = state.clips[index];
                  final isActive = _isRouteActive && state.activeIndex == index;
                  final isPreloadNext = state.activeIndex + 1 == index;
                  final isPrevious = state.activeIndex - 1 == index;
                  final inWindow = isActive || isPreloadNext || isPrevious;

                  // 3-Controller Window: Distant items (>1 step away) are disposed
                  if (!inWindow) {
                    return const SizedBox.shrink();
                  }

                  return ClipPageItem(
                    clip: clip,
                    isActive: isActive,
                    isPreloadNext: isPreloadNext,
                    isMuted: state.isMuted,
                    isLiked: state.likedClipIds.contains(clip.id),
                    onShareTap: () => _shareClip(clip),
                  );
                },
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AuraAdaptiveAppBar(
                  title: 'Clips',
                  opacity: 1.0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _shareClip(ClipItem clip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text('Sharing "${clip.title}" preview clip...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
