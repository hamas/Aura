# Aura
### Modern • Modular • Cinematic Media Center
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A high-performance, modular cross-platform media client engineered with Flutter. Built with a clean editorial design aesthetic, decentralized HTTP/JSON add-on protocols, and native hardware-accelerated media rendering.

- 🎬 **Unified Catalog Discovery:** Powered by The Movie Database (TMDB) API for real-time trending releases, episode guides, high-res backdrops, and metadata lookups.
- 🔌 **Decoupled Add-on Architecture:** Native compliance with the Stremio v3 Protocol specification. Resolves stream manifests dynamically over HTTP/JSON without bundling third-party scrapers or stream hosts.
- ⚡ **Hardware-Accelerated Playback:** Built on `media_kit` (native `libmpv` bindings) for smooth 4K/HDR rendering, `.mkv`/HEVC/AV1 codec support, and styled ASS/SSA subtitle processing.
- 🔑 **Hybrid Authentication & Multi-Profile Household Management:**
  - **Google Sign-In:** Account owners log in via Google to access system settings and manage custom household profiles.
  - **Household Member Sign-In:** Family members log in using the owner's email and linked Household Password to land directly on their personalized "Who's watching?" profile selection screen.
  - **Multi-Profiles:** Create up to 3 individual custom profiles with customizable glossy gradient avatars, PIN protection, and content rating filters.
- ☁️ **Cloud Continuity:** User-scoped state synchronization across devices (watch progress timestamps, continue watching shelf, watchlists, and installed add-on manifests).
- 🛡️ **App Store Compliant & 100% Dart-First Policy:** All app logic, state management, UI, and data handling are strictly implemented in pure Dart. High-speed cloud debrid integrations (Real-Debrid, TorBox) operate over secure HTTPS without requiring embedded scrapers.

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

## Getting Started

### Toolchain & Prerequisites

- ⚬ **Flutter SDK:** 3.24+ (Dart 3.5+)
- ⚬ **macOS / iOS:** Xcode 15+, CocoaPods 1.14+
- ⚬ **Android:** Android SDK 34+, JDK 17
- ⚬ **Services:** TMDB API Key, Firebase Project (Google Sign-In enabled)

### Environment & Configuration

1. Create a `.env` file in the project root:
   ```env
   TMDB_API_KEY=your_api_key_here
   TMDB_READ_ACCESS_TOKEN=your_v4_read_access_token_here
   ```
2. Place the Firebase configuration files:
   - ⚬ **Android:** `android/app/google-services.json`
   - ⚬ **iOS:** `ios/Runner/GoogleService-Info.plist`
   - ⚬ **macOS:** `macos/Runner/GoogleService-Info.plist`

### Installation & Run

```bash
# Clone repository
git clone https://github.com/dumbhamas/Aura.git
cd Aura

# Fetch dependencies
flutter pub get

# Generate build outputs
flutter pub run build_runner build --delete-conflicting-outputs

# Run on your target device
flutter run -d macos
flutter run -d android
flutter run -d ios
```

---

## Supported Platforms

| Platform | Playback Architecture | Stream Support |
| :--- | :--- | :--- |
| **Android** | `media_kit` (ExoPlayer / mpv) | Direct HTTPS / Debrid / Local Engine |
| **iOS** | `media_kit` (Native mpv) | Direct HTTPS / Debrid |
| **macOS** | `media_kit` (Native mpv) | Direct HTTPS / Debrid / Local Engine |
| **Android TV** | `media_kit` (D-Pad navigation) | Direct HTTPS / Debrid / Local Engine |

---

## Legal & Compliance

- ⚬ **Disclaimer:** Aura is an open-source media catalog organizer and playback interface. It does not host, stream, scrape, or distribute copyrighted media files. All metadata, imagery, and synopsis data are retrieved via official third-party APIs (TMDB). Streaming capabilities rely entirely on user-provided add-on manifests conforming to open decentralized protocols.
- ⚬ **License:** Distributed under the terms of the MIT License. See [LICENSE](LICENSE) for details.
