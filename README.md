# Aura - Modular Cross-Platform Media Center Client

**Aura** is a modular, high-performance cross-platform media center client built with 100% Flutter and Dart. It aggregates movie & TV metadata via TMDB, integrates the **Stremio v3 add-on protocol**, provides hardware-accelerated video playback via `media_kit` (libmpv), and supports Real-Debrid and cloud state synchronization via Google Sign-In.

---

## Features

- **Clean Architecture**: Strictly separated by `presentation`, `domain`, and `data` layers with feature-first structure.
- **Stremio v3 Add-on Protocol**: Supports community add-ons, manifest parsing, and `/stream/{type}/{id}.json` concurrent stream resolution using standardized IMDb identifiers.
- **Hardware-Accelerated Playback**: Powered by `media_kit` / `libmpv` supporting 4K HDR, MKV, multiple audio streams, and ASS subtitle rendering.
- **Platform-Safe Segregation**: BitTorrent/P2P capabilities are isolated behind conditional compilation flags so that **iOS builds remain 100% compliant with App Store guidelines** (HTTPS & Debrid streaming).
- **Real-Debrid Integration**: High-speed unrestricted streaming for hoster and torrent hashes.
- **Metadata Layer**: TMDB integration for trending carousels, detailed season/episode selectors, and live search.
- **Cloud State Sync**: Google Sign-In authentication with cross-device syncing for watchlist and timestamped watch progress.
- **Cinematic Dark Theme**: Custom dark UI palette with ambient blue/amber accents and gesture overlays.

---

## Directory Structure

```
lib/
├── app/
│   ├── app.dart                     # Main MaterialApp / Router & Bloc setup
│   ├── routes/                      # GoRouter declarative routing setup
│   └── theme/                       # Cinematic dark theme & tokens
├── core/
│   ├── constants/                   # API URLs, Stremio v3 protocol constants
│   ├── network/                     # Dio HTTP client, interceptors, error handling
│   ├── storage/                     # Secure storage (tokens) & local key-value store
│   ├── utils/                       # Formatters, debouncers, platform detectors
│   └── errors/                      # Failures, exceptions, and error mapping
├── features/
│   ├── auth/                        # Google Sign-In & account profile
│   ├── catalog/                     # TMDB discovery, search, and category carousels
│   ├── addons/                      # Add-on management & Stremio v3 protocol engine
│   ├── player/                      # Media playback & custom gesture controls
│   ├── debrid/                      # Real-Debrid API client & link unrestrictors
│   ├── library/                     # Watchlist, History, Continue Watching progress
│   └── engine/                      # Platform streaming engines (HTTP, Debrid, Torrent stubs)
└── main.dart                        # Dependency initialization & app launch
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev) (>= 3.16.0)
- Dart SDK (>= 3.2.0)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/hamas/Aura.git
   cd Aura
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run static analysis:
   ```bash
   flutter analyze
   ```
4. Run tests:
   ```bash
   flutter test
   ```
5. Launch the application:
   ```bash
   flutter run
   ```

---

## Target Platforms
- **Android**: Full streaming capabilities (Direct HTTPS, Debrid, and sequential proxy).
- **iOS**: Strictly compliant with App Store guidelines (Direct HTTPS & Debrid streaming).
- **macOS / Windows / Linux**: Desktop media center mode with native libmpv acceleration.
