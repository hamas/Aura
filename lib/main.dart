import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase App
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Graceful fallback if platform configuration is bypassed in mock tests
  }

  // Load Environment Variables (.env)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Gracefully handle if .env is missing in standalone test environments
  }

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
