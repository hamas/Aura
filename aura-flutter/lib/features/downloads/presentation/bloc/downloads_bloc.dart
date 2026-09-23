import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import 'downloads_event.dart';
import 'downloads_state.dart';

class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  final DownloadRepository _downloadRepository;
  StreamSubscription<List<DownloadTask>>? _streamSubscription;

  DownloadsBloc({required DownloadRepository downloadRepository})
      : _downloadRepository = downloadRepository,
        super(const DownloadsState()) {
    on<LoadDownloadsEvent>(_onLoadDownloads);
    on<StartDownloadEvent>(_onStartDownload);
    on<PauseDownloadEvent>(_onPauseDownload);
    on<ResumeDownloadEvent>(_onResumeDownload);
    on<CancelDownloadEvent>(_onCancelDownload);
    on<DeleteDownloadEvent>(_onDeleteDownload);
    on<ClearAllDownloadsEvent>(_onClearAllDownloads);
    on<DownloadsUpdatedInternalEvent>(_onDownloadsUpdatedInternal);

    _initStream();
  }

  void _initStream() {
    _streamSubscription = _downloadRepository.watchDownloads().listen((tasks) {
      _refreshStorageAndEmit(tasks);
    });
  }

  Future<void> _refreshStorageAndEmit(List<DownloadTask> tasks) async {
    final storage = await _downloadRepository.getTotalStorageUsage();
    add(DownloadsUpdatedInternalEvent(
      tasks: tasks,
      totalStorageBytes: storage,
    ));
  }

  void _onDownloadsUpdatedInternal(
    DownloadsUpdatedInternalEvent event,
    Emitter<DownloadsState> emit,
  ) {
    emit(state.copyWith(
      status: DownloadsStatus.ready,
      tasks: event.tasks,
      totalStorageBytes: event.totalStorageBytes,
    ));
  }

  Future<void> _onLoadDownloads(
    LoadDownloadsEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    emit(state.copyWith(status: DownloadsStatus.loading));
    try {
      final tasks = await _downloadRepository.getAllDownloads();
      final storage = await _downloadRepository.getTotalStorageUsage();
      emit(state.copyWith(
        status: DownloadsStatus.ready,
        tasks: tasks,
        totalStorageBytes: storage,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DownloadsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onStartDownload(
    StartDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await _downloadRepository.startDownload(event.task);
  }

  Future<void> _onPauseDownload(
    PauseDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await _downloadRepository.pauseDownload(event.taskId);
  }

  Future<void> _onResumeDownload(
    ResumeDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await _downloadRepository.resumeDownload(event.taskId);
  }

  Future<void> _onCancelDownload(
    CancelDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await _downloadRepository.cancelDownload(event.taskId);
  }

  Future<void> _onDeleteDownload(
    DeleteDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await _downloadRepository.deleteDownload(event.taskId);
  }

  Future<void> _onClearAllDownloads(
    ClearAllDownloadsEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await _downloadRepository.clearAllDownloads();
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
