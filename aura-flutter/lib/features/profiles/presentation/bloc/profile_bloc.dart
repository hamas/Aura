import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/repositories/profile_repository.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfilesEvent extends ProfileEvent {}

class SelectProfileEvent extends ProfileEvent {
  final UserProfile profile;
  final String? inputPin;

  const SelectProfileEvent({required this.profile, this.inputPin});

  @override
  List<Object?> get props => [profile, inputPin];
}

class SaveProfileEvent extends ProfileEvent {
  final UserProfile profile;

  const SaveProfileEvent(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DeleteProfileEvent extends ProfileEvent {
  final String profileId;

  const DeleteProfileEvent(this.profileId);

  @override
  List<Object?> get props => [profileId];
}

// States
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitialState extends ProfileState {}

class ProfileLoadingState extends ProfileState {}

class ProfileLoadedState extends ProfileState {
  final List<UserProfile> profiles;
  final UserProfile activeProfile;
  final String? errorMessage;

  const ProfileLoadedState({
    required this.profiles,
    required this.activeProfile,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [profiles, activeProfile, errorMessage];
}

class ProfilePinRequiredState extends ProfileState {
  final UserProfile targetProfile;

  const ProfilePinRequiredState(this.targetProfile);

  @override
  List<Object?> get props => [targetProfile];
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc(this.repository) : super(ProfileInitialState()) {
    on<LoadProfilesEvent>(_onLoadProfiles);
    on<SelectProfileEvent>(_onSelectProfile);
    on<SaveProfileEvent>(_onSaveProfile);
    on<DeleteProfileEvent>(_onDeleteProfile);
  }

  Future<void> _onLoadProfiles(
    LoadProfilesEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadingState());
    try {
      final profiles = await repository.getProfiles();
      final active = await repository.getActiveProfile() ?? profiles.first;
      emit(ProfileLoadedState(profiles: profiles, activeProfile: active));
    } catch (e) {
      final fallback = UserProfile(
        id: 'default',
        name: 'Main Profile',
        avatarPath: '',
        createdAt: DateTime.now(),
      );
      emit(ProfileLoadedState(
          profiles: [fallback],
          activeProfile: fallback,
          errorMessage: e.toString()));
    }
  }

  Future<void> _onSelectProfile(
    SelectProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final target = event.profile;
    if (target.hasPin &&
        (event.inputPin == null || !target.verifyPin(event.inputPin!))) {
      emit(ProfilePinRequiredState(target));
      return;
    }

    try {
      await repository.setActiveProfile(target.id);
      final profiles = await repository.getProfiles();
      emit(ProfileLoadedState(profiles: profiles, activeProfile: target));
    } catch (e) {
      add(LoadProfilesEvent());
    }
  }

  Future<void> _onSaveProfile(
    SaveProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await repository.saveProfile(event.profile);
      add(LoadProfilesEvent());
    } catch (e) {
      add(LoadProfilesEvent());
    }
  }

  Future<void> _onDeleteProfile(
    DeleteProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await repository.deleteProfile(event.profileId);
      add(LoadProfilesEvent());
    } catch (e) {
      add(LoadProfilesEvent());
    }
  }
}
