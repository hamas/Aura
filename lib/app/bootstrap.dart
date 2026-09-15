import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Bootstrap runner wrapping application startup inside a secure zoned error boundary.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // In production release builds, log asynchronously or send to Crashlytics
      Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.empty);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kReleaseMode) {
      // Prevent unhandled async errors from crashing release binaries silently
      debugPrint('Bootstrap Uncaught Async Error: $error');
    }
    return true;
  };

  unawaited(
    runZonedGuarded<Future<void>>(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        final appWidget = await builder();
        runApp(appWidget);
      },
      (Object error, StackTrace stack) {
        debugPrint('Zoned Guarded Exception Caught: $error\n$stack');
      },
    ),
  );
}
