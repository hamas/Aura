import 'package:flutter/material.dart';
import 'package:aura/features/downloads/presentation/screens/downloads_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DownloadsScreen(initialTabIndex: 0);
  }
}
