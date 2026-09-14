import 'dart:async';
import '../../domain/entities/watch_room_session.dart';

/// Lightweight WebSocket / Realtime coordination engine for multi-user watch rooms.
class WatchTogetherService {
  final StreamController<WatchSyncEvent> _eventController =
      StreamController<WatchSyncEvent>.broadcast();
  final StreamController<WatchRoomSession> _sessionController =
      StreamController<WatchRoomSession>.broadcast();

  WatchRoomSession? _currentSession;
  Timer? _heartbeatTimer;
  String _currentUserId = 'user_host';

  Stream<WatchSyncEvent> get eventStream => _eventController.stream;
  Stream<WatchRoomSession> get sessionStream => _sessionController.stream;
  WatchRoomSession? get currentSession => _currentSession;
  String get currentUserId => _currentUserId;

  /// Creates a new room session as host.
  Future<WatchRoomSession> createRoom({
    required String mediaId,
    required String streamUrl,
    required String hostDisplayName,
  }) async {
    _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final roomCode = WatchRoomSession.generateRoomCode();
    final host = WatchRoomParticipant(
      id: _currentUserId,
      displayName: hostDisplayName,
      role: WatchRoomRole.host,
    );

    _currentSession = WatchRoomSession(
      roomCode: roomCode,
      mediaId: mediaId,
      streamUrl: streamUrl,
      hostId: _currentUserId,
      participants: [host],
    );

    _sessionController.add(_currentSession!);
    _startHeartbeat();
    return _currentSession!;
  }

  /// Joins an existing room session using code.
  Future<WatchRoomSession> joinRoom({
    required String roomCode,
    required String participantDisplayName,
    required String mediaId,
    required String streamUrl,
  }) async {
    _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final participant = WatchRoomParticipant(
      id: _currentUserId,
      displayName: participantDisplayName,
      role: WatchRoomRole.participant,
    );

    _currentSession = WatchRoomSession(
      roomCode: roomCode,
      mediaId: mediaId,
      streamUrl: streamUrl,
      hostId: 'host_id',
      participants: [
        const WatchRoomParticipant(
          id: 'host_id',
          displayName: 'Host User',
          role: WatchRoomRole.host,
        ),
        participant,
      ],
    );

    _sessionController.add(_currentSession!);
    _startHeartbeat();
    return _currentSession!;
  }

  /// Broadcasts play, pause, seek, or reaction sync events.
  void broadcastEvent(WatchSyncEvent event) {
    if (_eventController.isClosed) return;
    _eventController.add(event);

    if (_currentSession != null) {
      if (event.type == WatchSyncEventType.play) {
        _currentSession = _currentSession!.copyWith(isPlaying: true);
      } else if (event.type == WatchSyncEventType.pause) {
        _currentSession = _currentSession!.copyWith(isPlaying: false);
      } else if (event.type == WatchSyncEventType.seek) {
        _currentSession =
            _currentSession!.copyWith(currentPosition: event.position);
      }
      _sessionController.add(_currentSession!);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_currentSession != null) {
        broadcastEvent(WatchSyncEvent(
          type: WatchSyncEventType.heartbeat,
          senderId: _currentUserId,
          position: _currentSession!.currentPosition,
          timestamp: DateTime.now(),
        ));
      }
    });
  }

  /// Evaluates drift between client position and host position.
  /// If drift > 1.5 seconds, returns target resynchronization position.
  static Duration? calculateDriftCorrection({
    required Duration clientPos,
    required Duration hostPos,
    double driftThresholdSeconds = 1.5,
  }) {
    final diffMs = (clientPos.inMilliseconds - hostPos.inMilliseconds).abs();
    final thresholdMs = (driftThresholdSeconds * 1000).round();
    if (diffMs > thresholdMs) {
      return hostPos;
    }
    return null;
  }

  void toggleHostOnlyControl(bool hostOnly) {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(hostOnlyControl: hostOnly);
      _sessionController.add(_currentSession!);
    }
  }

  Future<void> leaveRoom() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _currentSession = null;
  }

  Future<void> dispose() async {
    await leaveRoom();
    await _eventController.close();
    await _sessionController.close();
  }
}
