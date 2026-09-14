import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
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
  final ValueChanged<double>? onVolumeChange;
  final VoidCallback? onPictureInPicture;
  final VoidCallback? onToggleAuraGlow;
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
    this.onVolumeChange,
    this.onPictureInPicture,
    this.onToggleAuraGlow,
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
      // Left side: Brightness
      setState(() {
        _currentBrightness = (_currentBrightness + delta).clamp(0.0, 1.0);
        _showBrightnessHud = true;
      });
      _brightnessHudTimer?.cancel();
      _brightnessHudTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showBrightnessHud = false);
      });
    } else {
      // Right side: Volume
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
    // Scrub sensitivity: dragging full screen width moves through 90 seconds
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
                // Left Double-tap area (Rewind 10s)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: _handleDoubleTapLeft,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Center Dead Zone
                const SizedBox(width: 80),
                // Right Double-tap area (Forward 10s)
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

        // Left Double-Tap Seek Animation Ripple
        if (_showLeftSeekRipple)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: size.width * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.centerLeft,
                  radius: 1.0,
                  colors: [
                    AppTheme.primaryAccent.withAlpha((0.25 * 255).round()),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuraIcon(AppIcons.replay10, color: Colors.white, size: 48),
                    SizedBox(height: 6),
                    Text(
                      '-10s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Right Double-Tap Seek Animation Ripple
        if (_showRightSeekRipple)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: size.width * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.centerRight,
                  radius: 1.0,
                  colors: [
                    AppTheme.primaryAccent.withAlpha((0.25 * 255).round()),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuraIcon(AppIcons.forward10, color: Colors.white, size: 48),
                    SizedBox(height: 6),
                    Text(
                      '+10s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Brightness HUD Overlay (Left Vertical)
        if (_showBrightnessHud)
          Positioned(
            left: 32,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildHudIndicator(
                icon: _currentBrightness > 0.5
                    ? AppIcons.brightnessHigh
                    : AppIcons.brightnessMedium,
                percent: _currentBrightness,
                label: '${(_currentBrightness * 100).toInt()}%',
              ),
            ),
          ),

        // Volume HUD Overlay (Right Vertical)
        if (_showVolumeHud)
          Positioned(
            right: 32,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildHudIndicator(
                icon: _currentVolume == 0
                    ? AppIcons.volumeOff
                    : _currentVolume > 50
                        ? AppIcons.volumeUp
                        : AppIcons.volumeDown,
                percent: _currentVolume / 100.0,
                label: '${_currentVolume.toInt()}%',
              ),
            ),
          ),

        // Horizontal Scrub Timeline Preview HUD
        if (_isScrubbing)
          Positioned.fill(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.85 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primaryAccent
                          .withAlpha((0.5 * 255).round())),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.5 * 255).round()),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AuraIcon(
                          _scrubOffset.isNegative
                              ? AppIcons.fastRewind
                              : AppIcons.fastForward,
                          color: AppTheme.primaryAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_scrubOffset.isNegative ? '' : '+'}${Formatters.formatDuration(_scrubOffset)}',
                          style: TextStyle(
                            color: _scrubOffset.isNegative
                                ? AppTheme.warningAccent
                                : AppTheme.successAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.formatDuration(_scrubTarget),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
                    Colors.black.withAlpha((0.75 * 255).round()),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withAlpha((0.85 * 255).round()),
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
                      child: _buildTopBar(context),
                    ),

                    // Center Controls (Play, Pause, Buffering)
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
      ],
    );
  }

  Widget _buildHudIndicator({
    required IconData icon,
    required double percent,
    required String label,
  }) {
    return Container(
      width: 44,
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.8 * 255).round()),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          AuraIcon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryAccent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const AuraIcon(AppIcons.arrowBackIosNew, color: Colors.white),
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
          // Picture-in-Picture (PiP) Button
          IconButton(
            icon: const AuraIcon(AppIcons.pip, color: Colors.white),
            tooltip: 'Picture-in-Picture',
            onPressed: () {
              if (widget.onPictureInPicture != null) {
                widget.onPictureInPicture!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entering Picture-in-Picture mode...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          // Aspect Ratio Toggle
          IconButton(
            icon: const AuraIcon(AppIcons.aspectRatio, color: Colors.white),
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
          // Ambient Aura Glow Toggle Button
          IconButton(
            icon: AuraIcon(
              AppIcons.autoAwesome,
              color: widget.state.enableAuraGlow
                  ? AppTheme.primaryAccent
                  : Colors.white54,
            ),
            tooltip: 'Ambient Aura Glow',
            onPressed: widget.onToggleAuraGlow,
          ),
          // Subtitle Track Selector
          IconButton(
            icon: const AuraIcon(AppIcons.subtitles, color: Colors.white),
            tooltip: 'Subtitles',
            onPressed: () => _showSubtitlePicker(context),
          ),
          // Audio Track Selector
          IconButton(
            icon: const AuraIcon(AppIcons.audiotrack, color: Colors.white),
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
          icon: const AuraIcon(AppIcons.replay10, color: Colors.white),
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
            icon: AuraIcon(
              widget.state.isPlaying ? AppIcons.pause : AppIcons.play,
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
          icon: const AuraIcon(AppIcons.forward10, color: Colors.white),
          onPressed: () {
            final target = widget.state.position + const Duration(seconds: 10);
            widget.onSeek(target > widget.state.duration
                ? widget.state.duration
                : target);
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
    final remaining = dur > pos ? dur - pos : Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                Formatters.formatDuration(pos),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
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
                '-${Formatters.formatDuration(remaining)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
              title: Text('Subtitles',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('Off'),
              trailing: widget.state.selectedSubtitleTrack == null
                  ? const AuraIcon(AppIcons.check,
                      color: AppTheme.primaryAccent)
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
                    ? const AuraIcon(AppIcons.check,
                        color: AppTheme.primaryAccent)
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
              title: Text('Audio Tracks',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...widget.state.audioTracks.map((a) {
              final isSelected = widget.state.selectedAudioTrack?.id == a.id;
              return ListTile(
                title: Text(a.title ?? a.language ?? 'Audio Track ${a.id}'),
                trailing: isSelected
                    ? const AuraIcon(AppIcons.check,
                        color: AppTheme.primaryAccent)
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
