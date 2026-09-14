import 'dart:async';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/playback_completion_event.dart';
import '../../domain/entities/smart_download_settings.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/repositories/smart_download_settings_repository.dart';
import '../../../player/domain/entities/player_state.dart';
import 'smart_download_constraint_checker.dart';

/// Autonomous manager that monitors playback progress and orchestrates
/// episode deletion and pre-download within configurable guardrails.
///
/// Lifecycle:
///   1. Call [attachPlayerStream] after creating a playback session to begin
///      progress tracking.
///   2. The manager internally cancels its subscription when the player emits
///      [PlaybackStatus.completed] or when [detachPlayerStream] is called.
///   3. Call [dispose] when the feature is torn down (e.g., user logs out).
class SmartDownloadManager {
  final DownloadRepository _downloadRepository;
  final SmartDownloadSettingsRepository _settingsRepository;
  final SmartDownloadConstraintChecker _constraintChecker;

  /// Stream of human-readable status messages for the UI status row.
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  Stream<String> get statusStream => _statusController.stream;

  /// The [DownloadTask.id] currently being tracked for the 90% threshold.
  String? _trackedTaskId;

  /// Guards against duplicate deletion/queue calls for the same task.
  bool _hasTriggeredForCurrentTask = false;

  StreamSubscription<AuraPlayerState>? _playerSubscription;

  SmartDownloadManager({
    required DownloadRepository downloadRepository,
    required SmartDownloadSettingsRepository settingsRepository,
    SmartDownloadConstraintChecker? constraintChecker,
  })  : _downloadRepository = downloadRepository,
        _settingsRepository = settingsRepository,
        _constraintChecker =
            constraintChecker ?? SmartDownloadConstraintChecker();

  // ---------------------------------------------------------------------------
  // Player stream attachment
  // ---------------------------------------------------------------------------

  /// Begins tracking [playerStream] for the task identified by [taskId].
  ///
  /// [taskId] must match a [DownloadTask.id] stored in [DownloadRepository].
  /// Any previous subscription is cancelled before attaching the new one.
  void attachPlayerStream({
    required Stream<AuraPlayerState> playerStream,
    required String taskId,
  }) {
    _playerSubscription?.cancel();
    _trackedTaskId = taskId;
    _hasTriggeredForCurrentTask = false;

    _playerSubscription = playerStream.listen(
      (state) => _onPlayerState(state),
      onDone: detachPlayerStream,
    );
  }

  /// Cancels the current player subscription without disposing the manager.
  void detachPlayerStream() {
    _playerSubscription?.cancel();
    _playerSubscription = null;
    _trackedTaskId = null;
    _hasTriggeredForCurrentTask = false;
  }

  // ---------------------------------------------------------------------------
  // Playback progress evaluation
  // ---------------------------------------------------------------------------

  void _onPlayerState(AuraPlayerState state) {
    if (_hasTriggeredForCurrentTask) return;
    if (_trackedTaskId == null) return;
    if (state.duration == Duration.zero) return;

    final progress =
        state.position.inMilliseconds / state.duration.inMilliseconds;
    if (progress >= 0.90) {
      _hasTriggeredForCurrentTask = true;
      _handleWatchCompletion(_trackedTaskId!);
    }
  }

  // ---------------------------------------------------------------------------
  // Watch-completion handler
  // ---------------------------------------------------------------------------

  Future<void> _handleWatchCompletion(String completedTaskId) async {
    final settings = await _settingsRepository.loadSettings();
    if (!settings.enabled) return;

    final allTasks = await _downloadRepository.getAllDownloads();
    final completedTask =
        allTasks.where((t) => t.id == completedTaskId).firstOrNull;
    if (completedTask == null) return;

    // Step 1: Delete the watched episode file to reclaim vault space.
    await _safeDelete(completedTask);

    // Step 2: Check constraints before queuing next episodes.
    final vaultBytes = await _downloadRepository.getTotalStorageUsage();
    final constraint = await _constraintChecker.check(
      currentVaultBytes: vaultBytes,
      maxStorageBytes: settings.maxStorageBytes,
      lowStorageGuardBytes: settings.lowStorageGuardBytes,
    );

    if (!constraint.canDownload) {
      _emitStatus(
        'Episode deleted • Auto-queue paused: ${constraint.blockedReason}',
      );
      return;
    }

    // Step 3: Identify next episodes that need to be queued.
    final nextTasks = _resolveNextEpisodes(
      completedTask: completedTask,
      allTasks: allTasks,
      bufferSize: settings.bufferSize,
    );

    if (nextTasks.isEmpty) {
      _emitStatus('Watched episodes deleted • No further episodes to queue.');
      return;
    }

    // Step 4: Queue each undownloaded episode.
    var queued = 0;
    for (final task in nextTasks) {
      final updatedVault = await _downloadRepository.getTotalStorageUsage();
      final recheck = await _constraintChecker.check(
        currentVaultBytes: updatedVault,
        maxStorageBytes: settings.maxStorageBytes,
        lowStorageGuardBytes: settings.lowStorageGuardBytes,
      );
      if (!recheck.canDownload) break;

      // Reset to queued status before re-enqueueing.
      final queuedTask = task.copyWith(
        status: DownloadStatus.queued,
        bytesDownloaded: 0,
        completedAt: null,
        error: null,
        createdAt: DateTime.now(),
      );
      await _downloadRepository.startDownload(queuedTask);
      queued++;
    }

    final noun = queued == 1 ? 'episode' : 'episodes';
    _emitStatus(
      'Watched episodes deleted • Next $queued $noun queued on Wi-Fi',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Safely deletes the local file for [task], swallowing any IO errors.
  Future<void> _safeDelete(DownloadTask task) async {
    try {
      await _downloadRepository.deleteDownload(task.id);
    } catch (_) {
      // File deletion is best-effort; the engine must not crash on IO errors.
    }
  }

  /// Returns up to [bufferSize] completed [DownloadTask]s with episode numbers
  /// immediately following [completedTask] in the same season.
  ///
  /// Only tasks already downloaded (completed) but not yet watched, or tasks
  /// that need to be freshly queued, are returned. We identify candidates by
  /// episode number ordering within the same [mediaId] and [seasonNumber].
  List<DownloadTask> _resolveNextEpisodes({
    required DownloadTask completedTask,
    required List<DownloadTask> allTasks,
    required int bufferSize,
  }) {
    final mediaId = completedTask.mediaId;
    final season = completedTask.seasonNumber;
    final completedEp = completedTask.episodeNumber;
    if (season == null || completedEp == null) return [];

    // Gather all tasks in the same series+season, sorted by episode number.
    final siblings = allTasks
        .where(
          (t) =>
              t.mediaId == mediaId &&
              t.seasonNumber == season &&
              t.episodeNumber != null,
        )
        .toList()
      ..sort((a, b) => a.episodeNumber!.compareTo(b.episodeNumber!));

    // Find tasks after the completed episode that are not already downloading
    // or queued (we don't double-queue).
    return siblings
        .where(
          (t) =>
              t.episodeNumber! > completedEp &&
              t.status != DownloadStatus.downloading &&
              t.status != DownloadStatus.queued,
        )
        .take(bufferSize)
        .toList();
  }

  void _emitStatus(String message) {
    if (!_statusController.isClosed) {
      _statusController.add(message);
    }
  }

  // ---------------------------------------------------------------------------
  // Public helpers for external callers (e.g. enabling Smart Downloads)
  // ---------------------------------------------------------------------------

  /// Returns the current [SmartDownloadSettings] from persistent storage.
  Future<SmartDownloadSettings> loadSettings() =>
      _settingsRepository.loadSettings();

  /// Updates the persisted [SmartDownloadSettings].
  Future<void> saveSettings(SmartDownloadSettings settings) =>
      _settingsRepository.saveSettings(settings);

  /// Emits a [PlaybackCompletionEvent]-equivalent trigger manually (useful for
  /// testing or external integration without an active player stream).
  Future<void> handleManualCompletion(String taskId) =>
      _handleWatchCompletion(taskId);

  /// Releases all resources. Must be called when the owning scope is disposed.
  Future<void> dispose() async {
    await _playerSubscription?.cancel();
    _playerSubscription = null;
    await _statusController.close();
  }
}
