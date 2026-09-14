import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/entities/download_task.dart';
import 'download_storage_service.dart';

typedef OnProgressUpdate = void Function(
  String taskId,
  int bytesDownloaded,
  int totalBytes,
  double speed,
);

typedef OnDownloadComplete = void Function(
  String taskId,
  int totalBytes,
  String finalPath,
);

typedef OnDownloadError = void Function(
  String taskId,
  String errorMessage,
);

class DownloadExecutionManager {
  final Dio _dio;
  final DownloadStorageService _storageService;
  final Map<String, CancelToken> _activeCancelTokens = {};
  final Map<String, int> _lastReportedTime = {};
  final Map<String, int> _lastReportedBytes = {};

  DownloadExecutionManager({
    Dio? dio,
    required DownloadStorageService storageService,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 60),
                followRedirects: true,
              ),
            ),
        _storageService = storageService;

  bool isDownloading(String taskId) => _activeCancelTokens.containsKey(taskId);

  Future<void> startOrResumeTask({
    required DownloadTask task,
    required OnProgressUpdate onProgress,
    required OnDownloadComplete onComplete,
    required OnDownloadError onError,
  }) async {
    final taskId = task.id;
    if (isDownloading(taskId)) return;

    final cancelToken = CancelToken();
    _activeCancelTokens[taskId] = cancelToken;

    final partFilePath = _storageService.getPartFilePath(task.localFilePath);
    final partFile = File(partFilePath);

    int startByte = 0;
    if (await partFile.exists()) {
      startByte = await partFile.length();
    } else {
      await partFile.create(recursive: true);
    }

    _lastReportedTime[taskId] = DateTime.now().millisecondsSinceEpoch;
    _lastReportedBytes[taskId] = startByte;

    IOSink? sink;
    try {
      sink = partFile.openWrite(mode: FileMode.append);

      final headers = <String, dynamic>{
        'User-Agent': 'Aura-Mobile/1.0',
      };
      if (startByte > 0) {
        headers['Range'] = 'bytes=$startByte-';
      }

      final response = await _dio.get<ResponseBody>(
        task.downloadUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      final statusCode = response.statusCode ?? 200;
      final contentLengthHeader = response.headers.value('content-length');
      final contentRangeHeader = response.headers.value('content-range');

      int totalBytes = task.totalBytes;
      if (contentRangeHeader != null && contentRangeHeader.contains('/')) {
        final totalStr = contentRangeHeader.split('/').last;
        totalBytes = int.tryParse(totalStr) ?? totalBytes;
      } else if (contentLengthHeader != null) {
        final receivedContentLength = int.tryParse(contentLengthHeader) ?? 0;
        totalBytes = startByte + receivedContentLength;
      }

      if (statusCode != 200 && statusCode != 206) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'HTTP $statusCode stream rejected by remote server.',
        );
      }

      int currentBytes = startByte;
      final stream = response.data?.stream;
      if (stream == null) {
        throw Exception('Response body stream was null');
      }

      await for (final chunk in stream) {
        if (cancelToken.isCancelled) {
          break;
        }

        sink.add(chunk);
        currentBytes += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        final lastTime = _lastReportedTime[taskId] ?? now;
        final timeDelta = now - lastTime;

        // Throttle progress updates to at most once per 250ms to ensure 120fps UI fluidity
        if (timeDelta >= 250 || currentBytes >= totalBytes) {
          final lastBytes = _lastReportedBytes[taskId] ?? startByte;
          final byteDelta = currentBytes - lastBytes;
          final speed =
              timeDelta > 0 ? (byteDelta / (timeDelta / 1000.0)) : 0.0;

          _lastReportedTime[taskId] = now;
          _lastReportedBytes[taskId] = currentBytes;

          onProgress(taskId, currentBytes, totalBytes, speed);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      _activeCancelTokens.remove(taskId);
      _lastReportedTime.remove(taskId);
      _lastReportedBytes.remove(taskId);

      if (!cancelToken.isCancelled) {
        final finalFile =
            await _storageService.finalizeDownloadFile(task.localFilePath);
        onComplete(taskId, currentBytes, finalFile.path);
      }
    } catch (e) {
      _activeCancelTokens.remove(taskId);
      _lastReportedTime.remove(taskId);
      _lastReportedBytes.remove(taskId);

      try {
        await sink?.flush();
        await sink?.close();
      } catch (_) {}

      if (e is DioException && CancelToken.isCancel(e)) {
        // Paused or cancelled by user, not a fatal failure
        return;
      }

      onError(taskId, e.toString());
    }
  }

  void pauseTask(String taskId) {
    if (_activeCancelTokens.containsKey(taskId)) {
      _activeCancelTokens[taskId]?.cancel('Paused by user');
      _activeCancelTokens.remove(taskId);
    }
  }

  void cancelTask(String taskId) {
    if (_activeCancelTokens.containsKey(taskId)) {
      _activeCancelTokens[taskId]?.cancel('Cancelled by user');
      _activeCancelTokens.remove(taskId);
    }
  }

  void cancelAll() {
    for (final token in _activeCancelTokens.values) {
      token.cancel('Cancelled all');
    }
    _activeCancelTokens.clear();
  }
}
