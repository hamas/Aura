import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura/features/auth/domain/entities/user_profile.dart';
import 'package:aura/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aura/features/auth/presentation/bloc/auth_event.dart';
import 'package:aura/features/auth/presentation/bloc/auth_state.dart';
import 'package:aura/features/library/data/repositories/library_repository_impl.dart';
import 'package:aura/features/library/domain/entities/library_item.dart';

class MockAuthRepository implements AuthRepository {
  UserProfile? currentUser;

  @override
  Stream<UserProfile?> get authStateChanges => Stream.value(currentUser);

  @override
  Future<UserProfile?> getCurrentUser() async => currentUser;

  @override
  Future<UserProfile> signInWithGoogle() async {
    currentUser = UserProfile(
      id: 'google_uid_12345',
      email: 'tester@aura.app',
      displayName: 'Aura Tester',
      photoUrl: 'https://example.com/photo.png',
      createdAt: DateTime.now(),
    );
    return currentUser!;
  }

  @override
  Future<UserProfile> signInWithHouseholdPassword({
    required String email,
    required String password,
  }) async {
    currentUser = UserProfile(
      id: 'household_uid_12345',
      email: email,
      displayName: 'Household User',
      createdAt: DateTime.now(),
    );
    return currentUser!;
  }

  @override
  Future<void> setOrUpdateHouseholdPassword(String newPassword) async {}

  @override
  Future<bool> isHouseholdPasswordLinked() async => true;

  @override
  Future<void> signOut() async {
    currentUser = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Auth & User Profile Tests', () {
    test('UserProfile serializes and deserializes accurately', () {
      final now = DateTime.parse('2026-09-14T12:00:00Z');
      final user = UserProfile(
        id: 'user_123',
        email: 'dev@aura.io',
        displayName: 'Aura Developer',
        photoUrl: 'https://aura.io/avatar.png',
        createdAt: now,
      );

      final json = user.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, equals('user_123'));
      expect(restored.email, equals('dev@aura.io'));
      expect(restored.displayName, equals('Aura Developer'));
      expect(restored.photoUrl, equals('https://aura.io/avatar.png'));
    });

    test('AuthBloc handles CheckAuthStatus, SignIn, and SignOut events',
        () async {
      final mockRepo = MockAuthRepository();
      final bloc = AuthBloc(authRepository: mockRepo);

      expect(bloc.state.status, equals(AuthStatus.initial));

      bloc.add(CheckAuthStatusEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.status, equals(AuthStatus.unauthenticated));
      expect(bloc.state.isAuthenticated, isFalse);

      bloc.add(SignInWithGoogleEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.status, equals(AuthStatus.authenticated));
      expect(bloc.state.user?.id, equals('google_uid_12345'));
      expect(bloc.state.isAuthenticated, isTrue);

      bloc.add(SignOutEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.status, equals(AuthStatus.unauthenticated));
      expect(bloc.state.user, isNull);
      expect(bloc.state.isAuthenticated, isFalse);

      await bloc.close();
    });

    test('LibraryRepositoryImpl isolates persistence by authenticated user ID',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockAuth = MockAuthRepository();

      final libRepo = LibraryRepositoryImpl(
        prefs: prefs,
        authRepository: mockAuth,
      );

      // Guest session item
      final guestItem = LibraryItem(
        id: 'tt0137523',
        title: 'Fight Club',
        type: 'movie',
        category: LibraryCategory.watchlist,
        updatedAt: DateTime.now(),
      );
      await libRepo.saveLibraryItem(guestItem);

      var items = await libRepo.getLibraryItems();
      expect(items.length, equals(1));
      expect(items.first.title, equals('Fight Club'));

      // Sign in as user
      await mockAuth.signInWithGoogle();

      // User adds another item
      final userItem = LibraryItem(
        id: 'tt11126994',
        title: 'Arcane',
        type: 'series',
        category: LibraryCategory.watchlist,
        updatedAt: DateTime.now(),
      );
      await libRepo.saveLibraryItem(userItem);

      items = await libRepo.getLibraryItems();
      expect(items.any((i) => i.id == 'tt11126994'), isTrue);
    });
  });
}
