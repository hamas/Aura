import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/player_state.dart';
import '../../domain/entities/stream_track.dart';

class PlayerControlsOverlay extends StatefulWidget {
  final AuraPlayerState state;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<BoxFit> onAspectRatioChange;
  final ValueChanged<double> onSpeedChange;
  final ValueChanged<AudioTrackInfo> onSelectAudioTrack;
  final ValueChanged<SubtitleTrackInfo?> onSelectSubtitleTrack;
  final VoidCallback onBack;

  const PlayerControlsOverlay({
    super.key,
    required this.state,
    required this.onPlayPause,
    required this.onSeek,
    required this.onAspectRatioChange,
    required this.onSpeedChange,
    required this.onSelectAudioTrack,
    required this.onSelectSubtitleTrack,
    required this.onBack,
  });

  @override
  State<PlayerControlsOverlay> createState() => _PlayerControlsOverlayState();
}

class _PlayerControlsOverlayState extends State<PlayerControlsOverlay> {
  bool _isVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (widget.state.isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _isVisible = false);
        }
      });
    }
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
    if (_isVisible) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleVisibility,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !_isVisible,
          child: Container(
            color: Colors.black.withAlpha((0.55 * 255).round()),
            child: SafeArea(
              child: Stack(
                children: [
                  // Top Bar
                  Align(
                    alignment: Alignment.topCenter,
                    child: _buildTopBar(context),
                  ),

                  // Center Controls (Rewind, Play/Pause, Forward)
                  Align(
                    alignment: Alignment.center,
                    child: _buildCenterControls(),
                  ),

                  // Bottom Controls (Timeline, Aspect Ratio, Tracks)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildBottomBar(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.state.title ?? 'Aura Player',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.state.subtitle != null)
                  Text(
                    widget.state.subtitle!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Aspect Ratio Toggle
          IconButton(
            icon: const Icon(Icons.aspect_ratio, color: Colors.white),
            tooltip: 'Aspect Ratio',
            onPressed: () {
              final nextFit = widget.state.fit == BoxFit.contain
                  ? BoxFit.cover
                  : widget.state.fit == BoxFit.cover
                      ? BoxFit.fill
                      : BoxFit.contain;
              widget.onAspectRatioChange(nextFit);
            },
          ),
          // Subtitle Track Selector
          IconButton(
            icon: const Icon(Icons.subtitles_outlined, color: Colors.white),
            tooltip: 'Subtitles',
            onPressed: () => _showSubtitlePicker(context),
          ),
          // Audio Track Selector
          IconButton(
            icon: const Icon(Icons.audiotrack_outlined, color: Colors.white),
            tooltip: 'Audio Tracks',
            onPressed: () => _showAudioPicker(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    if (widget.state.isBuffering) {
      return const CircularProgressIndicator(
        color: AppTheme.primaryAccent,
        strokeWidth: 3.5,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 10s
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.replay_10, color: Colors.white),
          onPressed: () {
            final target = widget.state.position - const Duration(seconds: 10);
            widget.onSeek(target < Duration.zero ? Duration.zero : target);
            _startHideTimer();
          },
        ),
        const SizedBox(width: 32),
        // Play / Pause
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withAlpha((0.9 * 255).round()),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryAccent.withAlpha((0.4 * 255).round()),
                blurRadius: 16,
              ),
            ],
          ),
          child: IconButton(
            iconSize: 48,
            icon: Icon(
              widget.state.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              widget.onPlayPause();
              _startHideTimer();
            },
          ),
        ),
        const SizedBox(width: 32),
        // Forward 10s
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.forward_10, color: Colors.white),
          onPressed: () {
            final target = widget.state.position + const Duration(seconds: 10);
            widget.onSeek(target > widget.state.duration ? widget.state.duration : target);
            _startHideTimer();
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final pos = widget.state.position;
    final dur = widget.state.duration;
    final maxSec = dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0;
    final curSec = pos.inSeconds.toDouble().clamp(0.0, maxSec);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                Formatters.formatDuration(pos),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: AppTheme.primaryAccent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.primaryAccent,
                  ),
                  child: Slider(
                    value: curSec,
                    min: 0.0,
                    max: maxSec,
                    onChanged: (val) {
                      _startHideTimer();
                      widget.onSeek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),
              ),
              Text(
                Formatters.formatDuration(dur),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSubtitlePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Subtitles', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('Off'),
              trailing: widget.state.selectedSubtitleTrack == null
                  ? const Icon(Icons.check, color: AppTheme.primaryAccent)
                  : null,
              onTap: () {
                widget.onSelectSubtitleTrack(null);
                Navigator.pop(context);
              },
            ),
            ...widget.state.subtitleTracks.map((s) {
              final isSelected = widget.state.selectedSubtitleTrack?.id == s.id;
              return ListTile(
                title: Text(s.title ?? s.language ?? 'Track ${s.id}'),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.primaryAccent)
                    : null,
                onTap: () {
                  widget.onSelectSubtitleTrack(s);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }

  void _showAudioPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Audio Tracks', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...widget.state.audioTracks.map((a) {
              final isSelected = widget.state.selectedAudioTrack?.id == a.id;
              return ListTile(
                title: Text(a.title ?? a.language ?? 'Audio Track ${a.id}'),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.primaryAccent)
                    : null,
                onTap: () {
                  widget.onSelectAudioTrack(a);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }
}
