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

  MediaKitPlayerService() {
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
      ),
    );

    _listenToPlayerEvents();
  }

  MediaKitPlayerService.test(
      {AuraPlayerState initialState = const AuraPlayerState()})
      : _currentState = initialState;

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
        _emit(_currentState.copyWith(position: pos));
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
      status: PlaybackStatus.buffering,
      title: title,
      subtitle: subtitle,
      currentStreamUrl: url,
    ));

    await player.open(
      Media(
        url,
        httpHeaders: httpHeaders,
      ),
      play: true,
    );
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

  Future<void> selectSubtitleTrack(SubtitleTrackInfo? track) async {
    if (track == null) {
      await player.setSubtitleTrack(SubtitleTrack.no());
      _emit(_currentState.copyWith(selectedSubtitleTrack: null));
    } else {
      final nativeTrack = SubtitleTrack(track.id, track.title, track.language);
      await player.setSubtitleTrack(nativeTrack);
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
