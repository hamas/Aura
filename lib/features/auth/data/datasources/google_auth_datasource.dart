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
      // Return injected instance if available
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
        throw const ServerException('Firebase authentication returned an empty user profile.');
      }

      return _mapFirebaseUser(user)!;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Google Sign In failed: $e');
    }
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
