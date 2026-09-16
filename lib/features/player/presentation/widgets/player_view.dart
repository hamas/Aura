import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../data/services/media_kit_player_service.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import 'aura_glow_backdrop.dart';
import 'player_controls_overlay.dart';

import '../../data/services/chapter_ingestion_service.dart';
import '../../../watch_together/data/services/watch_together_service.dart';
import '../../../watch_together/domain/entities/watch_room_session.dart';
import '../../../watch_together/presentation/widgets/join_create_watch_room_dialog.dart';
import '../../../watch_together/presentation/widgets/watch_together_overlay_hud.dart';

class PlayerView extends StatefulWidget {
  final MediaKitPlayerService playerService;
  final VoidCallback onBack;
  final String? mediaId;
  final String? posterPath;
  final String? backdropPath;
  final String? mediaType;
  final int? seasonNumber;
  final int? episodeNumber;
  final VoidCallback? onNextEpisode;

  const PlayerView({
    super.key,
    required this.playerService,
    required this.onBack,
    this.mediaId,
    this.posterPath,
    this.backdropPath,
    this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
    this.onNextEpisode,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  Timer? _progressSyncTimer;
  WatchRoomSession? _watchSession;
  WatchTogetherService? _watchService;
  StreamSubscription<WatchSyncEvent>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    // Mobile Hardening: Lock to landscape and hide system status/nav bars
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _startProgressSyncTimer();
    _fetchIntervals();
  }

  Future<void> _fetchIntervals() async {
    if (widget.mediaId == null) return;
    try {
      final ingestionService = ChapterIngestionService();
      final intervals = await ingestionService.fetchIntervals(
        imdbId: widget.mediaId!,
        season: widget.seasonNumber,
        episode: widget.episodeNumber,
      );
      if (mounted && intervals.isNotEmpty) {
        context.read<PlayerBloc>().add(SetMediaIntervalsEvent(intervals));
      }
    } catch (_) {}
  }

  void _startProgressSyncTimer() {
    _progressSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _syncProgress();
    });
  }

  void _syncProgress() {
    if (!mounted || widget.mediaId == null) return;
    final state = widget.playerService.state;
    if (!state.isPlaying || state.position.inSeconds <= 0) return;

    try {
      context.read<LibraryBloc>().add(
            UpdateProgressEvent(
              mediaId: widget.mediaId!,
              title: state.title ?? 'Playing Media',
              posterPath: widget.posterPath,
              backdropPath: widget.backdropPath,
              type: widget.mediaType ?? 'movie',
              positionSeconds: state.position.inSeconds,
              durationSeconds: state.duration.inSeconds > 0
                  ? state.duration.inSeconds
                  : (120 * 60),
              seasonNumber: widget.seasonNumber,
              episodeNumber: widget.episodeNumber,
            ),
          );
    } catch (_) {
      // Ignore if LibraryBloc is unavailable in test harnesses
    }
  }

  @override
  void dispose() {
    _syncProgress(); // Final sync before exiting player
    _progressSyncTimer?.cancel();
    _syncSubscription?.cancel();
    _watchService?.dispose();

    // Mobile Hardening: Restore system orientations and edge-to-edge UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  Future<void> _openWatchTogetherDialog() async {
    final state = widget.playerService.state;
    final session = await showDialog<WatchRoomSession>(
      context: context,
      builder: (context) => JoinCreateWatchRoomDialog(
        mediaId: widget.mediaId ?? 'media_id',
        streamUrl: state.currentStreamUrl ?? '',
      ),
    );

    if (session != null && mounted) {
      setState(() => _watchSession = session);
      _watchService = WatchTogetherService();
      _subscribeToWatchTogether();
    }
  }

  void _subscribeToWatchTogether() {
    if (_watchService == null) return;
    _syncSubscription = _watchService!.eventStream.listen((event) {
      if (!mounted) return;
      final currentPos = widget.playerService.state.position;
      final correction = WatchTogetherService.calculateDriftCorrection(
        clientPos: currentPos,
        hostPos: event.position,
      );
      if (correction != null) {
        context.read<PlayerBloc>().add(SeekPositionEvent(correction));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, dynamic>(
      builder: (context, _) {
        final bloc = context.read<PlayerBloc>();
        final state = bloc.state;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Ambient Aura Glow Dynamic Backlight Surface
              AuraGlowBackdrop(
                isEnabled: state.enableAuraGlow,
                isPlaying: state.isPlaying,
                position: state.position,
                fit: state.fit,
              ),

              // Hardware-accelerated Video Surface
              SizedBox.expand(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Video(
                      controller: widget.playerService.controller,
                      fit: state.fit,
                      controls: (state) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // Cinematic Gesture Overlay Controls
              PlayerControlsOverlay(
                state: state,
                onPlayPause: () => bloc.add(const TogglePlayPauseEvent()),
                onSeek: (pos) => bloc.add(SeekPositionEvent(pos)),
                onAspectRatioChange: (fit) =>
                    bloc.add(ChangeAspectRatioEvent(fit)),
                onSpeedChange: (speed) =>
                    bloc.add(SetPlaybackSpeedEvent(speed)),
                onSelectAudioTrack: (track) =>
                    bloc.add(SelectAudioTrackEvent(track)),
                onSelectSubtitleTrack: (track) =>
                    bloc.add(SelectSubtitleTrackEvent(track)),
                onSelectSecondarySubtitleTrack: (track) =>
                    bloc.add(SelectSecondarySubtitleTrackEvent(track)),
                onSubtitleOffsetChanged: (val) =>
                    bloc.add(SetSubtitleOffsetEvent(val)),
                onNudgeSubtitleOffset: (delta) =>
                    bloc.add(NudgeSubtitleOffsetEvent(delta)),
                onVolumeChange: (vol) => bloc.add(SetVolumeEvent(vol)),
                onToggleAuraGlow: () => bloc.add(const ToggleAuraGlowEvent()),
                onSkipInterval: () =>
                    bloc.add(const SkipCurrentIntervalEvent()),
                onNextEpisode: widget.onNextEpisode,
                onWatchTogether: _openWatchTogetherDialog,
                onRetryStream: () {
                  if (state.currentStreamUrl != null) {
                    bloc.add(PlayStreamEvent(
                      streamUrl: state.currentStreamUrl!,
                      title: state.title,
                      subtitle: state.subtitle,
                    ));
                  }
                },
                onBack: widget.onBack,
              ),

              // Watch Together Synchronized Multi-User Overlay HUD
              if (_watchSession != null)
                WatchTogetherOverlayHUD(
                  session: _watchSession!,
                  onSendReaction: (emoji) {
                    _watchService?.broadcastEvent(WatchSyncEvent(
                      type: WatchSyncEventType.reaction,
                      senderId: _watchService?.currentUserId ?? 'user',
                      position: state.position,
                      timestamp: DateTime.now(),
                      payload: emoji,
                    ));
                  },
                  onToggleHostControl: (val) {
                    _watchService?.toggleHostOnlyControl(val);
                  },
                  onLeaveRoom: () {
                    _watchService?.leaveRoom();
                    setState(() => _watchSession = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
