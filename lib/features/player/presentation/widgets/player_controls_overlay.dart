import 'dart:async';
import 'package:flutter/material.dart';
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
  final VoidCallback? onRetryStream;
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
    this.onRetryStream,
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
  final bool _isScrubbing = false;
  final Duration _scrubTarget = Duration.zero;
  final Duration _scrubOffset = Duration.zero;

  // Pinch-to-zoom toast state
  String? _zoomToastMessage;
  Timer? _zoomToastTimer;

  @override
  void initState() {
    super.initState();
    _currentVolume = widget.state.volume;
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (widget.state.isPlaying) {
      _hideTimer = Timer(const Duration(milliseconds: 3500), () {
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

  int _leftSeekAmount = 0;
  int _rightSeekAmount = 0;

  void _handleDoubleTapLeft() {
    _leftSeekAmount += 10;
    final target = widget.state.position - const Duration(seconds: 10);
    widget.onSeek(target < Duration.zero ? Duration.zero : target);

    setState(() {
      _showLeftSeekRipple = true;
    });
    _leftSeekTimer?.cancel();
    _leftSeekTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showLeftSeekRipple = false;
          _leftSeekAmount = 0;
        });
      }
    });
  }

  void _handleDoubleTapRight() {
    _rightSeekAmount += 10;
    final target = widget.state.position + const Duration(seconds: 10);
    widget.onSeek(
        target > widget.state.duration ? widget.state.duration : target);

    setState(() {
      _showRightSeekRipple = true;
    });
    _rightSeekTimer?.cancel();
    _rightSeekTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showRightSeekRipple = false;
          _rightSeekAmount = 0;
        });
      }
    });
  }

  void _onScaleStart(ScaleStartDetails details) {}

  void _onScaleUpdate(ScaleUpdateDetails details, double screenWidth, double screenHeight) {
    if (details.pointerCount == 2) {
      // Pinch to zoom gesture detected
      final scale = details.scale;
      if (scale > 1.25 && widget.state.fit != BoxFit.cover) {
        widget.onAspectRatioChange(BoxFit.cover);
        _showZoomToast('Zoomed to fill');
      } else if (scale < 0.8 && widget.state.fit != BoxFit.contain) {
        widget.onAspectRatioChange(BoxFit.contain);
        _showZoomToast('Original aspect ratio');
      }
      return;
    }

    // Single pointer vertical drag: Left = Brightness, Right = Volume
    if (details.pointerCount == 1 && details.localFocalPoint.dx.isFinite) {
      final isLeft = details.localFocalPoint.dx < screenWidth / 2;
      final delta = -details.focalPointDelta.dy / screenHeight; // up = increase

      if (delta.abs() > 0.002) {
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
    }
  }

  void _showZoomToast(String message) {
    setState(() => _zoomToastMessage = message);
    _zoomToastTimer?.cancel();
    _zoomToastTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _zoomToastMessage = null);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _leftSeekTimer?.cancel();
    _rightSeekTimer?.cancel();
    _brightnessHudTimer?.cancel();
    _volumeHudTimer?.cancel();
    _zoomToastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Gesture Detector Zone (Scale, Pinch-to-zoom, Vertical Drags, Double-Taps)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleVisibility,
            onScaleStart: _onScaleStart,
            onScaleUpdate: (details) =>
                _onScaleUpdate(details, size.width, size.height),
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

        // Visual Feedback for Gestures (Seek ripples, Volume/Brightness HUDs, Zoom toast, Scrub preview)
        PlayerGestureFeedbackOverlay(
          showLeftSeekRipple: _showLeftSeekRipple,
          showRightSeekRipple: _showRightSeekRipple,
          leftSeekSeconds: _leftSeekAmount > 0 ? _leftSeekAmount : 10,
          rightSeekSeconds: _rightSeekAmount > 0 ? _rightSeekAmount : 10,
          showBrightnessHud: _showBrightnessHud,
          currentBrightness: _currentBrightness,
          showVolumeHud: _showVolumeHud,
          currentVolume: _currentVolume,
          isScrubbing: _isScrubbing,
          scrubOffset: _scrubOffset,
          scrubTarget: _scrubTarget,
          zoomToastMessage: _zoomToastMessage,
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

        // Top, Center & Bottom Overlay Controls (YouTube style fade on inactivity)
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
                    Colors.black.withAlpha(200),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withAlpha(220),
                  ],
                  stops: const [0.0, 0.25, 0.65, 1.0],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Top Controls (Back, Title, Subtitle, AspectRatio, Speed, Tracks)
                    Align(
                      alignment: Alignment.topCenter,
                      child: PlayerTopControlBar(
                        state: widget.state,
                        onBack: widget.onBack,
                        onWatchTogether: widget.onWatchTogether,
                        onPictureInPicture: widget.onPictureInPicture,
                        onAspectRatioChange: widget.onAspectRatioChange,
                        onSpeedChange: widget.onSpeedChange,
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

                    // Center Controls (Play, Pause, Buffering with 20s timeout & retry)
                    Align(
                      alignment: Alignment.center,
                      child: PlayerCenterControls(
                        state: widget.state,
                        onPlayPause: widget.onPlayPause,
                        onSeek: widget.onSeek,
                        onUserInteraction: _startHideTimer,
                        onRetry: widget.onRetryStream,
                      ),
                    ),

                    // Bottom Controls (Timecode, YouTube Red/Accent Scrubber, Fullscreen)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: PlayerBottomControlBar(
                        state: widget.state,
                        onSeek: widget.onSeek,
                        onUserInteraction: _startHideTimer,
                        onNextEpisode: widget.onNextEpisode,
                        onToggleFullscreen: () {
                          // Toggle aspect ratio / fill as fullscreen shortcut
                          final nextFit = widget.state.fit == BoxFit.contain
                              ? BoxFit.cover
                              : BoxFit.contain;
                          widget.onAspectRatioChange(nextFit);
                          _showZoomToast(nextFit == BoxFit.cover
                              ? 'Zoomed to fill'
                              : 'Original aspect ratio');
                        },
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
