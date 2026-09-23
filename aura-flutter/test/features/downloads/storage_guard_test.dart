import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura/features/downloads/data/datasources/download_storage_service.dart';
import 'addon_stream_download_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Download Storage Guard & Vault Cleanup Tests', () {
    test('hasSufficientStorageSpace returns true for standard requests', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = DownloadStorageService(prefs: prefs);

      final hasSpace = await storage.hasSufficientStorageSpace(500 * 1024 * 1024); // 500MB request
      expect(hasSpace, isTrue);
    });

    test('generateObfuscatedFilePath builds valid sandboxed path format', () async {
      SharedPreferences.setMockInitialValues({});
      final tempDir = await Directory.systemTemp.createTemp('storage_guard_test');
      final storage = FakeDownloadStorageService(tempDir);

      final path = await storage.generateObfuscatedFilePath('task_test_123');
      expect(path, contains('task_test_123'));
      expect(path, endsWith('.vault'));
    });
  });
}
