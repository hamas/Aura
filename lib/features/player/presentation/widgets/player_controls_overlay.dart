import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/media_interval.dart';
import '../../domain/entities/player_state.dart';
import '../../domain/entities/stream_track.dart';
import 'components/player_bottom_control_bar.dart';
import 'components/player_gesture_feedback_overlay.dart';
import 'components/player_top_control_bar.dart';
import 'components/player_track_pickers.dart';
import 'skip_interval_pill.dart';

class PlayerControlsOverlay extends StatefulWidget {
  final AuraPlayerState state;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<BoxFit> onAspectRatioChange;
  final ValueChanged<double> onSpeedChange;
  final ValueChanged<AudioTrackInfo> onSelectAudioTrack;
  final ValueChanged<SubtitleTrackInfo?> onSelectSubtitleTrack;
  final ValueChanged<SubtitleTrackInfo?>? onSelectSecondarySubtitleTrack;
  final ValueChanged<double>? onSubtitleOffsetChanged;
  final ValueChanged<double>? onNudgeSubtitleOffset;
  final ValueChanged<double>? onVolumeChange;
  final VoidCallback? onPictureInPicture;
  final VoidCallback? onToggleAuraGlow;
  final VoidCallback? onSkipInterval;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onWatchTogether;
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
    this.onSelectSecondarySubtitleTrack,
    this.onSubtitleOffsetChanged,
    this.onNudgeSubtitleOffset,
    this.onVolumeChange,
    this.onPictureInPicture,
    this.onToggleAuraGlow,
    this.onSkipInterval,
    this.onNextEpisode,
    this.onWatchTogether,
    required this.onBack,
  });

  @override
  State<PlayerControlsOverlay> createState() => _PlayerControlsOverlayState();
}

class _PlayerControlsOverlayState extends State<PlayerControlsOverlay>
    with SingleTickerProviderStateMixin {
  bool _isVisible = true;
  Timer? _hideTimer;

  // Double-tap seek animation states
  bool _showLeftSeekRipple = false;
  bool _showRightSeekRipple = false;
  Timer? _leftSeekTimer;
  Timer? _rightSeekTimer;

  // Gesture state indicators
  double _currentBrightness = 0.5;
  bool _showBrightnessHud = false;
  Timer? _brightnessHudTimer;

  double _currentVolume = 100.0;
  bool _showVolumeHud = false;
  Timer? _volumeHudTimer;

  // Horizontal scrub gesture state
  bool _isScrubbing = false;
  Duration _scrubTarget = Duration.zero;
  Duration _scrubOffset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentVolume = widget.state.volume;
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

  void _handleDoubleTapLeft() {
    final target = widget.state.position - const Duration(seconds: 10);
    widget.onSeek(target < Duration.zero ? Duration.zero : target);

    setState(() {
      _showLeftSeekRipple = true;
    });
    _leftSeekTimer?.cancel();
    _leftSeekTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _showLeftSeekRipple = false);
      }
    });
  }

  void _handleDoubleTapRight() {
    final target = widget.state.position + const Duration(seconds: 10);
    widget.onSeek(
        target > widget.state.duration ? widget.state.duration : target);

    setState(() {
      _showRightSeekRipple = true;
    });
    _rightSeekTimer?.cancel();
    _rightSeekTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _showRightSeekRipple = false);
      }
    });
  }

  void _onVerticalDragUpdate(
      DragUpdateDetails details, double screenWidth, double screenHeight) {
    final isLeft = details.globalPosition.dx < screenWidth / 2;
    final delta =
        -details.primaryDelta! / screenHeight; // inverted drag: up = increase

    if (isLeft) {
      setState(() {
        _currentBrightness = (_currentBrightness + delta).clamp(0.0, 1.0);
        _showBrightnessHud = true;
      });
      _brightnessHudTimer?.cancel();
      _brightnessHudTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showBrightnessHud = false);
      });
    } else {
      setState(() {
        _currentVolume = (_currentVolume + (delta * 100)).clamp(0.0, 100.0);
        _showVolumeHud = true;
      });
      widget.onVolumeChange?.call(_currentVolume);
      _volumeHudTimer?.cancel();
      _volumeHudTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showVolumeHud = false);
      });
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isScrubbing = true;
      _scrubTarget = widget.state.position;
      _scrubOffset = Duration.zero;
    });
    _hideTimer?.cancel();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double screenWidth) {
    final totalSeconds = widget.state.duration.inSeconds > 0
        ? widget.state.duration.inSeconds
        : 7200;
    final scrubDeltaSeconds = (details.primaryDelta! / screenWidth) * 90;
    final newOffsetSeconds = _scrubOffset.inSeconds + scrubDeltaSeconds;

    final newTargetSeconds =
        (widget.state.position.inSeconds + newOffsetSeconds).clamp(
      0.0,
      totalSeconds.toDouble(),
    );

    setState(() {
      _scrubOffset = Duration(seconds: newOffsetSeconds.toInt());
      _scrubTarget = Duration(seconds: newTargetSeconds.toInt());
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isScrubbing) {
      widget.onSeek(_scrubTarget);
      setState(() {
        _isScrubbing = false;
      });
      _startHideTimer();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _leftSeekTimer?.cancel();
    _rightSeekTimer?.cancel();
    _brightnessHudTimer?.cancel();
    _volumeHudTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Gesture Detector Zone
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleVisibility,
            onVerticalDragUpdate: (details) =>
                _onVerticalDragUpdate(details, size.width, size.height),
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: (details) =>
                _onHorizontalDragUpdate(details, size.width),
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: _handleDoubleTapLeft,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                const SizedBox(width: 80),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: _handleDoubleTapRight,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Visual Feedback for Gestures (Seek ripples, Volume/Brightness HUDs, Scrub preview)
        PlayerGestureFeedbackOverlay(
          showLeftSeekRipple: _showLeftSeekRipple,
          showRightSeekRipple: _showRightSeekRipple,
          showBrightnessHud: _showBrightnessHud,
          currentBrightness: _currentBrightness,
          showVolumeHud: _showVolumeHud,
          currentVolume: _currentVolume,
          isScrubbing: _isScrubbing,
          scrubOffset: _scrubOffset,
          scrubTarget: _scrubTarget,
          size: size,
          formatDuration: Formatters.formatDuration,
        ),

        // Smart Skip Interval Animated Pill Overlay (Bottom Right)
        if (widget.state.activeInterval != null &&
            (widget.state.activeInterval!.type == MediaIntervalType.intro ||
                widget.state.activeInterval!.type == MediaIntervalType.recap))
          Positioned(
            right: AppTokens.spacingLg,
            bottom: 84,
            child: SkipIntervalPill(
              interval: widget.state.activeInterval!,
              onSkip: () => widget.onSkipInterval?.call(),
            ),
          ),

        // Next Episode Auto-Trigger Countdown Overlay (Bottom Right during Credits)
        if (widget.state.activeInterval != null &&
            widget.state.activeInterval!.type == MediaIntervalType.credits &&
            widget.onNextEpisode != null)
          Positioned(
            right: AppTokens.spacingLg,
            bottom: 84,
            child: NextEpisodeCountdownCard(
              onPlayNext: () => widget.onNextEpisode?.call(),
              onDismiss: () {},
            ),
          ),

        // Top, Center & Bottom Overlay Controls (Faded on Inactivity)
        AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: !_isVisible,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceBackground.withAlpha((0.75 * 255).round()),
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.surfaceBackground.withAlpha((0.85 * 255).round()),
                  ],
                  stops: const [0.0, 0.25, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Top Controls (Back, Title, Subtitle, AspectRatio, Tracks)
                    Align(
                      alignment: Alignment.topCenter,
                      child: PlayerTopControlBar(
                        state: widget.state,
                        onBack: widget.onBack,
                        onWatchTogether: widget.onWatchTogether,
                        onPictureInPicture: widget.onPictureInPicture,
                        onAspectRatioChange: widget.onAspectRatioChange,
                        onToggleAuraGlow: widget.onToggleAuraGlow,
                        onShowSubtitlePicker: () =>
                            PlayerTrackPickers.showSubtitlePicker(
                          context: context,
                          state: widget.state,
                          onSelectSubtitleTrack: widget.onSelectSubtitleTrack,
                          onSelectSecondarySubtitleTrack:
                              widget.onSelectSecondarySubtitleTrack,
                          onSubtitleOffsetChanged:
                              widget.onSubtitleOffsetChanged,
                          onNudgeSubtitleOffset: widget.onNudgeSubtitleOffset,
                        ),
                        onShowAudioPicker: () =>
                            PlayerTrackPickers.showAudioPicker(
                          context: context,
                          state: widget.state,
                          onSelectAudioTrack: widget.onSelectAudioTrack,
                        ),
                      ),
                    ),

                    // Center Controls (Play, Pause, Buffering)
                    Align(
                      alignment: Alignment.center,
                      child: PlayerCenterControls(
                        state: widget.state,
                        onPlayPause: widget.onPlayPause,
                        onSeek: widget.onSeek,
                        onUserInteraction: _startHideTimer,
                      ),
                    ),

                    // Bottom Controls (Timeline, Aspect Ratio, Tracks)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: PlayerBottomControlBar(
                        state: widget.state,
                        onSeek: widget.onSeek,
                        onUserInteraction: _startHideTimer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
