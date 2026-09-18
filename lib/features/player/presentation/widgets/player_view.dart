import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:aura/features/addons/domain/repositories/addon_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../library/domain/entities/library_item.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../data/services/media_kit_player_service.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import 'aura_glow_backdrop.dart';
import 'player_controls_overlay.dart';

import '../../data/services/chapter_ingestion_service.dart';
import '../../services/pip_service.dart';
import '../../../watch_together/data/services/watch_together_service.dart';
import '../../../watch_together/domain/entities/watch_room_session.dart';
import '../../../watch_together/presentation/widgets/join_create_watch_room_dialog.dart';
import '../../../watch_together/presentation/widgets/watch_together_overlay_hud.dart';

class PlayerView extends StatefulWidget {
  final Map<String, dynamic> args;
  final VoidCallback? onBack;
  final MediaKitPlayerService? playerService; // Optional for unit tests / custom overrides
  final VoidCallback? onNextEpisode;

  const PlayerView({
    super.key,
    required this.args,
    this.onBack,
    this.playerService,
    this.onNextEpisode,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  late final MediaKitPlayerService _playerService;
  late final PlayerBloc _playerBloc;

  Timer? _progressSyncTimer;
  WatchRoomSession? _watchSession;
  WatchTogetherService? _watchService;
  StreamSubscription<WatchSyncEvent>? _syncSubscription;
  bool _dismissedBingeCountdown = false;

  @override
  void initState() {
    super.initState();
    _playerService = widget.playerService ?? MediaKitPlayerService();
    _playerBloc = PlayerBloc(playerService: _playerService);

    // Mobile Hardening: Lock to landscape and hide system status/nav bars
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    debugPrint('🚀 [PlayerView] Mounted successfully with URL: ${widget.args['streamUrl']}');
    debugPrint('DEBUG: [PLAYER_VIEW] Initialized with args: ${widget.args}');

    try {
      _playerService.player.stream.error.listen((e) {
        debugPrint('DEBUG: [PLAYER_VIEW] Error: $e');
      });
      _playerService.player.stream.completed.listen((c) {
        debugPrint('DEBUG: [PLAYER_VIEW] Completed: $c');
      });
    } catch (_) {}

    _startProgressSyncTimer();
    _fetchIntervals();
    _fetchExternalSubtitles();
    _checkResumeProgress();

    // Wait for first frame to ensure Texture widget is mounted to GPU
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final streamUrl = widget.args['streamUrl'] as String? ?? '';
      final title = widget.args['title'] as String?;
      final subtitle = widget.args['subtitle'] as String?;
      final headers = widget.args['headers'] as Map<String, String>?;
      if (streamUrl.isNotEmpty) {
        _playerBloc.add(PlayStreamEvent(
          streamUrl: streamUrl,
          title: title,
          subtitle: subtitle,
          httpHeaders: headers,
        ));
      }
    });
  }

  String? get _mediaId => widget.args['mediaId'] as String?;
  String? get _posterPath => widget.args['posterPath'] as String?;
  String? get _backdropPath => widget.args['backdropPath'] as String?;
  String? get _mediaType => widget.args['type'] as String?;
  int? get _seasonNumber => widget.args['seasonNumber'] as int?;
  int? get _episodeNumber => widget.args['episodeNumber'] as int?;

  Future<void> _fetchExternalSubtitles() async {
    if (_mediaId == null) return;
    try {
      final addonRepo = context.read<AddonRepository>();
      final type = _mediaType ?? 'movie';
      
      String stremioId = _mediaId!;
      if (type == 'series' && _seasonNumber != null && _episodeNumber != null) {
        stremioId = '$_mediaId:$_seasonNumber:$_episodeNumber';
      }

      final subs = await addonRepo.getSubtitles(type: type, id: stremioId);
      if (mounted) {
        for (final sub in subs) {
          unawaited(
            _playerService.addExternalSubtitleTrack(
              url: sub.url,
              language: sub.lang,
              title: '${sub.lang.toUpperCase()} (Addon)',
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _checkResumeProgress() async {
    if (_mediaId == null) return;
    try {
      final libraryBloc = context.read<LibraryBloc>();
      final continueWatching = libraryBloc.state.continueWatching;
      final existing = continueWatching.cast<LibraryItem?>().firstWhere(
            (item) => item?.id == _mediaId,
            orElse: () => null,
          );

      if (existing != null && existing.progress != null) {
        final posSec = existing.progress!.positionSeconds;
        final durSec = existing.progress!.durationSeconds;
        // Prompt/Resume if > 15s and < 92% finished
        if (posSec > 15 && posSec < (durSec * 0.92)) {
          final posDuration = Duration(seconds: posSec);
          final formattedTime = Formatters.formatDuration(posDuration);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surfaceElevated,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Resume from $formattedTime',
                  textColor: AppColors.accentPink,
                  onPressed: () {
                    _playerBloc.add(SeekPositionEvent(posDuration));
                  },
                ),
                content: Text(
                  'Saved watch progress found ($formattedTime)',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchIntervals() async {
    if (_mediaId == null) return;
    try {
      final ingestionService = ChapterIngestionService();
      final intervals = await ingestionService.fetchIntervals(
        imdbId: _mediaId!,
        season: _seasonNumber,
        episode: _episodeNumber,
      );
      if (mounted && intervals.isNotEmpty) {
        _playerBloc.add(SetMediaIntervalsEvent(intervals));
      }
    } catch (_) {}
  }

  Timer? _stallDetectionTimer;
  Duration _lastStallPosition = Duration.zero;
  int _stallSecondsCount = 0;

  void _startProgressSyncTimer() {
    _progressSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _syncProgress();
    });

    _stallDetectionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = _playerService.state;
      if (state.isBuffering) {
        if (state.position == _lastStallPosition) {
          _stallSecondsCount++;
          if (_stallSecondsCount == 15 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surfaceElevated,
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                  label: 'Retry Stream',
                  textColor: AppColors.accentPink,
                  onPressed: () {
                    if (state.currentStreamUrl != null) {
                      _playerBloc.add(PlayStreamEvent(
                        streamUrl: state.currentStreamUrl!,
                        title: state.title,
                        subtitle: state.subtitle,
                      ));
                    }
                  },
                ),
                content: const Text(
                  'Network stream stalled. Connection slow or unstable.',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            );
          }
        } else {
          _lastStallPosition = state.position;
          _stallSecondsCount = 0;
        }
      } else {
        _lastStallPosition = state.position;
        _stallSecondsCount = 0;
      }
    });
  }

  void _syncProgress() {
    if (!mounted || _mediaId == null) return;
    final state = _playerService.state;
    if (!state.isPlaying || state.position.inSeconds <= 0) return;

    try {
      context.read<LibraryBloc>().add(
            UpdateProgressEvent(
              mediaId: _mediaId!,
              title: state.title ?? 'Playing Media',
              posterPath: _posterPath,
              backdropPath: _backdropPath,
              type: _mediaType ?? 'movie',
              positionSeconds: state.position.inSeconds,
              durationSeconds: state.duration.inSeconds > 0
                  ? state.duration.inSeconds
                  : (120 * 60),
              seasonNumber: _seasonNumber,
              episodeNumber: _episodeNumber,
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
    _stallDetectionTimer?.cancel();
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

    _playerBloc.close();
    _playerService.dispose();
    super.dispose();
  }

  Future<void> _openWatchTogetherDialog() async {
    final state = _playerService.state;
    final session = await showDialog<WatchRoomSession>(
      context: context,
      builder: (context) => JoinCreateWatchRoomDialog(
        mediaId: _mediaId ?? 'media_id',
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
      final currentPos = _playerService.state.position;
      final correction = WatchTogetherService.calculateDriftCorrection(
        clientPos: currentPos,
        hostPos: event.position,
      );
      if (correction != null) {
        _playerBloc.add(SeekPositionEvent(correction));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlayerBloc>.value(
      value: _playerBloc,
      child: BlocBuilder<PlayerBloc, dynamic>(
        builder: (context, _) {
          final bloc = _playerBloc;
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
                        controller: _playerService.controller,
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
                  onPictureInPicture: () => PipService.enterPip(),
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
                  onBack: widget.onBack ?? () => Navigator.of(context).pop(),
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

                // Reconnect / Backup Source Fallback HUD Notice Overlay
                if (state.isRetrying)
                  Positioned(
                    top: 54,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.accentPink.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentPink.withValues(alpha: 0.25),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPink),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              state.errorMessage ?? 'Connection interrupted. Switching to backup source...',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Next Episode Glassmorphic Auto-Play Countdown Card Overlay
                if (state.showNextEpisodeCountdown && !_dismissedBingeCountdown)
                  Positioned(
                    bottom: 80,
                    right: 24,
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentPink.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentPink.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accentPink.withValues(alpha: 0.2),
                                ),
                                child: Center(
                                  child: Text(
                                    '${state.remainingCountdownSeconds}',
                                    style: const TextStyle(
                                      color: AppColors.accentPink,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Up Next',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() => _dismissedBingeCountdown = true);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Next Episode (${_seasonNumber != null && _episodeNumber != null ? "S$_seasonNumber E${_episodeNumber! + 1}" : "Episode"})',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: AppColors.accentPink,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (widget.onNextEpisode != null) {
                                      widget.onNextEpisode!();
                                    }
                                  },
                                  child: const Text(
                                    'Play Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
