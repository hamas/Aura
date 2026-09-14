import 'package:aura/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firebase Project Connectivity & Configuration Diagnostics', () {
    test('Android configuration targets aura-508612 project', () {
      const androidOptions = DefaultFirebaseOptions.android;
      expect(androidOptions.projectId, equals('aura-508612'));
      expect(
        androidOptions.appId,
        equals('1:1006842867636:android:b2d866cf7901d448010ce1'),
      );
      expect(
        androidOptions.storageBucket,
        equals('aura-508612.firebasestorage.app'),
      );
      expect(androidOptions.messagingSenderId, equals('1006842867636'));
      expect(androidOptions.apiKey.isNotEmpty, isTrue);
    });

    test(
      'iOS configuration targets aura-508612 project with valid bundle ID and client IDs',
      () {
        const iosOptions = DefaultFirebaseOptions.ios;
        expect(iosOptions.projectId, equals('aura-508612'));
        expect(
          iosOptions.appId,
          equals('1:1006842867636:ios:c0d08a05d9d58693010ce1'),
        );
        expect(iosOptions.iosBundleId, equals('com.aura.app.aura'));
        expect(
          iosOptions.storageBucket,
          equals('aura-508612.firebasestorage.app'),
        );
        expect(iosOptions.messagingSenderId, equals('1006842867636'));
        expect(iosOptions.iosClientId, isNotNull);
        expect(iosOptions.androidClientId, isNotNull);
      },
    );

    test(
      'macOS configuration targets aura-508612 project with matching bundle ID',
      () {
        const macosOptions = DefaultFirebaseOptions.macos;
        expect(macosOptions.projectId, equals('aura-508612'));
        expect(
          macosOptions.appId,
          equals('1:1006842867636:ios:c0d08a05d9d58693010ce1'),
        );
        expect(macosOptions.iosBundleId, equals('com.aura.app.aura'));
        expect(
          macosOptions.storageBucket,
          equals('aura-508612.firebasestorage.app'),
        );
      },
    );
  });
}
