import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/downloads/domain/entities/download_task.dart';
import 'package:aura/features/downloads/domain/entities/smart_download_settings.dart';
import 'package:aura/features/downloads/domain/repositories/download_repository.dart';
import 'package:aura/features/downloads/domain/repositories/smart_download_settings_repository.dart';
import 'package:aura/features/downloads/domain/services/smart_download_constraint_checker.dart';
import 'package:aura/features/downloads/domain/services/smart_download_manager.dart';
import 'package:aura/features/player/domain/entities/player_state.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeDownloadRepository implements DownloadRepository {
  final List<DownloadTask> tasks;
  final List<String> deletedIds = [];
  final List<DownloadTask> startedTasks = [];
  int vaultBytes;

  FakeDownloadRepository({required this.tasks, this.vaultBytes = 0});

  @override
  Future<List<DownloadTask>> getAllDownloads() async => List.of(tasks);

  @override
  Future<void> startDownload(DownloadTask task) async {
    startedTasks.add(task);
    tasks.add(task);
  }

  @override
  Future<void> deleteDownload(String taskId) async {
    deletedIds.add(taskId);
    tasks.removeWhere((t) => t.id == taskId);
  }

  @override
  Future<int> getTotalStorageUsage() async => vaultBytes;

  @override
  Stream<List<DownloadTask>> watchDownloads() => const Stream.empty();

  @override
  Future<void> pauseDownload(String taskId) async {}

  @override
  Future<void> resumeDownload(String taskId) async {}

  @override
  Future<void> cancelDownload(String taskId) async {}

  @override
  Future<void> clearAllDownloads() async {}

  @override
  Future<String> getSandboxedVaultDirectory() async => '/fake/vault';

  @override
  Future<DownloadTask?> getCompletedTask(int mediaId) async {
    try {
      return tasks.firstWhere(
        (t) => t.mediaId == mediaId && t.status == DownloadStatus.completed,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> smartDeleteWatchedEpisode(
      int mediaId, int season, int episode) async {
    tasks.removeWhere((t) =>
        t.mediaId == mediaId &&
        t.seasonNumber == season &&
        t.episodeNumber == episode &&
        t.status == DownloadStatus.completed);
  }
}

class FakeSettingsRepository implements SmartDownloadSettingsRepository {
  SmartDownloadSettings _settings;

  FakeSettingsRepository({SmartDownloadSettings? settings})
      : _settings = settings ??
            const SmartDownloadSettings(enabled: true, bufferSize: 2);

  @override
  Future<SmartDownloadSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(SmartDownloadSettings settings) async {
    _settings = settings;
  }
}

class FakeConstraintChecker extends SmartDownloadConstraintChecker {
  final bool allowed;
  final String? reason;

  FakeConstraintChecker({this.allowed = true, this.reason})
      : super(connectivity: null, battery: null);

  @override
  Future<ConstraintCheckResult> check({
    required int currentVaultBytes,
    required int maxStorageBytes,
    required int lowStorageGuardBytes,
  }) async {
    return allowed
        ? const ConstraintCheckResult.allowed()
        : ConstraintCheckResult.blocked(reason ?? 'Test blocked');
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

DownloadTask _makeTask({
  required String id,
  required int ep,
  int season = 1,
  int mediaId = 999,
  DownloadStatus status = DownloadStatus.completed,
}) {
  return DownloadTask(
    id: id,
    mediaId: mediaId,
    title: 'Series S${season}E$ep',
    mediaType: MediaType.series,
    seasonNumber: season,
    episodeNumber: ep,
    downloadUrl: 'https://cdn.example.com/$id',
    localFilePath: '/vault/$id.vault',
    status: status,
    createdAt: DateTime(2026, 1, ep),
  );
}

AuraPlayerState _stateAtProgress(double fraction, {int durationMs = 3000}) {
  final duration = Duration(milliseconds: durationMs);
  final position = Duration(milliseconds: (durationMs * fraction).round());
  return AuraPlayerState(
    status: PlaybackStatus.playing,
    position: position,
    duration: duration,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SmartDownloadManager', () {
    late FakeDownloadRepository repo;
    late FakeSettingsRepository settingsRepo;
    late FakeConstraintChecker checker;
    late SmartDownloadManager manager;

    setUp(() {
      repo = FakeDownloadRepository(
        tasks: [
          _makeTask(id: 'ep1', ep: 1),
          _makeTask(id: 'ep2', ep: 2),
          _makeTask(id: 'ep3', ep: 3, status: DownloadStatus.paused),
          _makeTask(id: 'ep4', ep: 4, status: DownloadStatus.failed),
        ],
      );
      settingsRepo = FakeSettingsRepository();
      checker = FakeConstraintChecker();
      manager = SmartDownloadManager(
        downloadRepository: repo,
        settingsRepository: settingsRepo,
        constraintChecker: checker,
      );
    });

    tearDown(() => manager.dispose());

    // -------------------------------------------------------------------------
    test('does NOT trigger before 90% playback progress', () async {
      final controller = StreamController<AuraPlayerState>();
      manager.attachPlayerStream(
          playerStream: controller.stream, taskId: 'ep1');

      controller.add(_stateAtProgress(0.50));
      controller.add(_stateAtProgress(0.89));
      await Future<void>.delayed(Duration.zero);

      expect(repo.deletedIds, isEmpty);
      expect(repo.startedTasks, isEmpty);
      await controller.close();
    });

    // -------------------------------------------------------------------------
    test('triggers deletion at exactly 90% playback progress', () async {
      final controller = StreamController<AuraPlayerState>();
      manager.attachPlayerStream(
          playerStream: controller.stream, taskId: 'ep1');

      controller.add(_stateAtProgress(0.90));
      await Future<void>.delayed(Duration.zero);

      expect(repo.deletedIds, contains('ep1'));
      await controller.close();
    });

    // -------------------------------------------------------------------------
    test('queues next [bufferSize] episodes after deletion', () async {
      // bufferSize = 2: after ep1 (completed) is watched, the next 2 eligible
      // siblings are ep2 (completed) and ep3 (paused). ep4 is out of the buffer.
      final controller = StreamController<AuraPlayerState>();
      manager.attachPlayerStream(
          playerStream: controller.stream, taskId: 'ep1');

      controller.add(_stateAtProgress(0.95));
      await Future<void>.delayed(Duration.zero);

      final queuedIds = repo.startedTasks.map((t) => t.id).toList();
      expect(queuedIds, containsAll(['ep2', 'ep3']));
      expect(queuedIds.length, equals(2)); // exactly bufferSize episodes queued
      await controller.close();
    });

    // -------------------------------------------------------------------------
    test('does NOT double-trigger for the same episode', () async {
      final controller = StreamController<AuraPlayerState>();
      manager.attachPlayerStream(
          playerStream: controller.stream, taskId: 'ep1');

      controller.add(_stateAtProgress(0.90));
      controller.add(_stateAtProgress(0.95));
      controller.add(_stateAtProgress(1.00));
      await Future<void>.delayed(Duration.zero);

      expect(repo.deletedIds.where((id) => id == 'ep1').length, equals(1));
      await controller.close();
    });

    // -------------------------------------------------------------------------
    test('does nothing when Smart Downloads are disabled', () async {
      settingsRepo = FakeSettingsRepository(
        settings: const SmartDownloadSettings(enabled: false),
      );
      manager = SmartDownloadManager(
        downloadRepository: repo,
        settingsRepository: settingsRepo,
        constraintChecker: checker,
      );

      final controller = StreamController<AuraPlayerState>();
      manager.attachPlayerStream(
          playerStream: controller.stream, taskId: 'ep1');

      controller.add(_stateAtProgress(1.00));
      await Future<void>.delayed(Duration.zero);

      expect(repo.deletedIds, isEmpty);
      expect(repo.startedTasks, isEmpty);
      await controller.close();
    });

    // -------------------------------------------------------------------------
    test('skips queueing when constraint checker blocks (no Wi-Fi)', () async {
      checker = FakeConstraintChecker(
        allowed: false,
        reason: 'No Wi-Fi',
      );
      manager = SmartDownloadManager(
        downloadRepository: repo,
        settingsRepository: settingsRepo,
        constraintChecker: checker,
      );

      final controller = StreamController<AuraPlayerState>();
      manager.attachPlayerStream(
          playerStream: controller.stream, taskId: 'ep1');

      controller.add(_stateAtProgress(0.92));
      await Future<void>.delayed(Duration.zero);

      // Deletion still occurs; only queuing is suppressed.
      expect(repo.deletedIds, contains('ep1'));
      expect(repo.startedTasks, isEmpty);
      await controller.close();
    });

    // -------------------------------------------------------------------------
    test('emits a status message after successful queue', () async {
      final messages = <String>[];
      manager.statusStream.listen(messages.add);

      final controller = StreamController<AuraPlayerState>();
      manager.attachPlayerStream(
          playerStream: controller.stream, taskId: 'ep1');

      controller.add(_stateAtProgress(0.91));
      await Future<void>.delayed(Duration.zero);

      expect(messages, isNotEmpty);
      expect(messages.last, contains('queued on Wi-Fi'));
      await controller.close();
    });

    // -------------------------------------------------------------------------
    test('handleManualCompletion deletes task and queues next episodes',
        () async {
      await manager.handleManualCompletion('ep1');

      expect(repo.deletedIds, contains('ep1'));
      expect(repo.startedTasks, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('SmartDownloadSettings serialisation', () {
    test('roundtrip toJson / fromJson preserves all fields', () {
      const original = SmartDownloadSettings(
        enabled: true,
        bufferSize: 3,
        maxStorageBytes: 10 * 1024 * 1024 * 1024,
        lowStorageGuardBytes: 1 * 1024 * 1024 * 1024,
      );
      final restored = SmartDownloadSettings.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('bufferSize is clamped to [1, 3] on copyWith', () {
      const base = SmartDownloadSettings();
      expect(base.copyWith(bufferSize: 0).bufferSize, equals(1));
      expect(base.copyWith(bufferSize: 5).bufferSize, equals(3));
    });
  });
}
