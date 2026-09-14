import 'package:equatable/equatable.dart';
import '../../domain/entities/download_task.dart';

abstract class DownloadsEvent extends Equatable {
  const DownloadsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDownloadsEvent extends DownloadsEvent {}

class StartDownloadEvent extends DownloadsEvent {
  final DownloadTask task;

  const StartDownloadEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class PauseDownloadEvent extends DownloadsEvent {
  final String taskId;

  const PauseDownloadEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class ResumeDownloadEvent extends DownloadsEvent {
  final String taskId;

  const ResumeDownloadEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class CancelDownloadEvent extends DownloadsEvent {
  final String taskId;

  const CancelDownloadEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class DeleteDownloadEvent extends DownloadsEvent {
  final String taskId;

  const DeleteDownloadEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class ClearAllDownloadsEvent extends DownloadsEvent {}

class DownloadsUpdatedInternalEvent extends DownloadsEvent {
  final List<DownloadTask> tasks;
  final int totalStorageBytes;

  const DownloadsUpdatedInternalEvent({
    required this.tasks,
    required this.totalStorageBytes,
  });

  @override
  List<Object?> get props => [tasks, totalStorageBytes];
}
