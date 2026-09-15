import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_profile.dart';

class GoogleAuthDataSource {
  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  GoogleAuthDataSource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            );

  FirebaseAuth get _auth {
    try {
      return _firebaseAuth ?? FirebaseAuth.instance;
    } catch (_) {
      if (_firebaseAuth != null) return _firebaseAuth;
      rethrow;
    }
  }

  Stream<UserProfile?> get authStateChanges {
    try {
      return _auth.authStateChanges().map(_mapFirebaseUser);
    } catch (_) {
      return Stream.value(null);
    }
  }

  UserProfile? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return UserProfile(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Google User',
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  Future<UserProfile> signIn() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const ServerException('Google sign in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw const ServerException(
            'Firebase authentication returned an empty user profile.');
      }

      return _mapFirebaseUser(user)!;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Google Sign In failed: $e');
    }
  }

  Future<UserProfile> signInWithHouseholdPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const ServerException('Sign in failed: User is null');
      }
      return _mapFirebaseUser(user)!;
    } catch (e) {
      throw ServerException('Household Sign In failed: $e');
    }
  }

  Future<void> setOrUpdateHouseholdPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const ServerException('No authenticated user found');
    }

    final isPasswordLinked = user.providerData
        .any((p) => p.providerId == EmailAuthProvider.PROVIDER_ID);

    try {
      if (!isPasswordLinked) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: newPassword,
        );
        await user.linkWithCredential(credential);
      } else {
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Re-authenticate via Google
        final googleUser = await _googleSignIn.signIn();
        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          final googleCred = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await user.reauthenticateWithCredential(googleCred);

          // Retry linking or updating password
          if (!isPasswordLinked) {
            final credential = EmailAuthProvider.credential(
              email: user.email!,
              password: newPassword,
            );
            await user.linkWithCredential(credential);
          } else {
            await user.updatePassword(newPassword);
          }
        } else {
          throw const ServerException('Re-authentication cancelled');
        }
      } else {
        throw ServerException('Failed to set household password: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Failed to set household password: $e');
    }
  }

  Future<bool> isHouseholdPasswordLinked() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData
        .any((p) => p.providerId == EmailAuthProvider.PROVIDER_ID);
  }

  Future<void> signOut() async {
    try {
      try {
        await _auth.signOut();
      } catch (_) {}
      await _googleSignIn.signOut();
    } catch (e) {
      throw ServerException('Sign out failed: $e');
    }
  }

  Future<UserProfile?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return _mapFirebaseUser(user);
      }
    } catch (_) {}

    final googleAccount = _googleSignIn.currentUser;
    if (googleAccount != null) {
      return UserProfile(
        id: googleAccount.id,
        email: googleAccount.email,
        displayName: googleAccount.displayName ?? 'Google User',
        photoUrl: googleAccount.photoUrl,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }
}
