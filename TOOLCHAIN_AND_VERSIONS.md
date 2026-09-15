# Aura Media Center — Toolchain & Dependency Reference

This document serves as the authoritative toolchain, environment specification, dependency manifest, language policy, and troubleshooting playbook for the **Aura** cross-platform media center client.

---

## 1. Environment & Runtime Specifications

| Component | Target Version / Constraint | Notes |
| :--- | :--- | :--- |
| **Flutter SDK** | `>=3.24.0` | Production Channel: `stable` |
| **Dart SDK** | `>=3.2.0 <4.0.0` | Strong null-safety enabled |
| **Android AGP** | `9.1.0` | Configured in `android/settings.gradle.kts` |
| **Kotlin Gradle Plugin** | `2.4.0` | Declarative plugin management |
| **Android SDK (minSdkVersion)**| `24` (Android 7.0 Nougat) | MediaKit & hardware decoding requirement |
| **Android SDK (compileSdkVersion)**| `35` (Android 15) | Modern Android API surfaces |
| **Android SDK (targetSdkVersion)**| `35` (Android 15) | Optimal runtime performance |
| **iOS Deployment Target** | `14.0+` | Metal & AVFoundation hardware acceleration |
| **macOS Deployment Target** | `11.0+` (Big Sur) | Apple Silicon & x86_64 dual architecture |

---

## 2. Dependency Manifest & Architecture Mapping

Below is the production dependency breakdown locked via `pubspec.lock`:

| Package Category | Dependency | Constrained Range | Architectural Role in Aura |
| :--- | :--- | :--- | :--- |
| **State Management** | `flutter_bloc` | `^9.1.1` | Event-driven UI state management across auth, downloads, clips, & library |
| | `hydrated_bloc` | `^11.0.0` | Persistent state engine for user preferences & active session states |
| | `equatable` | `^2.0.7` | Efficient value comparison for BLoC states & domain entities |
| **Navigation & Routing** | `go_router` | `^18.0.1` | Declarative URL routing, sub-pages, modal routing, & deep linking |
| **Playback Engine** | `media_kit` | `^1.1.11` | Cross-platform core video player engine (libmpv wrapper) |
| | `media_kit_video` | `^2.0.1` | Native hardware-accelerated video rendering widgets |
| | `media_kit_libs_video` | `^1.0.5` | Bundled FFmpeg & libmpv native binaries |
| **Networking & API** | `dio` | `^5.8.0+1` | HTTP engine for Stremio add-ons & TMDB API with interceptors |
| | `http` | `^1.2.1` | Standard HTTP client requests |
| | `flutter_dotenv` | `^6.0.1` | Environment variable management (`.env`) |
| **Authentication & Cloud** | `firebase_core` | `^4.15.0` | Firebase app bootstrap |
| | `firebase_auth` | `^6.7.0` | User account lifecycle & multi-device sync |
| | `google_sign_in` | `^6.2.2` | OAuth 2.0 Google Account Sign-In flow |
| | `supabase_flutter` | `^2.8.4` | Backend real-time synchronization |
| **Storage & Security** | `flutter_secure_storage` | `^11.1.1` | Hardware-backed key/value vault (Real-Debrid API keys, Auth Tokens) |
| | `shared_preferences` | `^2.3.5` | Fast synchronous key-value storage for active profiles & UI settings |
| | `path_provider` | `^2.1.5` | Sandboxed local disk access for downloads & caches |
| **Device & Utilities** | `package_info_plus` | `^10.2.1` | App metadata inspection (resolved KGP deprecation warning) |
| | `wakelock_plus` | `^1.8.0` | Video playback screen wake-lock prevention (resolved KGP deprecation warning) |
| | `connectivity_plus` | `^7.3.1` | Network state tracking (Wi-Fi, Cellular, Offline mode) |
| | `cached_network_image` | `^4.0.0` | Memory and disk image caching with blur hash placeholders |

---

## 3. Strict 100% Dart Language Policy

Aura strictly enforces a **100% Dart-First Architectural Standard**:

1. **Pure Dart Implementation**: All application logic, gesture routing, player controls, custom math layout calculations, state machines, and data serialization must be written purely in Dart.
2. **No Custom Native Code**: Writing custom Kotlin, Java, Objective-C, or Swift inside `android/` or `ios/` is prohibited unless wrapped and published as a reusable, open-source Flutter plugin.
3. **Plugin Wrapper Isolation**: Native capabilities (such as libmpv bindings or Firebase platform implementations) are accessed strictly through established, audited Flutter plugins maintained by the community or Flutter team.

---

## 4. Troubleshooting & Toolchain Playbook

### Problem 1: Built-in Kotlin Gradle Plugin (KGP) Deprecation Warnings
* **Symptom**: Warning during Gradle build: *"Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP)..."*
* **Root Cause**: Outdated third-party plugins using deprecated KGP Gradle application patterns instead of standard Flutter Gradle integration.
* **Resolution**:
  1. Check outdated plugins: `flutter pub outdated`
  2. Upgrade plugins to versions using modern Flutter plugin loader:
     ```bash
     flutter pub upgrade --major-versions
     ```
  3. Verify `android/settings.gradle.kts` uses declarative plugin management:
     ```kotlin
     plugins {
         id("dev.flutter.flutter-plugin-loader") version "1.0.0"
         id("com.android.application") version "9.1.0" apply false
         id("org.jetbrains.kotlin.android") version "2.4.0" apply false
     }
     ```

---

### Problem 2: Gradle Daemon & Cache Corruption
* **Symptom**: Unexplained Gradle compilation errors, missing symbols, or stuck daemon threads.
* **Resolution**:
  ```bash
  # 1. Purge Flutter build artifacts & pub cache locks
  flutter clean

  # 2. Stop running Gradle daemons (Android)
  cd android && ./gradlew --stop && cd ..

  # 3. Clear Gradle user home cache (optional if persistent)
  rm -rf ~/.gradle/caches/

  # 4. Re-fetch clean dependencies
  flutter pub get
  ```

---

### Problem 3: Dependency Version Conflicts (`pub get` Failure)
* **Symptom**: `pub get` fails with `version solving failed` error.
* **Resolution**:
  1. Inspect dependency graph:
     ```bash
     flutter pub deps
     ```
  2. Identify conflicting transient packages.
  3. Apply temporary dependency overrides in `pubspec.yaml` if needed:
     ```yaml
     dependency_overrides:
       package_name: ^x.y.z
     ```

---

### Problem 4: Platform-Specific Cache Locks (Android `.cxx` / iOS CocoaPods)
* **Android C++ / CMake Cache Lock**:
  ```bash
  rm -rf android/.cxx/ android/app/.cxx/ android/.gradle/ android/build/ android/app/build/
  ```
* **iOS / macOS Pod & DerivedData Reset**:
  ```bash
  cd ios && rm -rf Pods Podfile.lock ~/Library/Developer/Xcode/DerivedData/* && pod install --repo-update && cd ..
  ```
