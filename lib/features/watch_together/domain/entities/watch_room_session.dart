import 'dart:math';

enum WatchRoomRole { host, participant }

enum WatchSyncEventType { play, pause, seek, heartbeat, reaction }

class WatchRoomParticipant {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final WatchRoomRole role;
  final Duration position;
  final bool isReady;

  const WatchRoomParticipant({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    this.position = Duration.zero,
    this.isReady = true,
  });

  WatchRoomParticipant copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    WatchRoomRole? role,
    Duration? position,
    bool? isReady,
  }) {
    return WatchRoomParticipant(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      position: position ?? this.position,
      isReady: isReady ?? this.isReady,
    );
  }
}

class WatchSyncEvent {
  final WatchSyncEventType type;
  final String senderId;
  final Duration position;
  final DateTime timestamp;
  final String? payload; // Reaction emoji or extra metadata

  const WatchSyncEvent({
    required this.type,
    required this.senderId,
    required this.position,
    required this.timestamp,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'senderId': senderId,
        'positionMs': position.inMilliseconds,
        'timestampMs': timestamp.millisecondsSinceEpoch,
        'payload': payload,
      };

  factory WatchSyncEvent.fromJson(Map<String, dynamic> json) {
    return WatchSyncEvent(
      type: WatchSyncEventType.values.byName(json['type'] as String),
      senderId: json['senderId'] as String,
      position: Duration(milliseconds: json['positionMs'] as int),
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(json['timestampMs'] as int),
      payload: json['payload'] as String?,
    );
  }
}

class WatchRoomSession {
  final String roomCode;
  final String mediaId;
  final String streamUrl;
  final String hostId;
  final bool hostOnlyControl;
  final List<WatchRoomParticipant> participants;
  final bool isPlaying;
  final Duration currentPosition;

  const WatchRoomSession({
    required this.roomCode,
    required this.mediaId,
    required this.streamUrl,
    required this.hostId,
    this.hostOnlyControl = true,
    this.participants = const [],
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
  });

  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code =
        List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'AURA-$code';
  }

  WatchRoomSession copyWith({
    String? roomCode,
    String? mediaId,
    String? streamUrl,
    String? hostId,
    bool? hostOnlyControl,
    List<WatchRoomParticipant>? participants,
    bool? isPlaying,
    Duration? currentPosition,
  }) {
    return WatchRoomSession(
      roomCode: roomCode ?? this.roomCode,
      mediaId: mediaId ?? this.mediaId,
      streamUrl: streamUrl ?? this.streamUrl,
      hostId: hostId ?? this.hostId,
      hostOnlyControl: hostOnlyControl ?? this.hostOnlyControl,
      participants: participants ?? this.participants,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
}
