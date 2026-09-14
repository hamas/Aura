import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Native Playback Engine Bindings (libmpv wrapper)
  MediaKit.ensureInitialized();

  // Initialize Shared Preferences for Fast Local Add-on & UI Persistence
  final prefs = await SharedPreferences.getInstance();

  // Initialize Hydrated BLoC Storage
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );

  runApp(AuraApp(prefs: prefs));
}
