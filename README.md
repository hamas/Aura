<div align="center">

# Aura

### Modern • Modular • Cinematic Media Center

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Language-Dart%203-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20macOS-lightgrey)](#supported-platforms)

A high-performance, modular cross-platform media client engineered with Flutter. Built with a clean editorial design aesthetic, decentralized HTTP/JSON add-on protocols, and native hardware-accelerated media rendering.

</div>

---

* 🎬 **Unified Catalog Discovery**: Powered by The Movie Database (TMDB) API for real-time trending releases, episode guides, high-res backdrops, and metadata lookups.
* 🔌 **Decoupled Add-on Architecture**: Native compliance with the **Stremio v3 Protocol specification**. Resolves stream manifests dynamically over HTTP/JSON without bundling third-party scrapers or stream hosts.
* ⚡ **Hardware-Accelerated Playback**: Built on `media_kit` (native `libmpv` bindings) for smooth 4K/HDR rendering, `.mkv`/HEVC/AV1 codec support, and styled ASS/SSA subtitle processing.
* 🔑 **Hybrid Authentication & Multi-Profile Household Management**:
  - **Google Sign-In**: Account owners log in via Google to access system settings and manage custom household profiles.
  - **Household Member Sign-In**: Family members log in using the owner's email and linked Household Password to land directly on their personalized *"Who's watching?"* profile selection screen.
  - **Multi-Profiles**: Create up to 3 individual custom profiles with customizable glossy gradient avatars, PIN protection, and content rating filters.
* ☁️ **Cloud Continuity**: User-scoped state synchronization across devices (watch progress timestamps, continue watching shelf, watchlists, and installed add-on manifests).
* 🛡️ **App Store Compliant & 100% Dart-First Policy**: All app logic, state management, UI, and data handling are strictly implemented in pure Dart. High-speed cloud debrid integrations (Real-Debrid, TorBox) operate over secure HTTPS without requiring embedded scrapers.

---

## System Architecture

```text
lib/
├── app/         # Navigation (GoRouter), Theme tokens, App lifecycle
├── core/        # Network client (Dio), local storage, protocol constants
└── features/
    ├── auth/    # Google Sign-In & account profile management
    ├── catalog/ # TMDB integration, media shelves, search, and detail views
    ├── addons/  # Stremio v3 manifest parser & stream resolver
    ├── player/  # MediaKit controller, playback overlays, track selector
    ├── debrid/  # Multi-hoster link unrestrictor & token handlers
    ├── library/ # Watchlist, history, and cloud sync repository
    └── engine/  # Platform-specific streaming abstractions
```

---

## Prerequisites & Toolchain

### Runtime Environment Specifications

| Component | Constraint / Target | Notes |
| :--- | :--- | :--- |
| **Flutter SDK** | `>=3.16.0` (3.24+ recommended) | Production Channel: `stable` |
| **Dart SDK** | `>=3.2.0 <4.0.0` | Strong null-safety enabled |
| **Android AGP** | `8.11.1` | Configured in `android/settings.gradle.kts` |
| **Gradle Wrapper** | `8.14` | Configured in `android/gradle/wrapper/gradle-wrapper.properties` |
| **Kotlin Plugin** | `2.2.20` | Declarative plugin management |
| **Android SDK** | `minSdkVersion: 24`, `compileSdkVersion: 35` | Android 7.0+ for hardware decoding |
| **iOS / macOS Target**| iOS 14.0+ / macOS 11.0+ | Metal & AVFoundation hardware acceleration |

### Strict 100% Dart-First Policy
1. **Pure Dart Implementation**: All application logic, gesture routing, player controls, custom math layout calculations, state machines, and data serialization are written purely in Dart.
2. **No Custom Native Code**: Writing custom Kotlin, Java, Objective-C, or Swift inside `android/`, `ios/`, or `macos/` is prohibited unless wrapped and published as a reusable, open-source Flutter plugin.
3. **Plugin Wrapper Isolation**: Native capabilities (libmpv bindings, Firebase platform implementations) are accessed strictly through established, audited Flutter plugins.

---

## Getting Started

### Environment & Firebase Setup
1. Create a `.env` file in the root directory:
```env
TMDB_API_KEY=your_api_key_here
TMDB_READ_ACCESS_TOKEN=your_v4_read_access_token_here
```
2. Place your official Firebase configuration files:
   - **Android**: Place `google-services.json` inside `android/app/`
   - **iOS**: Place `GoogleService-Info.plist` inside `ios/Runner/`
   - **macOS**: Place `GoogleService-Info.plist` inside `macos/Runner/`

### Installation & Run

Clone repository:
```bash
git clone https://github.com/dumbhamas/Aura.git
cd Aura
```

Fetch packages:
```bash
flutter pub get
```

Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Launch on your active target platform:
```bash
# Mobile
flutter run -d android
flutter run -d ios

# Desktop
flutter run -d macos
```

---

## Supported Platforms

| Platform | Playback Architecture | Stream Support |
| :--- | :--- | :--- |
| **Android** | `media_kit` (ExoPlayer / mpv) | Direct HTTPS / Debrid / Local Engine |
| **iOS** | `media_kit` (Native mpv) | Direct HTTPS / Debrid |
| **macOS** | `media_kit` (Native mpv) | Direct HTTPS / Debrid / Local Engine |
| **Android TV** | `media_kit` (D-Pad remote navigation) | Direct HTTPS / Debrid / Local Engine |

---

## Legal & Disclaimers

### 1. Non-Hosting & Pure Client Architecture
Aura is strictly a client-side media player and organizer. Aura does **not**:
- Host, store, mirror, cache, stream, or transmit any audio-visual files, video files, or digital media.
- Maintain, operate, index, or track torrent databases, magnet links, or scrape listings.
- Operate any backend servers that aggregate, broadcast, or index copyrighted video streams.

The software functions solely as a graphical interface and player engine for user-configured remote and local resources.

### 2. Third-Party Metadata & TMDB Attribution
- All metadata, titles, descriptions, cast listings, release dates, and posters rendered within Aura are fetched via public API integrations, including **The Movie Database (TMDB)**.
- This product uses the TMDB API but is **not endorsed, certified, or otherwise approved by TMDB**.
- All copyrighted media titles, trademarks, and associated promotional artwork displayed belong entirely to their respective copyright holders.

### 3. Decoupled Add-on Protocol & External Services
- Aura implements a modular, decentralized HTTP/JSON add-on manifest standard (**Stremio v3 Protocol**).
- The application binary ships **completely devoid of pre-installed scrapers, stream providers, torrent indexers, or unauthorized third-party extensions**.
- Any installation, activation, or configuration of external add-on URLs, Debrid services (such as Real-Debrid), or cloud storage providers is initiated solely by the end user.

### 4. End-User Compliance & License
- Aura is provided strictly for lawful, personal media management. Users are solely responsible for ensuring that their playback sources comply with applicable laws.
- Distributed under the terms of the [MIT License](LICENSE).
