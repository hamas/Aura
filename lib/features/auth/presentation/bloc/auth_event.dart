import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}
class AuthCheckRequested extends CheckAuthStatusEvent {}

class SignInWithGoogleEvent extends AuthEvent {}
class SignInWithGoogleRequested extends SignInWithGoogleEvent {}

class SignOutEvent extends AuthEvent {}
class SignOutRequested extends SignOutEvent {}
