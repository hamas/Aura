import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryChangedEvent extends SearchEvent {
  final String query;

  const SearchQueryChangedEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class AddRecentSearchEvent extends SearchEvent {
  final String query;

  const AddRecentSearchEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class RemoveRecentSearchEvent extends SearchEvent {
  final String query;

  const RemoveRecentSearchEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearAllRecentSearchesEvent extends SearchEvent {}
