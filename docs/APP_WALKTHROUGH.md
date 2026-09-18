# 🌌 Aura: Comprehensive System & Architectural Walkthrough

Aura is a modern, modular, cross-platform media center client built with Flutter, Dart, and `media_kit` (libmpv). It delivers a unified, dark-mode, glassmorphic entertainment platform combining catalog discovery, multi-source streaming via Stremio v3 protocol add-ons, Debrid cloud un-restricting, hardware-accelerated video playback with ambient glow lighting, offline download vaults, synchronized multi-user watch rooms, and Trakt.tv scrobbling.

---

## 📑 Table of Contents
1. [Core Architecture & Design Philosophy](#1-core-architecture--design-philosophy)
2. [Complete Dependency Matrix (pubspec.yaml)](#2-complete-dependency-matrix)
3. [Data Sources & Origins (Where Everything Comes From)](#3-data-sources--origins)
   - [3.1 Catalog, Movies, TV Shows, Seasons & Episodes (TMDB)](#31-catalog-movies-tv-shows-seasons--episodes-tmdb)
   - [3.2 Cast, Crew & Person Filmographies (TMDB)](#32-cast-crew--person-filmographies-tmdb)
   - [3.3 Trailers & Video Previews (Multi-Tier Resolver)](#33-trailers--video-previews-multi-tier-resolver)
   - [3.4 Community Add-ons & Video Stream Sources (Stremio v3 Protocol)](#34-community-add-ons--video-stream-sources-stremio-v3-protocol)
   - [3.5 Premium Debrid Cloud Resolvers (Real-Debrid & TorBox)](#35-premium-debrid-cloud-resolvers-real-debrid--torbox)
   - [3.6 Subtitles & Multi-Language Captions (OpenSubtitles / Addons)](#36-subtitles--multi-language-captions)
   - [3.7 Watch Tracking & Scrobbling (Trakt.tv API v2)](#37-watch-tracking--scrobbling-trakttv-api-v2)
   - [3.8 Cloud Authentication & User Profiles (Firebase & Local Vault)](#38-cloud-authentication--user-profiles)
4. [Complete Feature & Screen Walkthrough](#4-complete-feature--screen-walkthrough)
   - [4.1 Navigation Shell & Floating Glass Pill](#41-navigation-shell--floating-glass-pill)
   - [4.2 Home & Discovery Screen](#42-home--discovery-screen)
   - [4.3 Ambient Search Screen](#43-ambient-search-screen)
   - [4.4 Media Details Screen (Movies & TV Shows)](#44-media-details-screen-movies--tv-shows)
   - [4.5 Person & Actor Details Screen](#45-person--actor-details-screen)
   - [4.6 Full-Screen Clips Reel Screen (Trailers Feed)](#46-full-screen-clips-reel-screen-trailers-feed)
   - [4.7 Hardware-Accelerated Video Player & Ambient Aura Glow](#47-hardware-accelerated-video-player--ambient-aura-glow)
   - [4.8 Stremio Add-on Hub Screen](#48-stremio-add-on-hub-screen)
   - [4.9 Sandboxed Offline Download Vault Screen](#49-sandboxed-offline-download-vault-screen)
   - [4.10 Watch Together Synchronized Watch Rooms Screen](#410-watch-together-synchronized-watch-rooms-screen)
   - [4.11 Library, Watchlist & Favorites Screen](#411-library-watchlist--favorites-screen)
   - [4.12 Settings, Profile & Cloud Debrid Services Screen](#412-settings-profile--cloud-debrid-services-screen)
   - [4.13 Multi-Profile Selection Screen (Kid/Adult PIN Vault)](#413-multi-profile-selection-screen-kidadult-pin-vault)
5. [Application Routing Directory (GoRouter)](#5-application-routing-directory-gorouter)
6. [Data Flow Diagrams](#6-data-flow-diagrams)

---

## 1. Core Architecture & Design Philosophy

Aura follows **Clean Architecture** with strict layer isolation and uni-directional data flow using **BLoC (Business Logic Component)** state management:

```
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION                           │
│   Screens, Widgets, Glassmorphic HUDs, BLoC / Cubits        │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Events & States)
┌──────────────────────────────▼──────────────────────────────┐
│                         DOMAIN                              │
│   Entities, Use Cases, Value Objects, Repository Interfaces │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Domain Models)
┌──────────────────────────────▼──────────────────────────────┐
│                          DATA                               │
│   Repository Implementations, Remote DataSources (Dio),     │
│   Local DataSources (SecureStorage, SharedPreferences)      │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Hardware & System APIs)
┌──────────────────────────────▼──────────────────────────────┐
│                          CORE                               │
│   Theme Tokens, Network Clients, Errors, libmpv Player Engine│
└─────────────────────────────────────────────────────────────┘
```

### Design Principles:
- **Zero Raw Platform Bleed**: App logic is 100% pure Dart, isolating platform channels behind resilient service abstractions.
- **Glassmorphism & Ambient Glow**: Ultra-deep dark backgrounds (`#0B0C10`, `#14161D`), frosted glass overlays with `BackdropFilter` Gaussian blurs (15px to 25px), and dynamic edge-color backlight projection (`AuraGlowBackdrop`).
- **Resilient Fallback Chains**: Every network subsystem (trailers, streams, subtitles, poster art) includes multi-tiered automated fallbacks to ensure uninterrupted user experience.

---

## 2. Complete Dependency Matrix

Below is the complete breakdown of every package declared in `pubspec.yaml` and its exact role within Aura:

| Dependency | Version | Category | Role & Usage in Aura |
|---|---|---|---|
| `flutter_bloc` | `^9.1.1` | State Management | Manages all reactive UI states across 12 distinct feature BLoCs (`CatalogBloc`, `PlayerBloc`, `AddonBloc`, `LibraryBloc`, `AuthBloc`, `ClipsBloc`, `DownloadsBloc`, `WatchTogetherCubit`, etc.). |
| `hydrated_bloc` | `^11.0.0` | State Persistence | Automatically persists critical BLoC state snapshots (e.g. user theme preferences, offline scrobbles, UI state) across app restarts without manual JSON boilerplate. |
| `equatable` | `^2.0.7` | Utility | Implements value-based equality for all BLoC Events, States, and Domain Entities to prevent unnecessary widget rebuilds. |
| `go_router` | `^18.0.1` | Navigation | Declarative deep-linking router managing page routing, nested navigation shells, parameter passing, and custom fade/slide page transitions. |
| `media_kit` | `^1.1.11` | Playback Core | High-performance pure Dart bindings to `libmpv` supporting hardware video decoding, GPU render pipelines, and zero-latency audio/video synchronization. |
| `media_kit_video` | `^2.0.1` | Playback UI | Flutter texture-based video widget wrapper for `media_kit` that renders GPU-accelerated video frames inside Flutter's widget tree. |
| `media_kit_libs_video` | `^1.0.5` | Native Binaries | Bundles precompiled `libmpv` and FFmpeg shared native libraries across macOS, iOS, Android, Linux, and Windows. |
| `dio` | `^5.8.0+1` | Networking | Advanced HTTP client with interceptors for TMDB API requests, Stremio addon stream scraping, and chunked byte-range offline video downloads. |
| `http` | `^1.2.1` | Networking | Lightweight HTTP client utilized by `TraktAuthService` and `TraktScrobbleService` for standard REST calls. |
| `flutter_dotenv` | `^6.0.1` | Configuration | Loads runtime environment variables from `.env` (TMDB access tokens, Trakt client IDs, Supabase keys) with graceful build-time defaults in `Env`. |
| `freezed_annotation` | `^3.1.0` | Data Modeling | Annotations for immutable domain entities with copy methods, union types, and automatic pattern matching. |
| `json_annotation` | `^4.9.0` | Serialization | Annotations for code generation of type-safe `fromJson` / `toJson` deserializers. |
| `firebase_core` | `^4.15.0` | Cloud Backend | Initializes Firebase cloud infrastructure on mobile/desktop platforms. |
| `firebase_auth` | `^6.7.0` | Authentication | Manages user sign-up, sign-in, token refreshes, password resets, and session lifecycle. |
| `google_sign_in` | `^6.2.2` | OAuth | Provides one-tap Google OAuth credential exchange with Firebase Authentication. |
| `supabase_flutter` | `^2.8.4` | Cloud Backend | Real-time database and WebSocket backend for cross-device watchlist synchronization and Watch Together signaling. |
| `flutter_secure_storage` | `^11.1.1` | Security Vault | Encrypted hardware keychain / keystore storage for Real-Debrid API keys, TorBox tokens, Trakt OAuth secrets, and user PINs. |
| `shared_preferences` | `^2.3.5` | Local Storage | Key-value store for user preferences: selected player decoder, subtitle size, glow intensity, default audio language, and active profile ID. |
| `path_provider` | `^2.1.5` | File System | Resolves sandboxed application documents directories for private offline download storage and temporary cache files. |
| `uuid` | `^4.5.1` | Utility | Generates RFC4122 v4 unique identifiers for download tasks, offline scrobble entries, and guest profiles. |
| `intl` | `^0.20.2` | Localization | Date formatting, duration formatting (e.g. `2h 15m`), and localized numeric currency/rating strings. |
| `cached_network_image` | `^4.0.0` | Image Caching | High-efficiency disk and memory caching of TMDB poster, backdrop, and cast headshot images with smooth shimmer placeholders. |
| `material_symbols_icons` | `^4.2960.0` | Icons | Provides modern Google Material Symbols rounded icon glyphs used throughout the UI. |
| `google_fonts` | `^8.2.1` | Typography | Loads Google Fonts (Outfit, Inter, Space Grotesk) dynamically with offline fallback caches. |
| `connectivity_plus` | `^7.3.1` | Network Monitoring | Detects online/offline status, Wi-Fi vs Cellular switching, and triggers automatic offline download mode transitions. |
| `battery_plus` | `^7.1.1` | Device Stats | Reads real-time device battery levels to display battery HUD indicators inside the video player controls overlay. |
| `crypto` | `^3.0.6` | Cryptography | Computes SHA-256 and MD5 checksums for verified file integrity of downloaded media files and password/PIN hashing. |
| `rxdart` | `^0.28.0` | Reactive Streams | Advanced reactive stream operators (debounce, throttle, combineLatest) used for search queries and player timeline slider nudging. |
| `youtube_explode_dart` | `^3.1.0` | Stream Extraction | Pure Dart YouTube stream parser that extracts raw direct MP4/WebM video stream URLs from trailer keys without requiring YouTube webviews or native players. |

---

## 3. Data Sources & Origins (Where Everything Comes From)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            AURA DATA ORIGINS                                │
├──────────────────────────────┬──────────────────────────────────────────────┤
│ METADATA & DISCOVERY         │ TMDB v3 REST API                             │
│ POSTERS & BACKDROPS          │ TMDB Cloud CDN (image.tmdb.org)             │
│ TRAILERS & PREVIEWS          │ YouTubeExplode -> Invidious Decentralized    │
│ STREAM RESOLUTION            │ Stremio v3 Add-ons (Cinemeta, Torrentio)     │
│ DEBRID UN-RESTRICTING        │ Real-Debrid & TorBox REST APIs               │
│ SUBTITLES & CAPTIONS         │ OpenSubtitles v3 REST / Stremio Subtitles    │
│ WATCH PROGRESS SCROBBLING    │ Trakt.tv API v2 OAuth Device Code            │
│ AUTHENTICATION & SYNC        │ Firebase Auth & Supabase Realtime            │
└──────────────────────────────┴──────────────────────────────────────────────┘
```

### 3.1 Catalog, Movies, TV Shows, Seasons & Episodes (TMDB)
- **Source**: [The Movie Database (TMDB) API v3](https://api.themoviedb.org/3).
- **Service Implementation**: [`TmdbApiClient`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/catalog/data/datasources/tmdb_api_client.dart) via [`ApiClient`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/core/network/api_client.dart).
- **Authentication**: HTTP `Authorization: Bearer <Env.tmdbReadAccessToken>` and fallback `?api_key=<Env.tmdbApiKey>`.
- **Endpoints Queried**:
  - `GET /trending/{media_type}/{time_window}`: Populates home hero banner and trending carousels.
  - `GET /movie/popular`, `GET /tv/popular`, `GET /movie/top_rated`, `GET /tv/top_rated`: Powers discovery shelves.
  - `GET /discover/movie` & `GET /discover/tv`: Dynamic filtering by genre IDs, release years, vote averages, and sorting orders.
  - `GET /search/multi`: Real-time debounced multi-search across movies, TV series, and actors.
  - `GET /movie/{id}` & `GET /tv/{id}`: Detailed metadata including budget, runtime, tagline, status, genres, and production companies.
  - `GET /tv/{id}/season/{season_number}`: Episode lists, episode names, still images, air dates, and overview summaries.
- **Image CDNs**:
  - Posters: `https://image.tmdb.org/t/p/w500/{poster_path}`
  - Backdrops: `https://image.tmdb.org/t/p/w1280/{backdrop_path}` or `https://image.tmdb.org/t/p/original/{backdrop_path}`
  - Cast Stills: `https://image.tmdb.org/t/p/w185/{profile_path}`

---

### 3.2 Cast, Crew & Person Filmographies (TMDB)
- **Source**: TMDB Credits & People API.
- **Endpoints Queried**:
  - `GET /movie/{id}/credits` & `GET /tv/{id}/credits`: Returns ordered lists of top billing cast actors, characters, and key crew (directors, writers, creators).
  - `GET /person/{id}`: Retrieves actor biography, birthday, birthplace, and profile image.
  - `GET /person/{id}/combined_credits`: Full aggregated filmography (movies + TV series) sorted by release date and popularity.

---

### 3.3 Trailers & Video Previews (Multi-Tier Pure Dart Resolver)
- **Source**: Multi-Tier Pipeline orchestrated by [`TrailerStreamResolver`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/player/data/services/trailer_stream_resolver.dart).
- **How It Works**:
  1. **TMDB Video Key Lookup**: Aura calls `GET /movie/{id}/videos` or `GET /tv/{id}/videos` to retrieve official YouTube trailer keys (`type: "Trailer"`, `site: "YouTube"`).
  2. **Tier 1 (Direct YouTube Stream Extraction)**: Uses `youtube_explode_dart` to parse the manifest, extract muxed video+audio MP4 streams (1080p, 720p, 360p), and feed the direct video stream into `media_kit`.
  3. **Tier 2 (Invidious Public Mirror Failover)**: If YouTube throttles or rate-limits, the resolver automatically races across public Invidious instances (`yewtu.be`, `inv.nadeko.net`, `invidious.nerdvpn.de`, `inv.tux.pizza`) and fetches direct video stream URLs via `/api/v1/videos/{id}`.
  4. **Tier 3 (Ambient Backdrop Fallback)**: If no video stream can be extracted, the player seamlessly falls back to `AmbientBackdropFallback` which displays a Ken Burns zooming animated high-res backdrop with audio preview and a preview badge.

---

### 3.4 Community Add-ons & Video Stream Sources (Stremio v3 Protocol)
- **Source**: Stremio v3 HTTP REST Add-on Ecosystem.
- **Service Implementation**: [`StremioAddonApi`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/addons/data/datasources/stremio_addon_api.dart) & [`AddonRepositoryImpl`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/addons/data/repositories/addon_repository_impl.dart).
- **Default Addons**:
  - **Cinemeta**: `https://v3-cinemeta.strem.io/manifest.json` (Official IMDb catalog metadata).
  - **Torrentio**: `https://torrentio.strem.fun/manifest.json` (Torrent & Debrid stream scraper).
- **Manifest Specification**:
  - `GET {addon_url}/manifest.json`: Returns addon `id`, `name`, `version`, `description`, `resources` (`stream`, `catalog`, `subtitles`), `types` (`movie`, `series`), and `idPrefixes` (`tt`, `kitsu`, `tmdb`).
- **Stream Query Specification**:
  - Movies: `GET {addon_base_url}/stream/movie/{imdb_id}.json` (e.g. `tt0137523`)
  - TV Shows: `GET {addon_base_url}/stream/series/{imdb_id}:{season}:{episode}.json` (e.g. `tt0903747:1:1`)
- **Performance**: Each installed add-on is queried in parallel with a strict **3.5-second timeout** so slow add-ons never delay fast add-ons. Streams are aggregated and ranked by quality (4K, 1080p, 720p), seeders, and stream type.

---

### 3.5 Premium Debrid Cloud Resolvers (Real-Debrid & TorBox)
- **Source**: Real-Debrid API (`https://api.real-debrid.com/rest/1.0`) & TorBox API (`https://api.torbox.app/v1`).
- **Service Implementation**: [`HttpDebridEngine`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/engine/http_debrid_engine.dart) & [`SecureStorageService`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/core/storage/secure_storage_service.dart).
- **How It Works**:
  - Users enter their Real-Debrid or TorBox API key in **Settings -> Debrid Cloud Services**.
  - The API key is stored securely in the hardware keychain (`FlutterSecureStorage`).
  - When a Debrid stream URL is selected (e.g. from Torrentio or direct Debrid stream), `HttpDebridEngine` automatically injects the `Authorization: Bearer <key>` header and resolves redirects into a full-speed, buffer-free direct HTTPS stream delivered directly to `media_kit`.

---

### 3.6 Subtitles & Multi-Language Captions
- **Source**: OpenSubtitles v3 / Stremio Subtitle Add-ons.
- **Service Implementation**: [`SubtitleEngine`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/player/data/services/subtitle_engine.dart).
- **Capabilities**:
  - Auto-downloads `.srt` / `.vtt` subtitle files by IMDb ID, season, and episode.
  - Ingests embedded subtitle tracks (ASS, SSA, SubRip) directly from the video container via `libmpv`.
  - Supports **Dual Subtitles** (simultaneous primary and secondary subtitle tracks for language learners).
  - **Live Subtitle Sync Offset HUD**: Real-time slider and ±0.5s quick nudge buttons to eliminate audio-subtitle delay on the fly.

---

### 3.7 Watch Tracking & Scrobbling (Trakt.tv API v2)
- **Source**: [Trakt.tv REST API v2](https://api.trakt.tv).
- **Service Implementation**: [`TraktAuthService`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/trakt/data/services/trakt_auth_service.dart) & [`TraktScrobbleService`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/trakt/data/services/trakt_scrobble_service.dart).
- **OAuth Device Code Flow**:
  1. Aura requests a device code: `POST https://api.trakt.tv/oauth/device/code`.
  2. UI displays an interactive pairing card with the user code (e.g. `8E2B-9A4F`) and clickable verification URL (`https://trakt.tv/activate`).
  3. Aura polls the Trakt token endpoint until authorized, then securely saves the OAuth `access_token` and `refresh_token`.
- **Live Scrobbling**:
  - `POST /scrobble/start`: Sent when playback begins.
  - `POST /scrobble/pause`: Sent when user pauses.
  - `POST /scrobble/stop`: Sent on exit. If watched progress is **≥ 80%**, Trakt marks the movie/episode as officially watched.
  - **Offline Scrobble Vault**: If offline, scrobble events are queued in [`OfflineScrobbleVault`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/downloads/data/datasources/offline_scrobble_vault.dart) and flushed automatically when connectivity returns.

---

### 3.8 Cloud Authentication & User Profiles
- **Source**: Firebase Authentication + Local Sandboxed Profiles.
- **Service Implementation**: [`AuthRepositoryImpl`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/auth/data/repositories/auth_repository_impl.dart) & [`ProfileStorageService`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/profiles/data/services/profile_storage_service.dart).
- **Capabilities**:
  - Supports Email/Password sign-up/login, Google Sign-In, and Guest/Offline mode.
  - **Multi-Profile System**: Up to 6 profiles per account (Adult, Teen, Kid). Kids profiles filter out adult content (`include_adult: false`).
  - Profiles can be locked with a 4-digit security PIN.

---

## 4. Complete Feature & Screen Walkthrough

```
                                  ┌───────────────┐
                                  │   App Launch  │
                                  └───────┬───────┘
                                          │
                               ┌──────────▼──────────┐
                               │ Profile Picker / PIN│
                               └──────────┬──────────┘
                                          │
    ┌─────────────────────────────────────▼─────────────────────────────────────┐
    │                      AuraNavigationShell (Bottom Pill)                    │
    ├──────────────────┬──────────────────┬──────────────────┬──────────────────┤
    │      HOME        │      SEARCH      │      CLIPS       │     LIBRARY      │
    │  - Hero Banner   │  - Live Debounce │  - Vertical Feed │  - Watchlist     │
    │  - Trending Rows │  - Genre Filters │  - Auto-play MP4 │  - History       │
    │  - Continue Play │  - Voice / Text  │  - Quick Like    │  - Offline Vault │
    └────────┬─────────┴────────┬─────────┴────────┬─────────┴────────┬─────────┘
             │                  │                  │                  │
             └──────────────────┼──────────────────┘                  │
                                │                                     │
                    ┌───────────▼───────────┐                         │
                    │   MediaDetailsScreen  │                         │
                    │ - Synopsis & Cast     │                         │
                    │ - Season/Episode Tabs │                         │
                    │ - Stream Aggregator   │                         │
                    │ - Download Trigger    │                         │
                    └───────────┬───────────┘                         │
                                │                                     │
                    ┌───────────▼───────────┐             ┌───────────▼───────────┐
                    │    PlayerView (MPV)   │             │     DownloadsScreen   │
                    │ - Hardware Decoding   │             │ - Chunk Downloader    │
                    │ - Aura Glow Projector │             │ - Offline Playback    │
                    │ - Subtitle Sync HUD   │             │ - Storage Manager     │
                    │ - Watch Together Room │             └───────────────────────┘
                    └───────────────────────┘
```

---

### 4.1 Navigation Shell & Floating Glass Pill
- **File**: [`AuraNavigationShell`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/core/navigation/aura_navigation_shell.dart) & [`AuraFloatingBottomPill`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/core/presentation/widgets/aura_floating_bottom_pill.dart).
- **Description**: A floating, frosted-glass navigation bar positioned above the bottom content. It includes micro-animations, active glow indicators, and hides smoothly during full-screen video playback.

---

### 4.2 Home & Discovery Screen
- **File**: [`HomeScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/catalog/presentation/screens/home_screen.dart).
- **Features**:
  - **Dynamic Hero Banner**: Displays the #1 trending title with high-res backdrop, synopsis, maturity badges, and a "Play Trailer" action.
  - **Continue Watching Shelf**: Reads saved watch positions from local storage and Trakt to allow one-tap resume.
  - **Categorized Shelves**: Trending Movies, Popular TV Series, Top Rated, and Sci-Fi/Action spotlight carousels with horizontal scrolling.
  - **Pull to Refresh**: Refreshes catalogs with animated indicators.

---

### 4.3 Ambient Search Screen
- **File**: [`AmbientSearchScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/search/presentation/screens/ambient_search_screen.dart).
- **Features**:
  - Real-time debounced search queries across TMDB.
  - Genre pill filter chips (Action, Comedy, Sci-Fi, Horror, Animation, Documentary).
  - Search history tags with quick clear and instant re-query.
  - Grid view layout with cached image posters and rating badges.

---

### 4.4 Media Details Screen (Movies & TV Shows)
- **File**: [`MediaDetailsScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/catalog/presentation/screens/media_details_screen.dart).
- **Features**:
  - High-res parallax backdrop with gradient fade.
  - Action row: Play, Add to Watchlist, Mark as Favorite, Download Offline.
  - **TV Show Season/Episode Selector**: Interactive tabs for Season 1..N, horizontal episode cards with episode still previews, titles, and air dates.
  - **Cast & Crew Reel**: Horizontal avatar cards for actors; tapping an actor opens their complete person filmography screen.
  - **Streaming Source Selector HUD**: Streams aggregated from all installed Stremio add-ons, displaying resolution, file size, codec, seeder count, and provider tag.

---

### 4.5 Person & Actor Details Screen
- **File**: [`PersonDetailsScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/catalog/presentation/screens/person_details_screen.dart).
- **Features**:
  - Actor portrait with biography, birthday, and birthplace.
  - Known For / Filmography grid: Chronological list of all movies and series starring the person.

---

### 4.6 Full-Screen Clips Reel Screen (Trailers Feed)
- **File**: [`ClipsScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/clips/presentation/screens/clips_screen.dart).
- **Features**:
  - Vertical TikTok/Reels-style scrolling feed of trending movie trailers.
  - Automatic video extraction via `TrailerStreamResolver` and auto-playback.
  - Right-side action column: Like button, Mute/Unmute toggle, Share, and "Open Details".
  - Floating video scrubber slider for seeking within the clip.

---

### 4.7 Hardware-Accelerated Video Player & Ambient Aura Glow
- **File**: [`PlayerView`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/player/presentation/widgets/player_view.dart).
- **Features**:
  - **Hardware Decoding Core**: Powered by `media_kit` (libmpv), supporting 4K HDR, AV1, HEVC/H.265, and VP9.
  - **Ambient Aura Glow**: `AuraGlowBackdrop` projects dynamic, blurred backlight colors matching the video frame onto the screen borders.
  - **HUD Controls**: Double-tap left/right to seek 10s with ripple effects, gesture-based brightness (left edge swipe) and volume (right edge swipe) controls.
  - **Track Selectors**: Multi-audio track switching and dual subtitle track rendering.
  - **Subtitle Sync HUD**: Live delay slider (-5.0s to +5.0s) and nudge buttons.
  - **Picture-in-Picture (PiP)**: Native PiP window support via `PipService`.
  - **Sleep Timer**: Configurable automatic playback shutdown (15m, 30m, 45m, 60m, end of episode).

---

### 4.8 Stremio Add-on Hub Screen
- **File**: [`AddonsScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/addons/presentation/screens/addons_screen.dart).
- **Features**:
  - Browse installed and community add-ons.
  - **Custom Manifest URL Installer**: Supports pasting `stremio://` or `https://` manifest URLs with automatic JSON validation.
  - Enable/Disable toggles and one-tap uninstallation.

---

### 4.9 Sandboxed Offline Download Vault Screen
- **File**: [`DownloadsScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/downloads/presentation/screens/downloads_screen.dart).
- **Features**:
  - Multi-threaded chunked file downloader (`DownloadExecutionManager`).
  - Storage visualizer bar showing downloaded media space vs total available device storage.
  - Resume, pause, and cancel controls.
  - Direct offline playback from local sandboxed file storage.

---

### 4.10 Watch Together Synchronized Watch Rooms Screen
- **File**: [`WatchTogetherScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/watch_together/presentation/screens/watch_together_screen.dart).
- **Features**:
  - Host a room or join via 6-character room code.
  - Real-time playback synchronization across participants (auto-seeks if drift exceeds 1.5s).
  - Floating video overlay HUD with participant avatars, live chat messages, and animated emoji reactions.

---

### 4.11 Library, Watchlist & Favorites Screen
- **File**: [`LibraryScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/library/presentation/screens/library_screen.dart).
- **Features**:
  - Filter by Watchlist, Favorites, and Watched History.
  - Search within personal library.
  - Cloud-synced across devices via Supabase / Firebase.

---

### 4.12 Settings, Profile & Cloud Debrid Services Screen
- **File**: [`SettingsScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/settings/presentation/screens/settings_screen.dart).
- **Features**:
  - **Profile Management**: Switch profiles, edit avatar, view account email.
  - **Trakt.tv Scrobbler Card**: Device code pairing HUD with code and activation link.
  - **Debrid Cloud Services**: Real-Debrid and TorBox API key inputs with obscure toggle, save, clear, and active status badges.
  - **Playback Settings**: Hardware decoder selection (auto, mediacodec, videotoolbox, vaapi), default audio and subtitle languages.
  - **Appearance Settings**: Theme selection, Aura Glow intensity, UI accent color.
  - **Cache & Data**: Clear image cache, flush temporary trailer buffers.

---

### 4.13 Multi-Profile Selection Screen
- **File**: [`ProfileSelectionScreen`](file:///Users/hamas/Desktop/Repo%20Projects/Aura/lib/features/profiles/presentation/screens/profile_selection_screen.dart).
- **Features**:
  - Netflix-style avatar selection screen with animated focus states.
  - Create new adult or kid profiles.
  - 4-digit PIN verification modal for protected adult profiles.

---

## 5. Application Routing Directory (GoRouter)

| Route Path | Screen Widget | Purpose |
|---|---|---|
| `/` | `ProfileSelectionScreen` / `AuraNavigationShell` | Entrypoint: Profile selector or main navigation shell |
| `/home` | `HomeScreen` | Discovery home with hero banner and trending carousels |
| `/search` | `SearchScreen` -> `AmbientSearchScreen` | Multi-category live search and genre filters |
| `/clips` | `ClipsScreen` | Vertical TikTok-style trailer feed |
| `/library` | `LibraryScreen` | Watchlist, favorites, and watch history |
| `/downloads` | `DownloadsScreen` | Offline media vault and storage manager |
| `/addons` | `AddonsScreen` | Stremio add-on manager and manifest installer |
| `/watch-together`| `WatchTogetherScreen` | Synchronized multi-user watch room lobby |
| `/details` | `MediaDetailsScreen` | Movie/TV show synopsis, cast, seasons, and streams |
| `/person/:id` | `PersonDetailsScreen` | Actor biography and filmography grid |
| `/player` | `PlayerView` | Full-screen hardware-accelerated video player |
| `/settings` | `SettingsScreen` | App preferences, Trakt pairing, and Debrid keys |
| `/auth` | `AuthScreen` | Sign-in / Sign-up / Guest authentication |

---

## 6. Data Flow Diagrams

### Stream Resolution & Debrid Pipeline:
```
User selects Movie/Episode
           │
           ▼
MediaDetailsScreen queries AddonRepository
           │
           ▼
StremioAddonApi dispatches concurrent queries (3.5s timeout)
   ├── Cinemeta (Metadata)
   ├── Torrentio (Streams / Hashes)
   └── Custom Add-ons
           │
           ▼
Aggregated Stream List presented to User
           │
           ▼
User selects Stream (e.g. 1080p Real-Debrid / Direct URL)
           │
           ▼
HttpDebridEngine
   ├── Reads API Key from SecureStorageService
   ├── Injects `Authorization: Bearer <key>`
   └── Resolves Redirects
           │
           ▼
media_kit Player Engine initializes libmpv hardware pipeline
           │
           ▼
AuraGlowBackdrop renders ambient edge lighting
```

### Trakt.tv Scrobble Pipeline:
```
Player starts playback
           │
           ▼
TraktScrobbleService sends `POST /scrobble/start`
           │
           ▼
Playback Progress updates in real-time
           │
     ┌─────┴────────────────┐
     │                      │
User Pauses           Playback completes (≥ 80%)
     │                      │
     ▼                      ▼
`POST /scrobble/pause`  `POST /scrobble/stop` (Marked Watched on Trakt)
     │
[Offline?] ──> Queued in OfflineScrobbleVault ──> Flushed on reconnect
```

---

## 7. Summary & Verification

- **Code Quality**: Clean architecture, pure Dart platform isolation, strict lint adherence.
- **Analysis Status**: `flutter analyze` completed with **0 errors / 0 warnings**.
- **Test Suite**: **All 96 unit, widget, and integration tests passed**.
