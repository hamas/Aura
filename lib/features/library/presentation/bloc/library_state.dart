import 'package:equatable/equatable.dart';
import '../../domain/entities/library_item.dart';

enum LibraryStatus { initial, loading, success, failure }

class LibraryState extends Equatable {
  final LibraryStatus status;
  final List<LibraryItem> watchlist;
  final List<LibraryItem> continueWatching;
  final List<LibraryItem> history;
  final String? errorMessage;

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.watchlist = const [],
    this.continueWatching = const [],
    this.history = const [],
    this.errorMessage,
  });

  bool isInWatchlist(String mediaId) {
    return watchlist.any((i) => i.id == mediaId);
  }

  LibraryState copyWith({
    LibraryStatus? status,
    List<LibraryItem>? watchlist,
    List<LibraryItem>? continueWatching,
    List<LibraryItem>? history,
    String? errorMessage,
  }) {
    return LibraryState(
      status: status ?? this.status,
      watchlist: watchlist ?? this.watchlist,
      continueWatching: continueWatching ?? this.continueWatching,
      history: history ?? this.history,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, watchlist, continueWatching, history, errorMessage];
}
