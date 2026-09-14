import 'package:aura/core/presentation/primitives/aura_page_scaffold.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/features/addons/domain/entities/addon_stream.dart';
import 'package:aura/features/addons/presentation/bloc/addon_bloc.dart';
import 'package:aura/features/addons/presentation/bloc/addon_event.dart';
import 'package:aura/features/addons/presentation/bloc/addon_state.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/clips/domain/entities/clip_item.dart';
import 'package:aura/features/clips/presentation/bloc/clips_bloc.dart';
import 'package:aura/features/clips/presentation/bloc/clips_event.dart';
import 'package:aura/features/clips/presentation/bloc/clips_state.dart';
import 'package:aura/features/clips/presentation/widgets/clip_page_item.dart';
import 'package:aura/features/engine/http_debrid_engine.dart';
import 'package:aura/features/library/presentation/bloc/library_bloc.dart';
import 'package:aura/features/library/presentation/bloc/library_event.dart';
import 'package:aura/features/player/presentation/widgets/stream_picker_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Full-screen vertical Netflix-style "Clips & Trailers" screen.
class ClipsScreen extends StatefulWidget {
  const ClipsScreen({super.key});

  @override
  State<ClipsScreen> createState() => _ClipsScreenState();
}

class _ClipsScreenState extends State<ClipsScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    context.read<ClipsBloc>().add(LoadClipsEvent());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openStreamPicker(BuildContext context, MediaItem item) {
    final stremioId = item.getStremioId();
    final addonBloc = context.read<AddonBloc>();
    addonBloc.add(FetchStreamsForMediaEvent(
      type: item.type == MediaType.movie ? 'movie' : 'series',
      id: stremioId,
    ));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return BlocBuilder<AddonBloc, AddonState>(
          bloc: addonBloc,
          builder: (context, addonState) {
            return StreamPickerModal(
              streams: addonState.resolvedStreams,
              isLoading: addonState.isLoadingStreams,
              onStreamSelected: (stream) =>
                  _launchPlayerWithStream(context, item, stream),
            );
          },
        );
      },
    );
  }

  Future<void> _launchPlayerWithStream(
    BuildContext context,
    MediaItem item,
    AddonStream stream,
  ) async {
    final engine = HttpDebridEngine();
    try {
      final rawTarget = stream.url ?? stream.infoHash ?? '';
      final resolved = await engine.resolveStream(
        rawUrlOrInfoHash: rawTarget,
        extraParams: {
          'title': stream.title ?? item.title,
          'quality': stream.resolution,
          'headers': stream.headers,
        },
      );

      if (context.mounted) {
        context.read<LibraryBloc>().add(
              UpdateProgressEvent(
                mediaId: item.id.toString(),
                title: item.title,
                posterPath: item.posterPath,
                backdropPath: item.backdropPath,
                type: item.type.name,
                positionSeconds: 1,
                durationSeconds: (item.runtimeMinutes ?? 120) * 60,
              ),
            );

        await context.push(
          '/player',
          extra: {
            'streamUrl': resolved.streamUrl,
            'title': item.title,
            'subtitle': stream.resolution,
            'headers': resolved.httpHeaders,
            'mediaId': item.id.toString(),
            'posterPath': item.posterPath,
            'backdropPath': item.backdropPath,
            'type': item.type.name,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorAccent,
            content: Text('Failed to start stream: $e'),
          ),
        );
      }
    }
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
                  const Icon(
                    Icons.movie_filter_outlined,
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

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const PageScrollPhysics(),
            itemCount: state.clips.length,
            onPageChanged: (index) {
              context.read<ClipsBloc>().add(ChangeActiveClipIndexEvent(index));
            },
            itemBuilder: (context, index) {
              final clip = state.clips[index];
              final isActive = state.activeIndex == index;
              final isLiked = state.likedClipIds.contains(clip.id);

              return ClipPageItem(
                clip: clip,
                isActive: isActive,
                isMuted: state.isMuted,
                isLiked: isLiked,
                onPlayTap: () => _openStreamPicker(context, clip.mediaItem),
                onShareTap: () => _shareClip(clip),
              );
            },
          );
        },
      ),
    );
  }
}
