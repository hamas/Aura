import 'dart:async';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/google_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GoogleAuthDataSource _googleAuthDataSource;
  final StreamController<UserProfile?> _authStateController =
      StreamController<UserProfile?>.broadcast();
  StreamSubscription<UserProfile?>? _authSubscription;

  AuthRepositoryImpl({GoogleAuthDataSource? googleAuthDataSource})
      : _googleAuthDataSource = googleAuthDataSource ?? GoogleAuthDataSource() {
    _authSubscription = _googleAuthDataSource.authStateChanges.listen((user) {
      _authStateController.add(user);
    });
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
  Future<UserProfile> signInWithHouseholdPassword({
    required String email,
    required String password,
  }) async {
    final user = await _googleAuthDataSource.signInWithHouseholdPassword(
      email: email,
      password: password,
    );
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> setOrUpdateHouseholdPassword(String newPassword) {
    return _googleAuthDataSource.setOrUpdateHouseholdPassword(newPassword);
  }

  @override
  Future<bool> isHouseholdPasswordLinked() {
    return _googleAuthDataSource.isHouseholdPasswordLinked();
  }

  @override
  Future<void> signOut() async {
    await _googleAuthDataSource.signOut();
    _authStateController.add(null);
  }

  void dispose() {
    _authSubscription?.cancel();
    _authStateController.close();
  }
}
