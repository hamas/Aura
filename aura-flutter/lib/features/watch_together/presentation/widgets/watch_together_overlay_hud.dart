import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/primitives/aura_badge.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../domain/entities/watch_room_session.dart';

class FloatingReaction {
  final String id;
  final String emoji;
  final double xOffset;

  const FloatingReaction({
    required this.id,
    required this.emoji,
    required this.xOffset,
  });
}

class WatchTogetherOverlayHUD extends StatefulWidget {
  final WatchRoomSession session;
  final ValueChanged<String> onSendReaction;
  final ValueChanged<bool> onToggleHostControl;
  final VoidCallback onLeaveRoom;

  const WatchTogetherOverlayHUD({
    super.key,
    required this.session,
    required this.onSendReaction,
    required this.onToggleHostControl,
    required this.onLeaveRoom,
  });

  @override
  State<WatchTogetherOverlayHUD> createState() =>
      _WatchTogetherOverlayHUDState();
}

class _WatchTogetherOverlayHUDState extends State<WatchTogetherOverlayHUD>
    with TickerProviderStateMixin {
  final List<FloatingReaction> _activeReactions = [];
  final List<String> _emojis = ['🔥', '😱', '😂', '❤️', '👏', '🎉'];

  void addReaction(String emoji) {
    widget.onSendReaction(emoji);
    final reaction = FloatingReaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      emoji: emoji,
      xOffset: (Random().nextDouble() * 40) - 20,
    );
    setState(() {
      _activeReactions.add(reaction);
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _activeReactions.removeWhere((r) => r.id == reaction.id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top Left: Participant Rail & Room Code Pill
        Positioned(
          left: 16,
          top: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.8 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        AppTheme.primaryAccent.withAlpha((0.5 * 255).round()),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AuraIcon(
                      AppIcons.group,
                      color: AppTheme.primaryAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.session.roomCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AuraBadge.status(
                      '${widget.session.participants.length} LIVE',
                      active: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Participant Avatars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.session.participants.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.surfaceElevated,
                      child: Text(
                        p.displayName.isNotEmpty
                            ? p.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Floating Animations Overlay (Right Edge)
        Positioned(
          right: 24,
          bottom: 120,
          top: 100,
          width: 60,
          child: Stack(
            children: _activeReactions.map((reaction) {
              return _AnimatedEmoji(
                key: ValueKey(reaction.id),
                reaction: reaction,
              );
            }).toList(),
          ),
        ),

        // Bottom Right Live Emoji Reaction Bar
        Positioned(
          right: 16,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.85 * 255).round()),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _emojis.map((emoji) {
                return GestureDetector(
                  onTap: () => addReaction(emoji),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedEmoji extends StatefulWidget {
  final FloatingReaction reaction;

  const _AnimatedEmoji({super.key, required this.reaction});

  @override
  State<_AnimatedEmoji> createState() => _AnimatedEmojiState();
}

class _AnimatedEmojiState extends State<_AnimatedEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _translateY;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _translateY = Tween<double>(begin: 200, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.reaction.xOffset, _translateY.value),
          child: Opacity(
            opacity: _opacity.value,
            child: Text(
              widget.reaction.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        );
      },
    );
  }
}
