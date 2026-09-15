import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura/features/profiles/domain/entities/user_profile.dart';
import 'package:aura/features/profiles/data/services/profile_manager.dart';
import 'package:aura/features/trakt/data/services/trakt_scrobble_service.dart';
import 'package:aura/features/player/audio/audio_enhancer_service.dart';
import 'package:aura/features/profiles/presentation/screens/profile_selection_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aura/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aura/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura/features/auth/domain/entities/user_profile.dart' as auth_entity;

class _MockAuthRepository implements AuthRepository {
  @override
  Stream<auth_entity.UserProfile?> get authStateChanges => Stream.value(null);
  @override
  Future<auth_entity.UserProfile?> getCurrentUser() async => null;
  @override
  Future<auth_entity.UserProfile> signInWithGoogle() async => throw UnimplementedError();
  @override
  Future<auth_entity.UserProfile> signInWithHouseholdPassword({required String email, required String password}) async => throw UnimplementedError();
  @override
  Future<void> setOrUpdateHouseholdPassword(String newPassword) async {}
  @override
  Future<bool> isHouseholdPasswordLinked() async => false;
  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Profile Engine Unit Tests', () {
    test('UserProfile hashes and verifies 4-digit PIN correctly', () {
      final pinHash = UserProfile.hashPin('1234');
      final profile = UserProfile(
        id: 'p1',
        name: 'Test User',
        avatarPath: 'avatar.png',
        pinHash: pinHash,
        createdAt: DateTime.now(),
      );

      expect(profile.hasPin, isTrue);
      expect(profile.verifyPin('1234'), isTrue);
      expect(profile.verifyPin('9999'), isFalse);
    });

    test('KidsCertification filters mature content ratings', () {
      expect(KidsCertification.isAllowed('G'), isTrue);
      expect(KidsCertification.isAllowed('PG'), isTrue);
      expect(KidsCertification.isAllowed('TV-Y7'), isTrue);
      expect(KidsCertification.isAllowed('TV-MA'), isFalse);
      expect(KidsCertification.isAllowed('R'), isFalse);
    });

    test('ProfileManager enforces max 3 profiles per household', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = ProfileManager(prefs);

      // Default profile is created ("Profile 1")
      expect(manager.getProfiles().length, equals(1));

      // Add 2 more profiles (Total 3)
      for (int i = 2; i <= 3; i++) {
        final success = await manager.saveProfile(UserProfile(
          id: 'p$i',
          name: 'User $i',
          avatarPath: 'avatar_$i.png',
          createdAt: DateTime.now(),
        ));
        expect(success, isTrue);
      }

      // 4th profile should fail
      final overflowSuccess = await manager.saveProfile(UserProfile(
        id: 'p4',
        name: 'User 4',
        avatarPath: 'avatar_4.png',
        createdAt: DateTime.now(),
      ));
      expect(overflowSuccess, isFalse);
      expect(manager.getProfiles().length, equals(3));
    });
  });

  group('Trakt Scrobble Threshold & Audio Enhancer Tests', () {
    test('TraktScrobbleService identifies 80% watched threshold', () {
      expect(TraktScrobbleService.shouldMarkWatched(0.79), isFalse);
      expect(TraktScrobbleService.shouldMarkWatched(0.80), isTrue);
      expect(TraktScrobbleService.shouldMarkWatched(0.95), isTrue);
    });

    test('AudioEnhancerService produces valid filter specs for player', () {
      final service = AudioEnhancerService();
      expect(service.currentMode, equals(AudioEnhancementMode.off));
      expect(service.currentMode.mediaKitFilter, isNull);

      service.setEnhancementMode(AudioEnhancementMode.dialogueBoost);
      expect(service.currentMode, equals(AudioEnhancementMode.dialogueBoost));
      expect(service.currentMode.mediaKitFilter, contains('equalizer'));

      service.setEnhancementMode(AudioEnhancementMode.nightMode);
      expect(service.currentMode.mediaKitFilter, contains('acompressor'));
    });
  });

  group('ProfileSelectionScreen Widget Tests', () {
    testWidgets('renders profile selection screen title and grid',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: _MockAuthRepository()),
          child: MaterialApp(
            home: ProfileSelectionScreen(
              onProfileSelected: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Who's watching?"), findsOneWidget);
      expect(find.text('Profile 1'), findsOneWidget);
    });
  });
}
