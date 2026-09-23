import '../entities/user_profile.dart';

abstract class AuthRepository {
  /// Gets currently signed-in user if available.
  Future<UserProfile?> getCurrentUser();

  /// Sign in with Google Auth flow.
  Future<UserProfile> signInWithGoogle();

  /// Sign in with Household Email & Password.
  Future<UserProfile> signInWithHouseholdPassword({
    required String email,
    required String password,
  });

  /// Set or update Household Password for currently signed-in owner account.
  Future<void> setOrUpdateHouseholdPassword(String newPassword);

  /// Check whether household password provider is currently linked.
  Future<bool> isHouseholdPasswordLinked();

  /// Sign out.
  Future<void> signOut();

  /// Stream of auth state changes.
  Stream<UserProfile?> get authStateChanges;
}
