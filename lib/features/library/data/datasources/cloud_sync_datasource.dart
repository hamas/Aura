import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/library_item.dart';

class CloudSyncDataSource {
  final SupabaseClient? _supabase;

  CloudSyncDataSource({SupabaseClient? supabase}) : _supabase = supabase;

  bool get isCloudAvailable => _supabase != null;

  Future<void> pushLibraryState(String userId, List<LibraryItem> items) async {
    if (_supabase == null) return;
    try {
      final payload = items.map((item) {
        return {
          'user_id': userId,
          'media_id': item.id,
          'title': item.title,
          'poster_path': item.posterPath,
          'backdrop_path': item.backdropPath,
          'type': item.type,
          'category': item.category.name,
          'progress': item.progress?.toJson(),
          'updated_at': item.updatedAt.toIso8601String(),
        };
      }).toList();

      await _supabase.from('user_library').upsert(payload);
    } catch (_) {
      // Offline fallback handling
    }
  }

  Future<List<LibraryItem>> fetchCloudLibrary(String userId) async {
    if (_supabase == null) return [];
    try {
      final response = await _supabase
          .from('user_library')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final records = response as List<dynamic>? ?? [];
      return records.map((r) {
        final map = r as Map<String, dynamic>;
        return LibraryItem.fromJson({
          'id': map['media_id'],
          'title': map['title'],
          'poster_path': map['poster_path'],
          'backdrop_path': map['backdrop_path'],
          'type': map['type'],
          'category': map['category'],
          'progress': map['progress'],
          'updated_at': map['updated_at'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
