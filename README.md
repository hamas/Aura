# Aura
### Modern • Extensible • Cinematic Media Player
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Tests-119%20Passed-success.svg)](test)
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B.svg?logo=flutter)](https://flutter.dev)

Aura is a high-performance, store-safe media client engineered with Flutter. Built with an editorial design aesthetic, decentralized Stremio v3 protocol manifest support, and hardware-accelerated rendering powered by `media_kit` (libmpv).

---

## Key Features

- 🎬 **Unified Catalog Discovery:** Real-time trending media, episode guides, high-resolution backdrops, and metadata lookups powered by The Movie Database (TMDb) API.
- 🔌 **Decoupled Add-on Architecture:** Full compliance with the open Stremio v3 Protocol specification. Resolves media streams and external subtitles dynamically over HTTP/JSON manifests with zero bundled scrapers.
- 🔗 **1-Click Deep Linking:** Seamless installation of external manifests via custom schemes (`aura://addon/install?url=...`), standard HTTPS links, or manual URL inputs.
- ⚡ **Hardware-Accelerated Playback:** Built on `media_kit` (libmpv bindings) supporting 4K/HDR, dynamic buffer telemetry, styled ASS/SSA subtitles, multi-audio container switching, and automatic stream rollover failover.
- 📺 **TV Series Binge Flow:** Automatic next-episode countdown overlay during end credits, seamless playback transition, and an in-player season/episode selection sheet.
- 💾 **Sandboxed Offline Vault:** Secure, chunked media downloader with custom header forwarding (`User-Agent`, `Referer`), storage capacity verification, and `.nomedia` gallery protection.
- 💬 **Dynamic Subtitle Engine:** Automatic resolution of external `.srt` and `.vtt` subtitle tracks matching IMDb IDs, complete with language badging.
- 🔑 **Multi-Profile Household Management:** Hybrid authentication supporting Google Sign-In, household PIN protection, and personalized watch histories.
- 🛡️ **Store-Safe Neutral Shell:** Ships with zero hardcoded scraping endpoints or piracy indexing, complying with App Store Guideline 4.2 and Google Play IP policies.

---

## Architecture Overview

```text
lib/
├── app/         # GoRouter setup, App lifecycle, theme primitives
├── core/        # DeepLinkService, Network client (Dio), design tokens
└── features/
    ├── addons/    # Stremio v3 API parser, manifest models, setup sheet
    ├── auth/      # Authentication & multi-profile management
    ├── catalog/   # TMDb repository, discovery rails, detail views
    ├── clips/     # Short-form video trailer feed
    ├── downloads/ # DownloadExecutionManager, storage guards, vault
    ├── library/   # Watchlist, history, and HydratedBloc continuity
    └── player/    # MediaKitPlayerService, PlayerBloc, HUD overlays
```

---

## Getting Started

### Prerequisites

- **Flutter SDK:** 3.24+ (Dart 3.5+)
- **Android:** Android Studio, JDK 17, Target SDK 34+
- **iOS / macOS:** Xcode 15+, CocoaPods 1.14+
- **API Keys:** TMDb API Key, Firebase Project (Google Sign-In enabled)

### Configuration

1. Create a `.env` file in the project root:
   ```env
   TMDB_API_KEY=your_tmdb_api_key_here
   TMDB_READ_ACCESS_TOKEN=your_v4_read_access_token_here
   ```

2. Place standard Firebase configuration files:
   - **Android:** `android/app/google-services.json`
   - **iOS:** `ios/Runner/GoogleService-Info.plist`
   - **macOS:** `macos/Runner/GoogleService-Info.plist`

### Build & Run

```bash
# Clone repository
git clone https://github.com/hamas/Aura.git
cd Aura

# Fetch dependencies
flutter pub get

# Run test suite
flutter test

# Launch on device
flutter run -d macos
flutter run -d android
flutter run -d ios
```

---

## Supported Platforms

| Platform | Rendering Surface | Capabilities |
| :--- | :--- | :--- |
| **Android** | `media_kit` (libmpv / ExoPlayer) | Direct HTTP/HLS, Sandboxed Downloads, Hardware 4K |
| **iOS** | `media_kit` (libmpv Metal) | Direct HTTP/HLS, External Subtitles, Picture-in-Picture |
| **Android TV** | `media_kit` (D-Pad Navigation) | Direct HTTP/HLS, TV Binge Flow, Leanback Launcher |
| **macOS** | `media_kit` (libmpv Cocoa) | Direct HTTP/HLS, Keyboard Shortcuts, Multi-Window |

---

## Legal & Compliance

- **Disclaimer:** Aura is an open-source media catalog organizer and player shell. It does not host, stream, scrape, or distribute copyrighted media files. All metadata, imagery, and trailers are retrieved via official third-party APIs (TMDb). Playback capabilities rely entirely on user-configured external JSON manifests conforming to open community protocols.
- **License:** Distributed under the terms of the MIT License. See [LICENSE](LICENSE) for details.

