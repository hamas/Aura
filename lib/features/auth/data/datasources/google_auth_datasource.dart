import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_profile.dart';

class GoogleAuthDataSource {
  final GoogleSignIn _googleSignIn;

  GoogleAuthDataSource({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            );

  Future<UserProfile> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const ServerException('Google sign in was cancelled');
      }

      return UserProfile(
        id: account.id,
        email: account.email,
        displayName: account.displayName ?? 'Google User',
        photoUrl: account.photoUrl,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw ServerException('Google Sign In failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<UserProfile?> getCurrentUser() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;
    return UserProfile(
      id: account.id,
      email: account.email,
      displayName: account.displayName ?? 'Google User',
      photoUrl: account.photoUrl,
      createdAt: DateTime.now(),
    );
  }
}
