import '../entities/download_task.dart';

abstract class DownloadRepository {
  /// Fetches all stored download tasks.
  Future<List<DownloadTask>> getAllDownloads();

  /// Reactive stream of download tasks for real-time UI synchronization.
  Stream<List<DownloadTask>> watchDownloads();

  /// Starts or queues a download task.
  Future<void> startDownload(DownloadTask task);

  /// Pauses an active download task.
  Future<void> pauseDownload(String taskId);

  /// Resumes a paused download task.
  Future<void> resumeDownload(String taskId);

  /// Cancels an in-progress download and cleans up temporary files.
  Future<void> cancelDownload(String taskId);

  /// Deletes a completed or failed download task along with its local file.
  Future<void> deleteDownload(String taskId);

  /// Clears all downloads and deletes all files in the offline vault.
  Future<void> clearAllDownloads();

  /// Calculates total bytes occupied by the sandboxed offline vault.
  Future<int> getTotalStorageUsage();

  /// Gets the path to the sandboxed vault directory.
  Future<String> getSandboxedVaultDirectory();
}
