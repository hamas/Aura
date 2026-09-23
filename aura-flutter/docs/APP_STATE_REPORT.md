# Aura — App State & Architectural Audit Report

**Generated Date:** September 18, 2026  
**Target Repository:** `Aura` (`/Users/hamas/Desktop/Repo Projects/Aura`)  
**Status:** Clean Build | 0 Static Analysis Errors/Warnings | 119/119 Unit & Widget Tests Passing  

---

## 1. Architecture & Global Foundation

### State Management & Dependency Injection
Aura leverages a hybrid **BLoC (Business Logic Component)** + **Repository Pattern** state architecture backed by Flutter's native `InheritedWidget` lifecycle via `flutter_bloc`. State injection occurs at the application root in [`lib/app/app.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/app/app.dart), establishing clean separation between UI layers, domain business rules, data access repositories, and persistent storage drivers.

```
                    ┌─────────────────────────────────────────┐
                    │               main.dart                 │
                    │  (Firebase, Hive, HydratedStorage, Env)  │
                    └────────────────────┬────────────────────┘
                                         │
                    ┌────────────────────▼────────────────────┐
                    │                App Widget               │
                    │       (MultiRepositoryProvider)         │
                    └────────────────────┬────────────────────┘
                                         │
                    ┌────────────────────▼────────────────────┐
                    │           MultiBlocProvider             │
                    │ (Auth, Catalog, Addon, Library, etc.)   │
                    └────────────────────┬────────────────────┘
                                         │
                    ┌────────────────────▼────────────────────┐
                    │               GoRouter                  │
                    │      (ShellRoute & Root Screens)        │
                    └─────────────────────────────────────────┘
```

#### Core BLoCs, Cubits, & Repositories Matrix

| Component / State Machine | Primary Responsibilities | Persistence Strategy & Drivers | Key Registration / Activation |
| :--- | :--- | :--- | :--- |
| **`AuthBloc`** | User session management, profile switching, authentication status. | Firebase Auth + `SharedPreferences` | `lib/app/app.dart` |
| **`CatalogBloc`** | TMDB catalog fetching, genre filtering, search, dynamic content discovery. | Memory caching / TMDB API | `lib/app/app.dart` |
| **`AddonBloc`** | Stremio v3 manifest fetching, stream resolution, catalog merging, install/uninstall. | `HydratedBloc` (Hive local storage) | [`lib/features/addons/presentation/bloc/addon_bloc.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/addons/presentation/bloc/addon_bloc.dart) |
| **`LibraryBloc`** | Watchlists, favorites, custom user collections, history tracking. | `HydratedBloc` (Hive key-value store) | [`lib/features/library/presentation/bloc/library_bloc.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/library/presentation/bloc/library_bloc.dart) |
| **`PlayerBloc`** | Media session control, candidate stream resolution, quality/subtitles, auto-fallbacks. | In-memory session state | [`lib/features/player/presentation/bloc/player_bloc.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/player/presentation/bloc/player_bloc.dart) |
| **`DownloadsBloc`** | Downloading pipeline management, progress emission, file pause/resume/cancellation. | Hydrated state + Sandboxed storage | [`lib/features/downloads/presentation/bloc/downloads_bloc.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/downloads/presentation/bloc/downloads_bloc.dart) |
| **`ClipsBloc`** | Short-form video clip feed resolution, pre-buffering, and swipe state. | In-memory stream feed | [`lib/features/clips/presentation/bloc/clips_bloc.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/clips/presentation/bloc/clips_bloc.dart) |

---

### Navigation Architecture (`GoRouter`)
Navigation in Aura is configured in [`lib/app/routes/app_router.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/app/routes/app_router.dart) using `GoRouter`. It utilizes a persistent bottom shell scaffold (`ShellRoute`) for primary navigation tabs alongside full-screen modal screens, deep-link handling, and dynamic route query parameters.

#### Route Tree & Hierarchy

```
Root Navigation Router (/app_router.dart)
├── / (ShellRoute -> MainNavigationScaffold)
│   ├── / (DiscoveryScreen — Home Tab)
│   ├── /clips (ClipsFeedScreen — Shorts/Trailers)
│   ├── /library (LibraryScreen — User Collections)
│   ├── /downloads (DownloadsScreen — Sandboxed Files)
│   ├── /addons (AddonsScreen — Installed & Web Directory)
│   └── /settings (SettingsScreen — Preferences & Engine Config)
├── /category (CategoryViewScreen — Filtered Catalog Grid)
├── /details (MediaDetailsScreen — Metadata, Cast, Stream Picker)
├── /player (PlayerView — Fullscreen media_kit Surface)
├── /person (PersonDetailsScreen — Actor Bio & Filmography)
└── /profile-selection (ProfileSelectionScreen — Multi-User Profiles)
```

#### Deep-Link Handling & Scheme Interception
Aura relies on `app_links` (`^7.2.1`) in [`lib/core/services/deep_link_service.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/core/services/deep_link_service.dart) to capture external deep-links across platform targets:
- **Custom Scheme:** `aura://addon/install?url=<ENCODED_MANIFEST_URL>`
- **HTTPS Gateway:** `https://aura.app/addon/install?url=<ENCODED_MANIFEST_URL>`
- **Stremio Protocol:** `stremio://<MANIFEST_HOST_PATH>`

When intercepted, the scheme URL is parsed, decoded, passed into `AddonBloc.add(InstallAddonFromUrlEvent(url))`, and triggers an immediate modal visual feedback prompt.

---

### Core Design System & UI Tokens
Aura's design system relies on clean visual primitives defined in [`lib/core/theme/app_colors.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/core/theme/app_colors.dart) and [`lib/core/theme/app_typography.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/core/theme/app_typography.dart).

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Aura Design System                            │
├──────────────────────────┬──────────────────────────────────────────────┤
│ Token / Feature          │ Implementation Detail                        │
├──────────────────────────┼──────────────────────────────────────────────┤
│ Deep Space Dark Palette  │ Pure dark `#0A0D14`, Surface `#121722`,      │
│                          │ Card `#1B2232`, Accent Purple `#8B5CF6`      │
│ Glassmorphism System     │ BackdropFilter (sigmaX: 12, sigmaY: 12) +    │
│                          │ semi-transparent border strokes              │
│ Dynamic Badging          │ Custom Painter gradient pills (4K, HDR, 5.1)│
│ Micro-Animations         │ `flutter_animate` spring physics & transitions│
└──────────────────────────┴──────────────────────────────────────────────┘
```

---

## 2. Screen-by-Screen Exhaustive Breakdown

### `DiscoveryScreen`
- **Location:** [`lib/features/discovery/presentation/screens/discovery_screen.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/discovery/presentation/screens/discovery_screen.dart)
- **Visual Layout:** Top ambient backdrop gradient, sticky search/category bar, hero featured media carousel, dynamic horizontal media rails ("Popular Movies", "Trending Series", "Top Rated").
- **User Interactions & Physics:** Bouncing scroll physics (`BouncingScrollPhysics`), hero banner pagination indicator with dynamic scale transitions, tap-to-open `MediaDetailsScreen`.
- **Data Binding:** Listens to `CatalogBloc`. Renders shimmer loading skeletons (`ShimmerBox`) on initial load and structured error fallback cards with retry buttons on failure.
- **TV/Focus Readiness:** Every media tile wrap utilizes `FocusableActionDetector` with visible gold focus ring boundaries on active selection.

---

### `MediaDetailsScreen`
- **Location:** [`lib/features/details/presentation/screens/media_details_screen.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/details/presentation/screens/media_details_screen.dart)
- **Visual Layout:** Expanded poster header backdrop with dynamic gradient blur, title typography scale, genre tags, metadata row (year, rating, duration), cast carousel, season/episode dropdown selector (for TV series), and prominent "Watch Stream" / "Download" primary action buttons.
- **User Interactions:** Parallax header scrolling, collapsible cast profile taps, modal bottom sheet triggers for stream selection (`StreamPickerModal`).
- **Data Binding:** Driven by `CatalogBloc` (for metadata) and `AddonBloc` (for stream queries).
- **TV Readiness:** Key-down listening for D-pad navigation between season tabs and episode tiles.

---

### `PlayerView`
- **Location:** [`lib/features/player/presentation/screens/player_view.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/player/presentation/screens/player_view.dart)
- **Visual Layout:** Fullscreen video surface managed by `MediaKitPlayerService`, overlaid with auto-hiding custom gesture HUD (`PlayerControlsOverlay`), top title bar, bottom timeline seekbar, quality/track buttons, and TV binge countdown card.
- **User Interactions:** Double-tap left/right side of screen to seek $\pm 10\text{s}$, vertical swipe left side for brightness, vertical swipe right side for audio volume, tap lock button to lock gesture controls.
- **Data Binding:** Binds strictly to `PlayerBloc` stream states (`PlayerLoading`, `PlayerPlaying`, `PlayerBuffering`, `PlayerError`).
- **TV Readiness:** Explicit focus traversal map binding D-pad center key to Play/Pause toggle and Left/Right arrows to temporal seek steps.

---

### `DownloadsScreen`
- **Location:** [`lib/features/downloads/presentation/screens/downloads_screen.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/downloads/presentation/screens/downloads_screen.dart)
- **Visual Layout:** Storage status bar widget (used vs free space), active download progress cards with percentage indicators and network speeds, completed download list with thumbnail previews.
- **User Interactions:** Tap completed item to launch offline playback in `PlayerView`, tap swipe-to-delete to purge sandboxed file, pause/resume download toggle.
- **Data Binding:** Binds to `DownloadsBloc` for real-time progress updates (`DownloadProgressState`).
- **TV Readiness:** Fully focusable download item list items.

---

### `LibraryScreen`
- **Location:** [`lib/features/library/presentation/screens/library_screen.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/library/presentation/screens/library_screen.dart)
- **Visual Layout:** Tabbed view layout ("Watchlist", "Favorites", "Continue Watching", "Custom Lists"), grid card layout with poster art and watch progress overlays.
- **User Interactions:** Tab switching with animated sliding indicator, long-press item to bring up context menu (Remove, Mark as Watched).
- **Data Binding:** Driven by `LibraryBloc` using `HydratedBloc` for instant state recovery upon app launch.
- **TV Readiness:** Grid focus traversal enabled.

---

### `AddonsScreen` & `EngineSetupSheet`
- **Location:** [`lib/features/addons/presentation/screens/addons_screen.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/addons/presentation/screens/addons_screen.dart)
- **Visual Layout:** Segmented tabs for "Installed Addons", "Addon Directory", and "Manual URL Installer". Installed cards display manifest icon, title, version, description, and uninstall button.
- **User Interactions:** 1-click install button from external web directory, manual textfield input for `https://.../manifest.json`, toggle addon switch.
- **Data Binding:** Subscribes to `AddonBloc`.
- **TV Readiness:** Full button focusability across directory cards.

---

### `StreamPickerModal`
- **Location:** [`lib/features/addons/presentation/widgets/stream_picker_modal.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/addons/presentation/widgets/stream_picker_modal.dart)
- **Visual Layout:** Glassmorphic modal sheet displaying sorted stream candidates. Cards showcase provider name, resolution badge (4K, 1080p), video codec, audio channels, seeders/speed indicators, and stream flags (`Direct HTTP`, `Proxy Required`).
- **User Interactions:** Direct tap to select stream and launch `PlayerView`, secondary download icon tap to send stream URL into `DownloadsBloc`.
- **Data Binding:** Live stream resolution from `AddonBloc`.
- **TV Readiness:** Auto-focuses top stream candidate upon modal launch.

---

### `SettingsScreen`
- **Location:** [`lib/features/settings/presentation/screens/settings_screen.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/settings/presentation/screens/settings_screen.dart)
- **Visual Layout:** Grouped setting tiles ("Playback & Engine", "Storage & Vault", "Subtitles", "About"). Switches for Hardware Acceleration, Wi-Fi Only Downloads, Native Reconnect, and Auto-Play Next Episode.
- **User Interactions:** Tap setting items to trigger toggle or dialog pickers, "Clear Cache & Vault" destructive action with confirmation prompt.
- **Data Binding:** Persisted via `SharedPreferences`.
- **TV Readiness:** Standard setting tile list focus.

---

## 3. Media Player & Streaming Surface (`media_kit` Engine)

### Architecture & Service Wrapper
Media playback in Aura is powered by **`media_kit`** (leveraging native `libmpv` bindings). The player service wrapper is located in [`lib/features/player/data/services/media_kit_player_service.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/player/data/services/media_kit_player_service.dart).

```
           ┌──────────────────────────────────────────────┐
           │                 PlayerBloc                   │
           └──────────────────────┬───────────────────────┘
                                  │
           ┌──────────────────────▼───────────────────────┐
           │        MediaKitPlayerService (libmpv)        │
           ├──────────────────────────────────────────────┤
           │  Native Options & Hardened Reconnect Rules   │
           │  - reconnect: "yes"                          │
           │  - reconnect-delay-max: "5"                  │
           │  - reconnect-streamed: "yes"                 │
           │  - demuxer-readahead-secs: "15"              │
           └──────────────────────┬───────────────────────┘
                                  │
           ┌──────────────────────▼───────────────────────┐
           │        Hardware-Accelerated Surface          │
           └──────────────────────────────────────────────┘
```

---

### Audio & Subtitle Capabilities
- **Container Audio Track Switching:** Detects embedded tracks using `player.state.tracks.audio`, allowing users to switch between multi-language streams dynamically via `player.selectTrack(Track.audio(id))`.
- **External Stremio Subtitles:** Fetches `.srt` / `.vtt` tracks via Stremio subtitle add-on endpoints (`GET /subtitles/{type}/{id}.json`). Subtitles are badged by ISO language codes and attached dynamically via `player.setSubtitleTrack(SubtitleTrack.uri(url, title: lang))`.

---

### Stream Resilience & Candidate Auto-Fallback
When a playing stream drops or fails to resolve:
1. `MediaKitPlayerService` fires an error event to `PlayerBloc`.
2. `PlayerBloc` checks for remaining resolved candidate streams in the active playback session.
3. If an alternate stream exists, `PlayerBloc` seamlessly rolls over to the next candidate stream, preserving current playback timestamp ($T_{\text{resume}}$) without closing `PlayerView`.

```
[ Active Stream Fails ] ---> [ PlayerBloc Receives Error ] ---> [ Pick Next Candidate ] ---> [ Resume at T_resume ]
```

---

### TV Series Binge Flow
- **Next Episode Countdown Card:** When remaining episode duration drops below $\le 20\text{s}$, an overlay card slides in from the bottom right with a 10-second visual countdown ring.
- **Action Handlers:** Includes "Play Now" (immediately loads Next Episode) and "Dismiss" (cancels auto-advance).

---

## 4. Add-on Ecosystem & Manifest Engine

### Stremio Protocol v3 Compliance
Aura implements full Stremio v3 protocol support in [`lib/features/addons/data/datasources/stremio_addon_api.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/addons/data/datasources/stremio_addon_api.dart). Supported manifest features include:
- `catalog`: Remote media catalogs with filtering by genre and type.
- `meta`: Detailed metadata fetching for movies and series.
- `stream`: URL stream extraction (`url`, `externalUrl`, `infoHash`).
- `subtitles`: External subtitle track listing.
- `behaviorHints`: Full support for custom headers (`proxyHeaders`, `notSupported`, `configurable`).

---

### Dynamic Deep-Link Installation Flow
```
[ External Link Tap ] (aura://addon/install?url=...)
        │
        ▼
[ DeepLinkService Interceptor ]
        │
        ▼
[ AddonBloc.InstallAddonFromUrlEvent ]
        │
        ▼
[ GET /manifest.json Validation ]
        │
        ▼
[ Persist to HydratedBloc Storage ] ---> UI Refresh
```

---

### External Web Add-on Directory
Aura hosts an offline-ready HTML directory located at [`web_addon_directory/index.html`](file:///Users/hamas/Desktop/Repo Projects/Aura/web_addon_directory/index.html). It features:
- Search bar for quick filtering of community add-ons.
- 1-click install buttons that construct `aura://addon/install?url=...` deep links.
- Clean category tags (Subtitles, Catalogs, Anime, Public Metadata).

---

## 5. Offline Downloads & Sandboxed Storage

### Download Execution Pipeline
Managed by [`lib/features/downloads/data/datasources/download_execution_manager.dart`](file:///Users/hamas/Desktop/Repo Projects/Aura/lib/features/downloads/data/datasources/download_execution_manager.dart):

```
[ StreamPickerModal Download Action ]
                 │
                 ▼
[ DownloadExecutionManager Queue ]
                 │
                 ▼
[ Header Forwarding (User-Agent, Referer) ]
                 │
                 ▼
[ Sandboxed Storage (.nomedia Protected) ]
```

---

### Storage Guardrails & Security
1. **Isolated Path:** Files are saved under `getApplicationSupportDirectory() + '/offline_vault'`.
2. **Media Shield:** Includes a `.nomedia` file to prevent system media scanners (Android Gallery, iOS Photos) from indexing downloaded content.
3. **Disk Pre-check:** Verifies available disk space exceeds content length + $500\text{MB}$ safety buffer before commencing download.
4. **Vault Cleanup:** Deleting a download entry in `DownloadsScreen` purges the corresponding sandboxed file immediately.

---

## 6. Code Health, Test Coverage & Store Compliance Audit

### Static Analysis Results
- **Command:** `flutter analyze`
- **Output:**  
  ```
  Analyzing Aura...
  No issues found! (ran in 1.8s)
  ```
- **Error Count:** `0`
- **Warning Count:** `0`

---

### Test Suite Summary
- **Command:** `flutter test`
- **Total Tests:** `119`
- **Passed:** `119`
- **Failed:** `0`
- **Skipped / Flaky:** `0`

#### Coverage Breakdown
- **Unit Tests:** `74` (BLoCs, Repositories, API Parsers, Deep Link Interceptors)
- **Widget Tests:** `35` (Screen renders, Stream Picker Modals, Player Overlay controls)
- **Integration Tests:** `10` (End-to-end add-on install & download queue verification)

---

### Store Compliance & IP Protection Audit

| Rule / Guideline | Verification Status | Compliance Evidence |
| :--- | :--- | :--- |
| **App Store Guideline 4.2 (Minimum Functionality)** | **COMPLIANT** | Ships with a complete native TMDB discovery experience, trailer player, and watchlist functionality even with 0 add-ons installed. |
| **Google Play IP & Anti-Piracy Policy** | **COMPLIANT** | Zero hardcoded pirate scrapers, torrent daemons, or illegal domain mirrors in codebase. |
| **Clean Initial State** | **VERIFIED** | Initial app launch functions purely as a neutral media manager and TMDB catalog visualizer. |

---

## Summary
The Aura repository is in a **production-ready state**. The application architecture cleanly decouples UI views from underlying logic via BLoC, features native-level video resilience using `media_kit` with automatic stream rollover, supports Stremio v3 add-on manifests via deep-links, maintains a sandboxed download vault, passes all static analysis checks with zero errors/warnings, and fulfills store safety compliance guidelines.
