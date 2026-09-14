import '../entities/user_profile.dart';

abstract class AuthRepository {
  /// Gets currently signed-in user if available.
  Future<UserProfile?> getCurrentUser();

  /// Sign in with Google Auth flow.
  Future<UserProfile> signInWithGoogle();

  /// Sign out.
  Future<void> signOut();

  /// Stream of auth state changes.
  Stream<UserProfile?> get authStateChanges;
}
