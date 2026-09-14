import 'package:equatable/equatable.dart';
import '../../domain/entities/library_item.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LoadLibraryEvent extends LibraryEvent {}

class ToggleWatchlistEvent extends LibraryEvent {
  final LibraryItem item;
  const ToggleWatchlistEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class UpdateProgressEvent extends LibraryEvent {
  final String mediaId;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String type;
  final int positionSeconds;
  final int durationSeconds;
  final int? seasonNumber;
  final int? episodeNumber;

  const UpdateProgressEvent({
    required this.mediaId,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.type,
    required this.positionSeconds,
    required this.durationSeconds,
    this.seasonNumber,
    this.episodeNumber,
  });

  @override
  List<Object?> get props => [
        mediaId,
        title,
        posterPath,
        backdropPath,
        type,
        positionSeconds,
        durationSeconds,
        seasonNumber,
        episodeNumber,
      ];
}

class RemoveLibraryItemEvent extends LibraryEvent {
  final String mediaId;
  const RemoveLibraryItemEvent(this.mediaId);

  @override
  List<Object?> get props => [mediaId];
}
