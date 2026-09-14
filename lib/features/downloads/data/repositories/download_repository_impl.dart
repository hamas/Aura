import 'dart:async';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import '../datasources/download_execution_manager.dart';
import '../datasources/download_storage_service.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  final DownloadStorageService _storageService;
  final DownloadExecutionManager _executionManager;

  final StreamController<List<DownloadTask>> _tasksStreamController =
      StreamController<List<DownloadTask>>.broadcast();

  final Map<String, DownloadTask> _tasksCache = {};
  bool _isInitialized = false;

  DownloadRepositoryImpl({
    DownloadStorageService? storageService,
    DownloadExecutionManager? executionManager,
  })  : _storageService = storageService ?? DownloadStorageService(),
        _executionManager = executionManager ??
            DownloadExecutionManager(
              storageService: storageService ?? DownloadStorageService(),
            );

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    final stored = await _storageService.loadAllTaskRecords();
    for (final task in stored) {
      // If a task was left in downloading or queued state upon app restart, set to paused
      if (task.status == DownloadStatus.downloading ||
          task.status == DownloadStatus.queued) {
        _tasksCache[task.id] = task.copyWith(status: DownloadStatus.paused);
      } else {
        _tasksCache[task.id] = task;
      }
    }
    _isInitialized = true;
    _notifyListeners();
  }

  void _notifyListeners() {
    final list = _tasksCache.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _tasksStreamController.add(list);
    _storageService.saveAllTaskRecords(list);
  }

  @override
  Stream<List<DownloadTask>> watchDownloads() {
    _ensureInitialized();
    return _tasksStreamController.stream;
  }

  @override
  Future<List<DownloadTask>> getAllDownloads() async {
    await _ensureInitialized();
    return _tasksCache.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> startDownload(DownloadTask task) async {
    await _ensureInitialized();

    // Prepare sandboxed path if not already generated
    var effectiveTask = task;
    if (effectiveTask.localFilePath.isEmpty) {
      final sandboxedPath = await _storageService.generateObfuscatedFilePath(
        task.id,
        profileId: task.profileId,
        mediaId: task.mediaId,
      );
      effectiveTask = effectiveTask.copyWith(localFilePath: sandboxedPath);
    }

    effectiveTask =
        effectiveTask.copyWith(status: DownloadStatus.downloading, error: null);
    _tasksCache[effectiveTask.id] = effectiveTask;
    _notifyListeners();

    _runExecution(effectiveTask);
  }

  void _runExecution(DownloadTask task) {
    _executionManager.startOrResumeTask(
      task: task,
      onProgress: (taskId, bytesDownloaded, totalBytes, speed) {
        final current = _tasksCache[taskId];
        if (current != null) {
          _tasksCache[taskId] = current.copyWith(
            status: DownloadStatus.downloading,
            bytesDownloaded: bytesDownloaded,
            totalBytes: totalBytes,
            downloadSpeed: speed,
          );
          _notifyListeners();
        }
      },
      onComplete: (taskId, totalBytes, finalPath) {
        final current = _tasksCache[taskId];
        if (current != null) {
          _tasksCache[taskId] = current.copyWith(
            status: DownloadStatus.completed,
            bytesDownloaded: totalBytes,
            totalBytes: totalBytes,
            downloadSpeed: 0.0,
            localFilePath: finalPath,
            completedAt: DateTime.now(),
          );
          _notifyListeners();
        }
      },
      onError: (taskId, errorMessage) {
        final current = _tasksCache[taskId];
        if (current != null) {
          _tasksCache[taskId] = current.copyWith(
            status: DownloadStatus.failed,
            downloadSpeed: 0.0,
            error: errorMessage,
          );
          _notifyListeners();
        }
      },
    );
  }

  @override
  Future<void> pauseDownload(String taskId) async {
    await _ensureInitialized();
    _executionManager.pauseTask(taskId);
    final current = _tasksCache[taskId];
    if (current != null && current.status == DownloadStatus.downloading) {
      _tasksCache[taskId] = current.copyWith(
        status: DownloadStatus.paused,
        downloadSpeed: 0.0,
      );
      _notifyListeners();
    }
  }

  @override
  Future<void> resumeDownload(String taskId) async {
    await _ensureInitialized();
    final current = _tasksCache[taskId];
    if (current != null) {
      final updated = current.copyWith(
        status: DownloadStatus.downloading,
        error: null,
      );
      _tasksCache[taskId] = updated;
      _notifyListeners();
      _runExecution(updated);
    }
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    await _ensureInitialized();
    _executionManager.cancelTask(taskId);
    final task = _tasksCache.remove(taskId);
    if (task != null) {
      await _storageService.deleteMediaFiles(task.localFilePath);
    }
    _notifyListeners();
  }

  @override
  Future<void> deleteDownload(String taskId) async {
    await _ensureInitialized();
    _executionManager.cancelTask(taskId);
    final task = _tasksCache.remove(taskId);
    if (task != null) {
      await _storageService.deleteMediaFiles(task.localFilePath);
    }
    _notifyListeners();
  }

  @override
  Future<void> clearAllDownloads() async {
    await _ensureInitialized();
    _executionManager.cancelAll();
    _tasksCache.clear();
    await _storageService.clearVaultAndRecords();
    _notifyListeners();
  }

  @override
  Future<int> getTotalStorageUsage() {
    return _storageService.calculateVaultStorageUsage();
  }

  @override
  Future<String> getSandboxedVaultDirectory() async {
    final dir = await _storageService.getVaultDirectory();
    return dir.path;
  }

  @override
  Future<DownloadTask?> getCompletedTask(int mediaId) async {
    await _ensureInitialized();
    try {
      return _tasksCache.values.firstWhere(
        (t) => t.mediaId == mediaId && t.status == DownloadStatus.completed,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> smartDeleteWatchedEpisode(
      int mediaId, int season, int episode) async {
    await _ensureInitialized();
    final task = _tasksCache.values.cast<DownloadTask?>().firstWhere(
          (t) =>
              t != null &&
              t.mediaId == mediaId &&
              t.seasonNumber == season &&
              t.episodeNumber == episode &&
              t.status == DownloadStatus.completed,
          orElse: () => null,
        );
    if (task != null) {
      await deleteDownload(task.id);
    }
  }
}
