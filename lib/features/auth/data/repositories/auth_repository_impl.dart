import 'dart:async';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/google_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GoogleAuthDataSource _googleAuthDataSource;
  final StreamController<UserProfile?> _authStateController =
      StreamController<UserProfile?>.broadcast();

  AuthRepositoryImpl({GoogleAuthDataSource? googleAuthDataSource})
      : _googleAuthDataSource = googleAuthDataSource ?? GoogleAuthDataSource() {
    _initCurrentUser();
  }

  Future<void> _initCurrentUser() async {
    final user = await _googleAuthDataSource.getCurrentUser();
    _authStateController.add(user);
  }

  @override
  Stream<UserProfile?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserProfile?> getCurrentUser() {
    return _googleAuthDataSource.getCurrentUser();
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    final user = await _googleAuthDataSource.signIn();
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _googleAuthDataSource.signOut();
    _authStateController.add(null);
  }
}
