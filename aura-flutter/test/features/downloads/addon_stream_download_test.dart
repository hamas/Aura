import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:aura/features/addons/domain/entities/addon_stream.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/downloads/data/datasources/download_execution_manager.dart';
import 'package:aura/features/downloads/data/datasources/download_storage_service.dart';
import 'package:aura/features/downloads/domain/entities/download_task.dart';
import 'package:aura/features/downloads/data/models/download_task_model.dart';
import 'package:aura/features/player/data/services/media_kit_player_service.dart';
import 'package:aura/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura/features/player/presentation/bloc/player_event.dart';

class FakeDownloadStorageService implements DownloadStorageService {
  final Directory tempDir;

  FakeDownloadStorageService(this.tempDir);

  @override
  Future<bool> hasSufficientStorageSpace(int requiredBytes) async => true;

  @override
  Future<Directory> getVaultDirectory() async {
    final vault = Directory('${tempDir.path}/offline_vault');
    if (!await vault.exists()) {
      await vault.create(recursive: true);
    }
    return vault;
  }

  @override
  Future<String> generateObfuscatedFilePath(
    String taskId, {
    String profileId = 'default',
    int? mediaId,
  }) async {
    final vault = await getVaultDirectory();
    final file = File('${vault.path}/${taskId}_test.vault');
    return file.path;
  }

  @override
  String getPartFilePath(String localFilePath) {
    return '$localFilePath.part';
  }

  @override
  Future<File> finalizeDownloadFile(String localFilePath) async {
    final partFile = File(getPartFilePath(localFilePath));
    final targetFile = File(localFilePath);
    if (await partFile.exists()) {
      return partFile.rename(localFilePath);
    }
    return targetFile;
  }

  @override
  Future<void> deleteMediaFiles(String localFilePath) async {
    final vFile = File(localFilePath);
    if (await vFile.exists()) await vFile.delete();
    final pFile = File(getPartFilePath(localFilePath));
    if (await pFile.exists()) await pFile.delete();
  }

  @override
  Future<int> calculateVaultStorageUsage() async => 0;

  @override
  Future<List<DownloadTask>> loadAllTaskRecords() async => [];

  @override
  Future<void> saveAllTaskRecords(List<DownloadTask> tasks) async {}

  @override
  Future<void> clearVaultAndRecords() async {}
}

void main() {
  group('AddonStream to DownloadExecutionManager & Sandboxed Storage Tests', () {
    late Directory tempDir;
    late FakeDownloadStorageService storageService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aura_download_test_');
      storageService = FakeDownloadStorageService(tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('AddonStream headers are retained in DownloadTask & sent via Dio', () async {
      // 1. Construct an AddonStream with headers
      const stream = AddonStream(
        url: 'https://cdn.example.com/movie.mp4',
        name: 'HD Stream',
        title: 'HD Stream Direct CDN',
        headers: {
          'User-Agent': 'CustomAddon/2.0',
          'Referer': 'https://origin.example.com',
        },
      );

      expect(stream.headers, isNotNull);
      expect(stream.headers!['User-Agent'], equals('CustomAddon/2.0'));
      expect(stream.headers!['Referer'], equals('https://origin.example.com'));

      final vaultDir = await storageService.getVaultDirectory();

      // 2. Create DownloadTask with custom headers
      final task = DownloadTask(
        id: 'test_task_1',
        mediaId: 101,
        title: 'Sample Movie',
        mediaType: MediaType.movie,
        downloadUrl: stream.url!,
        localFilePath: '${vaultDir.path}/test_task_1.vault',
        httpHeaders: stream.headers,
        createdAt: DateTime.now(),
      );

      // Verify task retains headers
      expect(task.httpHeaders, equals(stream.headers));

      // 3. Test DownloadTaskModel serialization preserves httpHeaders
      final model = DownloadTaskModel.fromEntity(task);
      final json = model.toJson();
      final restored = DownloadTaskModel.fromJson(json).toEntity();
      expect(restored.httpHeaders, equals(stream.headers));

      // 4. Intercept Dio request to verify injected headers
      RequestOptions? capturedOptions;
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        capturedOptions = options;
        return ResponseBody.fromBytes(
          [1, 2, 3, 4, 5],
          200,
          headers: {
            'content-length': ['5'],
          },
        );
      });

      final manager = DownloadExecutionManager(
        dio: dio,
        storageService: storageService,
      );

      final completer = Completer<String>();
      await manager.startOrResumeTask(
        task: task,
        onProgress: (_, __, ___, ____) {},
        onComplete: (taskId, totalBytes, finalPath) {
          completer.complete(finalPath);
        },
        onError: (taskId, error) {
          completer.completeError(error);
        },
      );

      final finalPath = await completer.future;

      // Verify request received merged custom headers
      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.headers['User-Agent'], equals('CustomAddon/2.0'));
      expect(capturedOptions!.headers['Referer'], equals('https://origin.example.com'));

      // Verify downloaded file exists in sandboxed path
      final downloadedFile = File(finalPath);
      expect(await downloadedFile.exists(), isTrue);
      expect(await downloadedFile.length(), equals(5));
    });

    test('Offline sandboxed file playback launches seamlessly in PlayerBloc without network headers', () async {
      final vaultDir = await storageService.getVaultDirectory();
      final localFile = File('${vaultDir.path}/local_video.mp4');
      await localFile.writeAsBytes([1, 2, 3, 4, 5, 6, 7, 8]);

      final testPlayerService = MediaKitPlayerService.test();
      final playerBloc = PlayerBloc(playerService: testPlayerService);

      // Dispatch PlayStreamEvent with local file path and no headers
      playerBloc.add(PlayStreamEvent(
        streamUrl: localFile.path,
        title: 'Offline Video',
        subtitle: 'Offline Playback',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(playerBloc.state.currentStreamUrl, equals(localFile.path));
      expect(playerBloc.state.title, equals('Offline Video'));

      await playerBloc.close();
    });
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) _handler;

  _MockHttpClientAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
