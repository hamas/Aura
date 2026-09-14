import '../entities/clip_item.dart';

abstract class ClipsRepository {
  /// Fetches a curated list of high-engagement video clips and trailers.
  Future<List<ClipItem>> getTrendingClips();
}
