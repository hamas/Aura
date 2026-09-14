import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure(
      [super.message = 'No internet connection or host unreachable.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load local cached data.']);
}

class AddonProtocolFailure extends Failure {
  const AddonProtocolFailure(super.message, {super.statusCode});
}

class PlaybackFailure extends Failure {
  const PlaybackFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class DebridFailure extends Failure {
  const DebridFailure(super.message, {super.statusCode});
}
