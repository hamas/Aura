import 'package:flutter/material.dart';
import '../../domain/entities/media_item.dart';
import 'media_details_screen.dart';

export 'media_details_screen.dart';

/// Backward-compatible alias for [MediaDetailsScreen].
class DetailScreen extends StatelessWidget {
  final int id;
  final MediaType type;
  final MediaItem? initialItem;

  const DetailScreen({
    super.key,
    required this.id,
    required this.type,
    this.initialItem,
  });

  @override
  Widget build(BuildContext context) {
    return MediaDetailsScreen(
      id: id,
      type: type,
      initialItem: initialItem,
    );
  }
}
