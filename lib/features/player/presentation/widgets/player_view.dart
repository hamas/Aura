import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../data/services/media_kit_player_service.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_event.dart';
import 'player_controls_overlay.dart';

class PlayerView extends StatelessWidget {
  final MediaKitPlayerService playerService;
  final VoidCallback onBack;

  const PlayerView({
    super.key,
    required this.playerService,
    required this.onBack,
  });

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
              // Hardware-accelerated Video Surface
              Center(
                child: Video(
                  controller: playerService.controller,
                  fit: state.fit,
                  controls: (state) => const SizedBox.shrink(),
                ),
              ),

              // Cinematic Gesture Overlay Controls
              PlayerControlsOverlay(
                state: state,
                onPlayPause: () => bloc.add(TogglePlayPauseEvent()),
                onSeek: (pos) => bloc.add(SeekPositionEvent(pos)),
                onAspectRatioChange: (fit) => bloc.add(ChangeAspectRatioEvent(fit)),
                onSpeedChange: (speed) => bloc.add(SetPlaybackSpeedEvent(speed)),
                onSelectAudioTrack: (track) => bloc.add(SelectAudioTrackEvent(track)),
                onSelectSubtitleTrack: (track) => bloc.add(SelectSubtitleTrackEvent(track)),
                onBack: onBack,
              ),
            ],
          ),
        );
      },
    );
  }
}
