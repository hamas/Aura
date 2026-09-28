import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:aura/features/addons/domain/repositories/addon_repository.dart';
import '../../../engine/http_debrid_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../library/domain/entities/library_item.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../data/services/media_kit_player_service.dart';
import '../../domain/entities/subtitle_style_config.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import '../../domain/entities/player_state.dart';
import '../subtitles/widgets/subtitle_styling_modal.dart';
import 'aura_glow_backdrop.dart';
import 'components/in_player_episode_drawer.dart';
import 'player_controls_overlay.dart';

import '../../data/services/chapter_ingestion_service.dart';
import '../../services/pip_service.dart';
import '../../../watch_together/data/services/watch_together_service.dart';
import '../../../watch_together/domain/entities/watch_room_session.dart';
import '../../../watch_together/presentation/widgets/join_create_watch_room_dialog.dart';
import '../../../watch_together/presentation/widgets/watch_together_overlay_hud.dart';
import '../../../../core/presentation/primitives/desktop_keyboard_shortcut_handler.dart';

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

  // Netflix-grade Subtitle Customization Config
  SubtitleStyleConfig _subtitleConfig = SubtitleStyleConfig.netflixWhite;

  // Mutable Episode Tracking for In-Player Episode Switching
  late int? _seasonNumber;
  late int? _episodeNumber;

  @override
  void initState() {
    super.initState();
    _seasonNumber = widget.args['seasonNumber'] as int?;
    _episodeNumber = widget.args['episodeNumber'] as int?;

    final streamUrl = widget.args['streamUrl'] as String? ?? '';
    debugPrint('🎬 [PlayerView] Initializing playback with URL: $streamUrl');

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

  void _openSubtitleAppearance() {
    SubtitleStylingModal.show(
      context: context,
      initialConfig: _subtitleConfig,
      onConfigChanged: (newConfig) {
        setState(() => _subtitleConfig = newConfig);
      },
    );
  }

  void _openEpisodeDrawer() {
    final seriesId = int.tryParse(_mediaId ?? '');
    if (_mediaType != 'series' || seriesId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Episodes drawer is only available for series titles.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    InPlayerEpisodeDrawer.show(
      context: context,
      seriesId: seriesId,
      seriesTitle: widget.args['title'] as String? ?? 'Series',
      initialSeason: _seasonNumber ?? 1,
      currentEpisode: _episodeNumber ?? 1,
      totalSeasons: 1,
      onEpisodeSelected: (season, episode, title) async {
        Navigator.of(context).pop();
        await _playSelectedEpisode(season: season, episode: episode, episodeTitle: title);
      },
    );
  }

  Future<void> _playSelectedEpisode({
    required int season,
    required int episode,
    String? episodeTitle,
  }) async {
    setState(() {
      _seasonNumber = season;
      _episodeNumber = episode;
    });

    final seriesTitle = widget.args['title'] as String? ?? 'Series';
    final subtitleText = 'S$season:E$episode • ${episodeTitle ?? "Episode $episode"}';

    // Show buffering / loading notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 3),
          content: Text(
            'Loading $subtitleText...',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    try {
      final stremioId = '$_mediaId:$season:$episode';
      final addonRepo = context.read<AddonRepository>();
      final streams = await addonRepo.getStreams(type: 'series', id: stremioId);

      if (streams.isNotEmpty) {
        final stream = streams.first;
        final rawTarget = stream.url ?? stream.infoHash ?? '';
        final engine = HttpDebridEngine();
        final resolvedUrl = await engine.resolveStream(
          rawUrlOrInfoHash: rawTarget,
          extraParams: {
            'title': stream.title ?? seriesTitle,
            'quality': stream.resolution,
            'headers': stream.headers,
          },
        );

        if (mounted) {
          _playerBloc.add(PlayStreamEvent(
            streamUrl: resolvedUrl.streamUrl,
            title: seriesTitle,
            subtitle: subtitleText,
            httpHeaders: stream.headers,
          ));
        }
      } else {
        // Fallback demo stream if no addon resolved stream
        if (mounted) {
          _playerBloc.add(PlayStreamEvent(
            streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            title: seriesTitle,
            subtitle: subtitleText,
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        _playerBloc.add(PlayStreamEvent(
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          title: seriesTitle,
          subtitle: subtitleText,
        ));
      }
    }

    // Refresh chapter intervals and external subtitles for the new episode
    unawaited(_fetchIntervals());
    unawaited(_fetchExternalSubtitles());
  }

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
      child: BlocBuilder<PlayerBloc, AuraPlayerState>(
        builder: (context, state) {
          final bloc = context.read<PlayerBloc>();
          return DesktopKeyboardShortcutHandler(
            onPlayPause: () => bloc.add(const TogglePlayPauseEvent()),
            onToggleFullscreen: () => bloc.add(ChangeAspectRatioEvent(
                state.fit == BoxFit.cover ? BoxFit.contain : BoxFit.cover)),
            onToggleMute: () => bloc.add(
                SetVolumeEvent(state.volume > 0 ? 0.0 : 100.0)),
            onSkipIntro: () => bloc.add(const SkipCurrentIntervalEvent()),
            onNextEpisode: widget.onNextEpisode,
            onSeekBackward: () => bloc.add(SeekPositionEvent(
                state.position - const Duration(seconds: 10))),
            onSeekForward: () => bloc.add(SeekPositionEvent(
                state.position + const Duration(seconds: 10))),
            onVolumeUp: () => bloc.add(
                SetVolumeEvent((state.volume + 5.0).clamp(0.0, 100.0))),
            onVolumeDown: () => bloc.add(
                SetVolumeEvent((state.volume - 5.0).clamp(0.0, 100.0))),
            onEscape: () => Navigator.of(context).maybePop(),
            child: Scaffold(
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
                  onOpenEpisodeDrawer: _openEpisodeDrawer,
                  onOpenSubtitleAppearance: _openSubtitleAppearance,
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
              ),
            );
          },
        ),
      );
  }
}
