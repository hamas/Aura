import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../domain/entities/player_state.dart';
import '../../domain/entities/stream_track.dart';

class MediaKitPlayerService {
  late final Player player;
  late final VideoController controller;

  final StreamController<AuraPlayerState> _stateController =
      StreamController<AuraPlayerState>.broadcast();
  AuraPlayerState _currentState = const AuraPlayerState();

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final bool _isTestMode;

  MediaKitPlayerService() : _isTestMode = false {
    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, // 32MB buffer for high-bitrate 4K
        logLevel: MPVLogLevel.warn,
      ),
    );
    controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
        androidAttachSurfaceAfterVideoParameters: true,
        hwdec: 'auto-safe',
      ),
    );

    _setNativeReconnectOptions();
    _listenToPlayerEvents();
  }

  void _setNativeReconnectOptions() {
    try {
      final platform = player.platform;
      if (platform != null) {
        (platform as dynamic).setProperty(
          'user-agent',
          'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        );
        (platform as dynamic).setProperty('demuxer-max-bytes', '33554432'); // 32MB
        (platform as dynamic).setProperty('demuxer-max-back-bytes', '16777216'); // 16MB
        (platform as dynamic).setProperty('network-timeout', '15');
        (platform as dynamic).setProperty('http-header-fields', 'User-Agent: Mozilla/5.0');
        (platform as dynamic).setProperty('reconnect', 'yes');
        (platform as dynamic).setProperty('reconnect-delay-max', '5');
        (platform as dynamic).setProperty('reconnect-streamed', 'yes');
        (platform as dynamic).setProperty('demuxer-readahead-secs', '25');
      }
    } catch (_) {}
  }

  MediaKitPlayerService.test(
      {AuraPlayerState initialState = const AuraPlayerState()})
      : _isTestMode = true,
        _currentState = initialState;

  Stream<AuraPlayerState> get stateStream => _stateController.stream;
  AuraPlayerState get state => _currentState;

  void _emit(AuraPlayerState newState) {
    _currentState = newState;
    _stateController.add(_currentState);
  }

  void _listenToPlayerEvents() {
    _subscriptions.add(
      player.stream.playing.listen((playing) {
        _emit(_currentState.copyWith(
          status: playing ? PlaybackStatus.playing : PlaybackStatus.paused,
        ));
      }),
    );

    _subscriptions.add(
      player.stream.buffering.listen((buffering) {
        if (buffering) {
          // If already playing and position is active, ignore transient buffering signals
          if (player.state.playing && player.state.position > Duration.zero) {
            return;
          }
          _emit(_currentState.copyWith(status: PlaybackStatus.buffering));
        } else if (_currentState.status == PlaybackStatus.buffering) {
          _emit(_currentState.copyWith(
            status: player.state.playing
                ? PlaybackStatus.playing
                : PlaybackStatus.paused,
          ));
        }
      }),
    );

    _subscriptions.add(
      player.stream.position.listen((pos) {
        final isCurrentlyBuffering = _currentState.status == PlaybackStatus.buffering;
        final shouldDismissBuffering = isCurrentlyBuffering && (pos > Duration.zero || player.state.playing);
        
        _emit(_currentState.copyWith(
          position: pos,
          status: shouldDismissBuffering
              ? (player.state.playing ? PlaybackStatus.playing : PlaybackStatus.paused)
              : _currentState.status,
        ));
      }),
    );

    _subscriptions.add(
      player.stream.duration.listen((dur) {
        _emit(_currentState.copyWith(duration: dur));
      }),
    );

    _subscriptions.add(
      player.stream.buffer.listen((buf) {
        _emit(_currentState.copyWith(buffer: buf));
      }),
    );

    _subscriptions.add(
      player.stream.tracks.listen((tracks) {
        final audio = tracks.audio.map((a) {
          return AudioTrackInfo(id: a.id, title: a.title, language: a.language);
        }).toList();

        final subs = tracks.subtitle.map((s) {
          return SubtitleTrackInfo(
              id: s.id, title: s.title, language: s.language);
        }).toList();

        _emit(_currentState.copyWith(
          audioTracks: audio,
          subtitleTracks: subs,
        ));
      }),
    );
  }

  Future<void> openStream({
    required String url,
    String? title,
    String? subtitle,
    Map<String, String>? httpHeaders,
  }) async {
    _emit(_currentState.copyWith(
      status: _currentState.status == PlaybackStatus.retrying
          ? PlaybackStatus.retrying
          : PlaybackStatus.buffering,
      title: title,
      subtitle: subtitle,
      currentStreamUrl: url,
    ));

    final effectiveHeaders = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      if (httpHeaders != null) ...httpHeaders,
    };

    try {
      if (_isTestMode) return;
      await player.open(
        Media(
          url,
          httpHeaders: effectiveHeaders,
        ),
        play: true,
      );
    } catch (e) {
      _emit(_currentState.copyWith(
        status: PlaybackStatus.paused,
      ));
      rethrow;
    }
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> playOrPause() => player.playOrPause();
  Future<void> seek(Duration position) async {
    _emit(_currentState.copyWith(position: position));
    try {
      await player.seek(position);
    } catch (_) {}
  }

  Future<void> setVolume(double volume) {
    _emit(_currentState.copyWith(volume: volume));
    return player.setVolume(volume);
  }

  Future<void> setRate(double rate) {
    _emit(_currentState.copyWith(rate: rate));
    return player.setRate(rate);
  }

  void setFit(BoxFit fit) {
    _emit(_currentState.copyWith(fit: fit));
  }

  Future<void> selectAudioTrack(AudioTrackInfo track) async {
    final nativeTrack = AudioTrack(track.id, track.title, track.language);
    await player.setAudioTrack(nativeTrack);
    _emit(_currentState.copyWith(selectedAudioTrack: track));
  }

  Future<void> addExternalSubtitleTrack({
    required String url,
    required String language,
    String? title,
  }) async {
    final trackId = 'ext_$url';
    final newTrack = SubtitleTrackInfo(
      id: trackId,
      title: title ?? language,
      language: language,
      isExternal: true,
      uri: url,
    );

    final updatedSubs = List<SubtitleTrackInfo>.from(_currentState.subtitleTracks);
    if (!updatedSubs.any((s) => s.id == trackId)) {
      updatedSubs.add(newTrack);
      _emit(_currentState.copyWith(subtitleTracks: updatedSubs));
    }
  }

  Future<void> selectSubtitleTrack(SubtitleTrackInfo? track) async {
    if (track == null) {
      if (!_isTestMode) {
        await player.setSubtitleTrack(SubtitleTrack.no());
      }
      _emit(_currentState.copyWith(selectedSubtitleTrack: null));
    } else if (track.isExternal && track.uri != null) {
      if (!_isTestMode) {
        await player.setSubtitleTrack(
          SubtitleTrack.uri(
            track.uri!,
            title: track.title ?? track.language ?? 'External Subtitle',
            language: track.language,
          ),
        );
      }
      _emit(_currentState.copyWith(selectedSubtitleTrack: track));
    } else {
      if (!_isTestMode) {
        final nativeTrack = SubtitleTrack(track.id, track.title, track.language);
        await player.setSubtitleTrack(nativeTrack);
      }
      _emit(_currentState.copyWith(selectedSubtitleTrack: track));
    }
  }

  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await player.dispose();
    await _stateController.close();
  }
}
