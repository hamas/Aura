# Aura — Comprehensive Codebase & Architecture Analysis

> **Date:** September 25, 2026  
> **Repository:** Aura (`aura-flutter` & `aura-swift`)  
> **Core Focus:** Modular, Decentralized, Multi-Platform Cinematic Media Center Client

---

## 1. Executive Summary

**Aura** is a modular media streaming and discovery ecosystem engineered across two tracks:
- **`aura-flutter`**: A cross-platform client (Android, iOS, macOS, Android TV) leveraging Flutter, BLoC/HydratedBloc, and `media_kit` (`libmpv` native bindings).
- **`aura-swift`**: A native Apple platform client built with SwiftUI, Combine, and `AVFoundation` (`AVPlayer`).

Aura combines an Apple TV+ / Netflix-grade cinematic interface with decentralized protocol integrations, including:
- **Stremio v3 Add-on Protocol**: Dynamic discovery of external catalogs, metadata, and streaming endpoints.
- **Debrid & Torrent Resolvers**: Support for Real-Debrid, Premiumize, TorBox, and local torrent proxying.
- **Trakt.tv Scrobbling**: Bidirectional synchronization for watched status, progress, and ratings.
- **Synchronized Playback (WatchTogether)**: Multi-user room synchronization via WebSockets / Supabase.
- **Clips / Reels Feed**: Vertical, short-form trailer browsing with immediate watchlist triage.

---

## 2. Repository Layout & Architecture

```
Aura/
├── aura-flutter/                         # Cross-Platform Flutter Codebase
│   ├── lib/
│   │   ├── app/                          # Routing (GoRouter), App Entrypoint & Theme
│   │   ├── core/                         # Core Infrastructure
│   │   │   ├── config/                   # App Environment & Constants
│   │   │   ├── constants/                # UI Tokens, Endpoints & API Keys
│   │   │   ├── errors/                   # Failure & Exception Definitions
│   │   │   ├── network/                  # Dio HTTP Client & Interceptors
│   │   │   ├── presentation/             # Reusable UI Primitives & Glassmorphic Scaffolds
│   │   │   ├── security/                 # Secure Storage, Vault & Privacy Shield
│   │   │   ├── services/                 # Downloader, Filter, Ranking Services
│   │   │   ├── storage/                  # Hydrated Storage & SharedPreferences
│   │   │   ├── theme/                    # App Colors, Typography & Design Tokens
│   │   │   └── utils/                    # Formatters, Extensions & Helpers
│   │   └── features/                     # Feature Modules (Domain, Data & Presentation)
│   │       ├── addons/                   # Stremio Add-on Manager & Manifest Parsing
│   │       ├── auth/                     # Authentication (Firebase / Supabase)
│   │       ├── catalog/                  # TMDB Discovery, Hero Carousel & Shelves
│   │       ├── clips/                    # Vertical Shorts / Video Trailer Reels
│   │       ├── downloads/                # Sandboxed Offline Media Manager
│   │       ├── engine/                   # Debrid & Torrent Stream Extraction
│   │       ├── library/                  # Watchlist, Watch History & Bookmark State
│   │       ├── player/                   # MediaKit (libmpv) Video Playback Engine
│   │       ├── profiles/                 # Multi-Profile Manager & PIN Lock
│   │       ├── search/                   # Universal Search & Filtering
│   │       ├── settings/                 # Playback, Subtitle & Engine Preferences
│   │       ├── streams/                  # Stream Quality Scoring & Selection
│   │       ├── trakt/                    # Trakt.tv Integration & Scrobbler
│   │       ├── tv/                       # Android TV D-Pad Navigation Support
│   │       └── watch_together/           # Real-Time Shared Playback Rooms
│   ├── android/                          # Native Android Configuration
│   ├── ios/                              # Native iOS Runner
│   ├── macos/                            # Native macOS Runner
│   ├── docs/                             # Project Documentation & Guides
│   └── pubspec.yaml                      # Flutter Dependencies & Assets
│
├── aura-swift/                           # Native Apple Track (Swift / SwiftUI)
│   ├── Aura.xcodeproj                   # Xcode Project Configuration
│   ├── Shared/                           # Shared iOS & macOS Code
│   │   ├── AuraApp.swift                 # App Lifecycle & Audio Session Setup
│   │   ├── Config/                       # Environment & Constants
│   │   ├── Models/                       # MediaItem, StreamOption, CastMember
│   │   ├── Networking/                   # APIClient (TMDB & Add-on HTTP calls)
│   │   ├── Services/                     # AVPlayerManager, StreamResolver, TorrentEngine
│   │   └── Views/                        # SwiftUI Modules (Feed, Player, Addons, etc.)
│   ├── iOS/                              # iOS Target Views & Adjustments
│   └── macOS/                            # macOS Window Styles & Menu Handlers
│
├── build/                                # Build Artifacts & Intermediate Outputs
└── scripts/                              # Automation Scripts (e.g. dev-macos.sh)
```

---

## 3. Deep Dive: `aura-flutter`

### 3.1 Architectural Pattern
The Flutter application is structured around **Clean Architecture with BLoC State Management**:
- **Presentation Layer**: Built using `flutter_bloc` and `GoRouter` declarative navigation with an isolated root navigator for full-screen video player modals.
- **Domain Layer**: Independent entities (`MediaItem`, `AddonManifest`, `AddonStream`, `DownloadTask`, `UserProfile`) and business services (`SmartDownloadManager`, `StreamRankerService`).
- **Data Layer**: Dio HTTP client, `HydratedBloc` persistence, `FlutterSecureStorage`, and `media_kit` hardware-accelerated playback.

### 3.2 State Management & Persistence
- **Hydrated BLoC (`hydrated_bloc`)**: Used across `LibraryBloc`, `SettingsBloc`, and `AddonBloc` to guarantee instantaneous state restoration across app restarts without manual database queries.
- **Secure Storage (`flutter_secure_storage`)**: Encrypted storage of sensitive credentials, including Debrid API keys, Trakt OAuth tokens, and user profile PINs.
- **Smart Download Manager**: Handles chunked downloads into an app-sandboxed encrypted vault with automated resumption on network reconnections.

### 3.3 Media Player Subsystem
- **Engine**: Wraps native `libmpv` using `media_kit` and `media_kit_video`.
- **Capabilities**:
  - Hardware-accelerated decoding (H.264, HEVC, AV1, VP9).
  - External and embedded subtitle selection (SRT, VTT, ASS/SSA styling).
  - Multi-track audio switching (Dolby Digital Plus, DTS, AAC).
  - Dynamic playback rate modification (0.5x to 2.0x).
  - Auto-scrobbling watch milestones to Trakt (start, pause, complete at 80%+ threshold).

### 3.4 Visual Design System
- **Theme Palette**: Deep dark aesthetics (`#0E0F12`, `#14161B`, `#1B1E26`) accented with `#FF2D55` (Pink Glow), `#E50914` (Cinema Red), and `#F5C518` (IMDb Gold).
- **Typography**: Google Fonts Outfit (Display headers) and Inter (Body & metadata).
- **Glassmorphic UI**: `AuraFloatingBottomPill`, `AuraCard`, and `AuraAdaptiveAppBar` using `BackdropFilter` Gaussian blur effects.
- **Privacy Shield**: `_PrivacyCurtainWrapper` automatically blurs and protects screen contents when the application loses focus or is placed in the background.

---

## 4. Deep Dive: `aura-swift`

### 4.1 Architectural Pattern
The Swift application targets iOS and macOS natively with:
- **Framework**: SwiftUI + Combine.
- **State Management**: `@StateObject` and `@ObservedObject` observable view models.
- **Media Engine**: Native `AVPlayer` with custom HUD controls (`CustomPlayerHUD.swift`) and Picture-in-Picture lifecycle management (`PictureInPictureController.swift`).

### 4.2 Core Swift Services
- **`AVPlayerManager.swift`**: Controls `AVQueuePlayer` playback sessions, time observers, buffering state, and custom audio session routing.
- **`APIClient.swift`**: Asynchronous networking layer for TMDB v3 APIs and Stremio add-on manifest resolution via `URLSession`.
- **`StreamResolverService.swift`**: Ranks and resolves stream playback URLs from various configured add-on providers.
- **`LocalTorrentProxyEngine.swift`**: Local embedded HTTP proxy enabling `AVPlayer` to stream sequential chunks of torrent files directly.

---

## 5. Feature Comparison Matrix

| Feature | `aura-flutter` | `aura-swift` |
| :--- | :---: | :---: |
| **Catalog & Hero Carousel** | ✅ Full TMDB + Custom Filters | ✅ Full TMDB + Shelves |
| **Media Player Engine** | ✅ `media_kit` (`libmpv`) | ✅ `AVPlayer` (`AVFoundation`) |
| **Stremio Add-on Protocol** | ✅ Full Manifest & Stream Query | ✅ Manifest & Stream Query |
| **Debrid Unrestricting** | ✅ Real-Debrid / TorBox / Premiumize | ✅ Supported in Resolver |
| **Torrent Streaming** | ✅ Native / Proxy Support | ✅ `LocalTorrentProxyEngine` |
| **Clips / Reels Feed** | ✅ Full-Screen Video Reel | 🔄 In Progress |
| **Offline Download Vault** | ✅ `SmartDownloadManager` | ✅ Basic File Downloads |
| **Trakt.tv Scrobbling** | ✅ OAuth2 + Scrobble API | 🔄 In Progress |
| **WatchTogether (Rooms)** | ✅ WebSockets + Supabase | 🔄 In Progress |
| **Multi-Profile & PINs** | ✅ Firebase / Supabase Profiles | 🔄 In Progress |
| **Android TV & D-Pad** | ✅ Native D-Pad Navigation | N/A (Apple Platforms) |
| **Picture-in-Picture** | ✅ Supported | ✅ Supported |

---

## 6. Key Strengths & Architectural Insights

1. **Protocol Agnostic Architecture**: Stremio v3 protocol support allows dynamic extension of streaming sources without requiring app rebuilds or updates.
2. **Superior Playback Flexibility**: In Flutter, `libmpv` provides unmatched codec support across desktop and mobile, bypassing native OS container restrictions.
3. **Resilient Local State**: `HydratedBloc` ensures persistent navigation and playback history even when offline.
4. **Platform Adaptability**: Responsive design adjusts gracefully between mobile touch screens, desktop multi-window setups, and Android TV 10-foot interfaces.

---

## 7. Recommendations & Strategic Roadmap

1. **Decide Track Unification vs. Specialization**:
   - Maintain `aura-flutter` as the unified cross-platform hub (covering Android, Android TV, macOS, iOS, Windows/Linux).
   - Position `aura-swift` for deep native Apple integration (e.g. Apple TV tvOS target, native Mac menu bars, Widgets, and Shortcuts).
2. **Testing & QA**:
   - Expand unit tests for `StreamRankerService`, `AddonBloc`, and `SmartDownloadManager`.
   - Add integration tests for end-to-end stream resolution and playback flows.
3. **App Store Sandbox & Entitlements**:
   - Ensure local torrent proxy sockets and networking permissions comply with Apple sandbox restrictions when targeting the macOS App Store.
