import 'dart:async';
import 'package:aura/core/theme/aura_theme.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/downloads/data/models/download_task_model.dart';
import 'package:aura/features/downloads/domain/entities/download_task.dart';
import 'package:aura/features/downloads/domain/repositories/download_repository.dart';
import 'package:aura/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:aura/features/downloads/presentation/bloc/downloads_event.dart';
import 'package:aura/features/downloads/presentation/screens/downloads_screen.dart';
import 'package:aura/features/downloads/presentation/widgets/download_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockDownloadRepository implements DownloadRepository {
  final Map<String, DownloadTask> _tasks = {};
  final StreamController<List<DownloadTask>> _streamController =
      StreamController<List<DownloadTask>>.broadcast();

  MockDownloadRepository({List<DownloadTask>? initialTasks}) {
    if (initialTasks != null) {
      for (final t in initialTasks) {
        _tasks[t.id] = t;
      }
    }
  }

  void _emit() {
    _streamController.add(_tasks.values.toList());
  }

  @override
  Future<List<DownloadTask>> getAllDownloads() async {
    return _tasks.values.toList();
  }

  @override
  Stream<List<DownloadTask>> watchDownloads() {
    return _streamController.stream;
  }

  @override
  Future<void> startDownload(DownloadTask task) async {
    _tasks[task.id] = task.copyWith(status: DownloadStatus.downloading);
    _emit();
  }

  @override
  Future<void> pauseDownload(String taskId) async {
    final t = _tasks[taskId];
    if (t != null) {
      _tasks[taskId] = t.copyWith(status: DownloadStatus.paused);
      _emit();
    }
  }

  @override
  Future<void> resumeDownload(String taskId) async {
    final t = _tasks[taskId];
    if (t != null) {
      _tasks[taskId] = t.copyWith(status: DownloadStatus.downloading);
      _emit();
    }
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    _tasks.remove(taskId);
    _emit();
  }

  @override
  Future<void> deleteDownload(String taskId) async {
    _tasks.remove(taskId);
    _emit();
  }

  @override
  Future<void> clearAllDownloads() async {
    _tasks.clear();
    _emit();
  }

  @override
  Future<int> getTotalStorageUsage() async {
    return _tasks.values.fold<int>(0, (sum, t) => sum + t.bytesDownloaded);
  }

  @override
  Future<String> getSandboxedVaultDirectory() async {
    return '/mock/sandbox/offline_vault';
  }
}

void main() {
  group('Private Sandboxed Offline Download Engine Tests', () {
    final testTaskMovie = DownloadTask(
      id: 'movie_550',
      mediaId: 550,
      title: 'Fight Club',
      mediaType: MediaType.movie,
      posterPath: '/poster.jpg',
      backdropPath: '/backdrop.jpg',
      downloadUrl: 'https://debrid.example.com/stream/fight_club.mp4',
      localFilePath: '/mock/sandbox/offline_vault/movie_550_abc.vault',
      status: DownloadStatus.completed,
      bytesDownloaded: 1024 * 1024 * 500, // 500 MB
      totalBytes: 1024 * 1024 * 500,
      createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
    );

    final testTaskSeries = DownloadTask(
      id: 'series_1399_s1_e1',
      mediaId: 1399,
      title: 'Game of Thrones',
      mediaType: MediaType.series,
      seasonNumber: 1,
      episodeNumber: 1,
      episodeTitle: 'Winter Is Coming',
      posterPath: '/got_poster.jpg',
      backdropPath: '/got_backdrop.jpg',
      downloadUrl: 'https://debrid.example.com/stream/got_s1_e1.mp4',
      localFilePath: '/mock/sandbox/offline_vault/series_1399_s1_e1_xyz.vault',
      status: DownloadStatus.downloading,
      bytesDownloaded: 1024 * 1024 * 250, // 250 MB
      totalBytes: 1024 * 1024 * 1000, // 1000 MB (1GB)
      downloadSpeed: 1024 * 1024 * 15, // 15 MB/s
      createdAt: DateTime.parse('2026-01-02T00:00:00.000Z'),
    );

    test('DownloadTask entity calculated properties and formatters', () {
      expect(testTaskMovie.isCompleted, isTrue);
      expect(testTaskMovie.progressPercentage, equals(1.0));
      expect(testTaskMovie.formattedProgressPercentage, equals('100.0%'));
      expect(testTaskMovie.formattedTotalSize, equals('500.0 MB'));

      expect(testTaskSeries.isDownloading, isTrue);
      expect(testTaskSeries.progressPercentage, equals(0.25));
      expect(testTaskSeries.formattedProgressPercentage, equals('25.0%'));
      expect(testTaskSeries.formattedSpeed, equals('15.0 MB/s'));
    });

    test('DownloadTaskModel JSON roundtrip serialization', () {
      final model = DownloadTaskModel.fromEntity(testTaskMovie);
      final json = model.toJson();
      final fromJson = DownloadTaskModel.fromJson(json).toEntity();

      expect(fromJson.id, equals(testTaskMovie.id));
      expect(fromJson.mediaId, equals(testTaskMovie.mediaId));
      expect(fromJson.title, equals(testTaskMovie.title));
      expect(fromJson.status, equals(DownloadStatus.completed));
      expect(fromJson.bytesDownloaded, equals(testTaskMovie.bytesDownloaded));
    });

    test(
        'DownloadsBloc handles start, pause, resume, delete, and clear lifecycle',
        () async {
      final repo = MockDownloadRepository(initialTasks: [testTaskMovie]);
      final bloc = DownloadsBloc(downloadRepository: repo);

      bloc.add(LoadDownloadsEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.tasks.length, equals(1));
      expect(bloc.state.completedTasks.length, equals(1));

      // Start new task
      bloc.add(StartDownloadEvent(testTaskSeries));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.tasks.any((t) => t.id == 'series_1399_s1_e1'), isTrue);

      // Pause task
      bloc.add(const PauseDownloadEvent('series_1399_s1_e1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.getTask('series_1399_s1_e1')?.status,
          DownloadStatus.paused);

      // Resume task
      bloc.add(const ResumeDownloadEvent('series_1399_s1_e1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.getTask('series_1399_s1_e1')?.status,
          DownloadStatus.downloading);

      // Delete task
      bloc.add(const DeleteDownloadEvent('series_1399_s1_e1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.getTask('series_1399_s1_e1'), isNull);

      // Clear all
      bloc.add(ClearAllDownloadsEvent());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.tasks.isEmpty, isTrue);

      await bloc.close();
    });

    testWidgets('DownloadActionButton renders dynamic states', (tester) async {
      final repo = MockDownloadRepository(initialTasks: [testTaskMovie]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: Scaffold(
            body: BlocProvider<DownloadsBloc>(
              create: (_) => DownloadsBloc(downloadRepository: repo)
                ..add(LoadDownloadsEvent()),
              child: DownloadActionButton(
                mediaId: 550,
                mediaType: MediaType.movie,
                showLabel: true,
                onStartDownload: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Downloaded'), findsOneWidget);
    });

    testWidgets('DownloadsScreen displays stored downloads and storage banner',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo =
          MockDownloadRepository(initialTasks: [testTaskMovie, testTaskSeries]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: BlocProvider<DownloadsBloc>(
            create: (_) => DownloadsBloc(downloadRepository: repo)
              ..add(LoadDownloadsEvent()),
            child: const DownloadsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Downloads'), findsOneWidget);
      expect(find.text('Private Vault Storage'), findsOneWidget);
      expect(find.text('SANDBOXED'), findsOneWidget);
      expect(find.text('Fight Club'), findsOneWidget);
      expect(find.text('Game of Thrones'), findsOneWidget);
      expect(find.textContaining('Winter Is Coming'), findsOneWidget);
    });
  });
}
