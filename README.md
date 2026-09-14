<div align="center">

# Aura

### Modern • Modular • Cinematic Media Center

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Language-Dart%203-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows-lightgrey)](#supported-platforms)

A high-performance, modular cross-platform media client engineered with Flutter. Built with a clean editorial design aesthetic, decentralized HTTP/JSON add-on protocols, and native hardware-accelerated media rendering.

</div>

---

## Highlights

* 🎬 **Unified Catalog Discovery**: Powered by The Movie Database (TMDB) API for real-time trending releases, episode guides, high-res backdrops, and metadata lookups.
* 🔌 **Decoupled Add-on Architecture**: Native compliance with the **Stremio v3 Protocol specification**. Resolves stream manifests dynamically over HTTP/JSON without bundling third-party scrapers or stream hosts.
* ⚡ **Hardware-Accelerated Playback**: Built on `media_kit` (native `libmpv` bindings) for smooth 4K/HDR rendering, `.mkv`/HEVC/AV1 codec support, and styled ASS/SSA subtitle processing.
* ☁️ **Cloud Continuity**: Built-in **Firebase Authentication** with **Google Sign-In** and user-scoped state synchronization across devices (watch progress timestamps, continue watching shelf, watchlists, and installed add-on manifests).
* 🛡️ **App Store Compliant Footprint**: Native support for high-speed cloud debrid services (Real-Debrid, TorBox). P2P/BitTorrent modules are cleanly decoupled to allow direct iOS/App Store distribution.

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

### Prerequisites
* Flutter SDK (3.22+ recommended)
* Xcode 15+ (for macOS / iOS compilation)
* Android SDK 34+
* TMDB API Key

### Environment Setup
Create a `.env` file in the root directory:
```env
TMDB_API_KEY=your_api_key_here
TMDB_READ_ACCESS_TOKEN=your_v4_read_access_token_here
```

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

Launch on your platform:
```bash
# Desktop
flutter run -d macos
flutter run -d windows

# Mobile
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
| **Windows** | `media_kit` (Native mpv) | Direct HTTPS / Debrid / Local Engine |
| **Android TV** | `media_kit` (D-Pad remote navigation) | Direct HTTPS / Debrid / Local Engine |

---

## Legal & Compliance

* **Disclaimer:** Aura is an open-source media catalog organizer and playback interface. It does not host, stream, scrape, or distribute copyrighted media files. Please review the full [Legal Disclaimer](DISCLAIMER.md) for details.
* **License:** Distributed under the terms of the [MIT License](LICENSE).
