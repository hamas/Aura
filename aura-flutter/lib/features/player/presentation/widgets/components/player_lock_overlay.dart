import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';

/// Overlay handling the Netflix-style Player Screen Lock state.
/// When locked, all other touch controls are intercepted, and only a subtle unlock trigger is presented.
class PlayerLockOverlay extends StatefulWidget {
  final bool isLocked;
  final VoidCallback onToggleLock;

  const PlayerLockOverlay({
    super.key,
    required this.isLocked,
    required this.onToggleLock,
  });

  @override
  State<PlayerLockOverlay> createState() => _PlayerLockOverlayState();
}

class _PlayerLockOverlayState extends State<PlayerLockOverlay> with SingleTickerProviderStateMixin {
  bool _showLockedHint = false;
  Timer? _hintTimer;

  void _onLockedTap() {
    HapticFeedback.lightImpact();
    setState(() => _showLockedHint = true);
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showLockedHint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLocked) {
      // Unlocked state: Render floating lock toggle on top-left / left edge
      return Positioned(
        left: 20,
        top: 24,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onToggleLock();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_open_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Lock',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Locked state: Fullscreen tap interceptor + Unlock floating button & hint
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onLockedTap,
        child: Stack(
          children: [
            // Center hint on tap
            if (_showLockedHint)
              Center(
                child: AnimatedOpacity(
                  opacity: _showLockedHint ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.accentPink.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPink.withValues(alpha: 0.35),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: AppColors.accentPink, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Screen Locked',
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

            // Floating Unlock Button
            Positioned(
              left: 24,
              top: 24,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  widget.onToggleLock();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accentPink.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPink.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Unlock Screen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
