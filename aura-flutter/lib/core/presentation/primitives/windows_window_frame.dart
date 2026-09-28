import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Glassmorphic Windows 11 Mica / Acrylic custom window frame
/// and System Media Transport Controls (SMTC) integration.
class WindowsWindowFrame extends StatelessWidget {
  final Widget child;
  final String title;

  const WindowsWindowFrame({
    super.key,
    required this.child,
    this.title = 'Aura',
  });

  static const MethodChannel _smtcChannel = MethodChannel('aura/windows_smtc');

  /// Synchronizes current playback state and media metadata with Windows SMTC.
  static Future<void> updateSmtcMetadata({
    required String title,
    required String subtitle,
    required bool isPlaying,
    String? posterUrl,
  }) async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      await _smtcChannel.invokeMethod('updateMediaMetadata', {
        'title': title,
        'artist': subtitle,
        'isPlaying': isPlaying,
        'thumbnail': posterUrl,
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isWindows) {
      return child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      body: Column(
        children: [
          // Windows 11 Mica Frameless Window Title Bar
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D111A).withValues(alpha: 0.90),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Aura Logo Icon
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                // Native-styled Windows Window Controls
                _WindowControlButton(
                  icon: Icons.remove,
                  onTap: () {
                    // Minimize window
                  },
                ),
                _WindowControlButton(
                  icon: Icons.crop_square,
                  onTap: () {
                    // Maximize / restore window
                  },
                ),
                _WindowControlButton(
                  icon: Icons.close,
                  isClose: true,
                  onTap: () {
                    // Close window
                  },
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _WindowControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowControlButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: isClose ? Colors.redAccent : Colors.white.withValues(alpha: 0.1),
      child: SizedBox(
        width: 42,
        height: 38,
        child: Center(
          child: Icon(
            icon,
            size: 14,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
