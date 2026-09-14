# Aura

> A modern, modular, cross-platform media center client built with Flutter.

Aura is a high-performance media aggregator and video player engineered for speed, clean typography, and spacious visual aesthetics. Built around a decoupled architecture, Aura combines rich catalog discovery, an extensible server-side JSON add-on protocol, and hardware-accelerated playback across mobile, desktop, and TV platforms.

---

## Key Features

### 🎬 Discovery & Rich Metadata
* **Unified Media Catalog:** Real-time trending movies, series, and curated collections powered by The Movie Database (TMDB).
* **Cinematic Detail Views:** High-resolution backdrops, cast filmographies, seasonal breakdowns, and release metadata.
* **Universal ID Mapping:** Standardized IMDb/TMDB primary keys to ensure immediate compatibility across decentralized metadata and stream indexes.

### 🔌 Extensible Add-on Architecture
* **Stremio v3 Protocol Compatible:** Native support for server-side JSON add-on manifests (`/manifest.json`).
* **Decoupled Stream Resolution:** No hardcoded scrapers or internal stream hosts. Streams are resolved dynamically via user-installed HTTP/JSON add-on microservices.
* **Custom Add-on Management:** Install, configure, or remove community endpoints with zero app recompilation.

### ⚡ Performance Playback Engine
* **Native MediaKit Integration:** Hardware-accelerated media rendering powered by native `libmpv` bindings.
* **Universal Format Support:** Out-of-the-box playback for `.mkv`, `.mp4`, H.265/HEVC, AV1, and multi-channel audio tracks (Dolby Digital, DTS, Atmos).
* **Advanced Subtitle Styling:** Real-time subtitle synchronization offsets, styled ASS/SSA subtitle rendering, and OpenSubtitles API integration.

### ☁️ Cloud Sync & Continuity
* **Google Authentication:** Frictionless one-tap sign-in.
* **Cross-Device State Sync:** Synchronize installed add-ons, personal watchlists, and exact playback progress timestamps across all active devices.

### 🛡️ App Store Safe Architecture
* **HTTPS/Debrid Native:** First-class support for cloud debrid services (Real-Debrid, TorBox) delivering fast, encrypted direct streams.
* **Platform-Isolated Engine:** P2P/BitTorrent layers are strictly decoupled and excluded from iOS build targets via conditional compilation, keeping iOS App Store compliant.

---

## Architecture Overview

Aura follows Clean Architecture principles with a strict feature-first structure:

```text
lib/
├── app/         # App initialization, GoRouter navigation, theme tokens
├── core/        # Network (Dio), error abstractions, constants, local storage
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

## Tech Stack

* **Framework:** [Flutter](https://flutter.dev) (Dart 3)
* **Media Playback:** [`media_kit`](https://github.com/media-kit/media-kit) (C/FFI `libmpv` bindings)
* **State Management:** `flutter_bloc`
* **Networking & Serialization:** `dio`, `freezed`, `json_serializable`
* **Local Persistence:** `flutter_secure_storage`, `shared_preferences`
* **Backend & Auth:** Google OAuth + Cloud Sync

---

## Getting Started

### Prerequisites
* Flutter SDK (3.22.0 or later recommended)
* Xcode 15+ (for iOS / macOS builds)
* Android Studio & Android SDK 34+
* A valid TMDB API Key

### Environment Setup
Create a `.env` file in the root directory:
```env
TMDB_API_KEY=your_tmdb_api_key_here
TMDB_READ_ACCESS_TOKEN=your_v4_read_access_token_here
```

### Installation

Clone the repository:
```bash
git clone https://github.com/dumbhamas/Aura.git
cd Aura
```

Install dependencies:
```bash
flutter pub get
```

Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Launch the application:
```bash
# For macOS Desktop
flutter run -d macos

# For Android
flutter run -d android

# For iOS
flutter run -d ios
```

---

## Supported Platforms

| Platform | Status | Playback Engine |
| :--- | :--- | :--- |
| **Android** | Supported | `media_kit` (ExoPlayer / mpv) |
| **iOS** | Supported | `media_kit` (Debrid / HTTPS direct) |
| **macOS** | Supported | `media_kit` (Native libmpv) |
| **Windows** | Supported | `media_kit` (Native libmpv) |
| **Android TV** | Planned | D-Pad remote focus navigation |

---

## Disclaimer

Aura is a client-side media catalog organizer and video player. It does not host, distribute, or stream any media files or torrents directly. Users are solely responsible for any third-party add-ons installed and the content accessed through them.

---

## License

This project is licensed under the [MIT License](LICENSE).
