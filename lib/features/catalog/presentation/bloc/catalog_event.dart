import 'package:equatable/equatable.dart';
import '../../domain/entities/media_item.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class LoadDiscoveryFeedsEvent extends CatalogEvent {}

class SearchQueryChangedEvent extends CatalogEvent {
  final String query;
  const SearchQueryChangedEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadMediaDetailsEvent extends CatalogEvent {
  final int id;
  final MediaType type;
  const LoadMediaDetailsEvent({required this.id, required this.type});

  @override
  List<Object?> get props => [id, type];
}
