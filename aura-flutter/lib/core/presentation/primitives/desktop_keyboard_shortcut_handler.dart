import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global and In-Player Keyboard Shortcut Handler for Windows & Desktop.
/// Implements standard Netflix keyboard controls:
/// - Space / K: Play / Pause
/// - F / F11: Fullscreen Toggle
/// - M: Mute / Unmute
/// - S: Skip Intro / Recap
/// - N: Next Episode
/// - Left / Right Arrow: Seek ±10s
/// - Up / Down Arrow: Volume ±5%
/// - C: Toggle Subtitles
/// - Escape: Exit Fullscreen
class DesktopKeyboardShortcutHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPlayPause;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onToggleMute;
  final VoidCallback? onSkipIntro;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onSeekBackward;
  final VoidCallback? onSeekForward;
  final VoidCallback? onVolumeUp;
  final VoidCallback? onVolumeDown;
  final VoidCallback? onToggleSubtitles;
  final VoidCallback? onEscape;

  const DesktopKeyboardShortcutHandler({
    super.key,
    required this.child,
    this.onPlayPause,
    this.onToggleFullscreen,
    this.onToggleMute,
    this.onSkipIntro,
    this.onNextEpisode,
    this.onSeekBackward,
    this.onSeekForward,
    this.onVolumeUp,
    this.onVolumeDown,
    this.onToggleSubtitles,
    this.onEscape,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;

        // 1. Play / Pause (Space / K)
        if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyK) {
          if (onPlayPause != null) {
            onPlayPause!();
            return KeyEventResult.handled;
          }
        }

        // 2. Fullscreen Toggle (F / F11)
        if (key == LogicalKeyboardKey.keyF || key == LogicalKeyboardKey.f11) {
          if (onToggleFullscreen != null) {
            onToggleFullscreen!();
            return KeyEventResult.handled;
          }
        }

        // 3. Mute / Unmute (M)
        if (key == LogicalKeyboardKey.keyM) {
          if (onToggleMute != null) {
            onToggleMute!();
            return KeyEventResult.handled;
          }
        }

        // 4. Skip Intro (S)
        if (key == LogicalKeyboardKey.keyS) {
          if (onSkipIntro != null) {
            onSkipIntro!();
            return KeyEventResult.handled;
          }
        }

        // 5. Next Episode (N)
        if (key == LogicalKeyboardKey.keyN) {
          if (onNextEpisode != null) {
            onNextEpisode!();
            return KeyEventResult.handled;
          }
        }

        // 6. Seek Left / Right (±10s)
        if (key == LogicalKeyboardKey.arrowLeft) {
          if (onSeekBackward != null) {
            onSeekBackward!();
            return KeyEventResult.handled;
          }
        }
        if (key == LogicalKeyboardKey.arrowRight) {
          if (onSeekForward != null) {
            onSeekForward!();
            return KeyEventResult.handled;
          }
        }

        // 7. Volume Up / Down (±5%)
        if (key == LogicalKeyboardKey.arrowUp) {
          if (onVolumeUp != null) {
            onVolumeUp!();
            return KeyEventResult.handled;
          }
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          if (onVolumeDown != null) {
            onVolumeDown!();
            return KeyEventResult.handled;
          }
        }

        // 8. Toggle Subtitles (C)
        if (key == LogicalKeyboardKey.keyC) {
          if (onToggleSubtitles != null) {
            onToggleSubtitles!();
            return KeyEventResult.handled;
          }
        }

        // 9. Escape (Exit Fullscreen / Back)
        if (key == LogicalKeyboardKey.escape) {
          if (onEscape != null) {
            onEscape!();
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
