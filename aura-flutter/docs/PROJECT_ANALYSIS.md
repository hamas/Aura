# Aura — Complete Architectural & Functional Analysis

> **Project Name:** Aura  
> **Description:** Modular, Cross-Platform Cinematic Media Center Client  
> **Framework:** Flutter (Dart 3.5+ / Flutter 3.24+)  
> **Target Platforms:** Android, iOS, macOS, Android TV  
> **Core Architecture:** Clean Architecture (Domain / Data / Presentation) with BLoC State Management & Hydrated Storage  

---

## 1. Executive Summary & Core Architecture

**Aura** is an open-source, modular, client-side media center engineered with Flutter. It combines a **premium editorial streaming interface** (reminiscent of Apple TV+ and Netflix) with a **decentralized protocol architecture** (Stremio v3 specification compliance, Debrid HTTPS unrestrictors, and native `media_kit` / `libmpv` video playback).

### High-Level Architecture Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             PRESENTATION LAYER                              │
│  • GoRouter Shell Navigation (MainNavigationScaffold, AuraFloatingBottomPill)│
│  • BLoCs: CatalogBloc, PlayerBloc, AddonBloc, LibraryBloc, DownloadsBloc,  │
│           ClipsBloc, AuthBloc, SearchBloc, ProfileBloc                     │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                                DOMAIN LAYER                                 │
│  • Entities: MediaItem, AddonManifest, AddonStream, DownloadTask,           │
│              UserProfile, WatchRoomSession, MediaInterval, SubtitleCue      │
│  • Services: SmartDownloadManager, StreamRankerService, MediaContentFilter, │
│              ChapterIngestionService, TraktScrobbleService                  │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                                 DATA LAYER                                  │
│  • Remote APIs: TMDB API (v3/v4), Stremio HTTP/JSON Add-on Endpoints,        │
│                 Trakt.tv OAuth2 / Scrobble API, YouTube Explode Stream URL  │
│  • Storage: SharedPreferences, HydratedBloc Cache, FlutterSecureStorage,   │
│             App Sandboxed Vault (Offline Media Storage)                     │
│  • Engines: HttpDebridEngine, TorrentEngine (Android Proxy / Stub)          │
│  • Media Engine: MediaKit Video Player (Native libmpv bindings)             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Design System & Visual Aesthetics

Aura adheres to a custom dark-mode design system with glassmorphism and subtle micro-interactions:

* **Theme Tokens (`AppTokens`, `AppColors`):**
  * **Backgrounds:** `#0E0F12` (Surface Background), `#14161B` (Surface Elevated), `#1B1E26` (Surface Card).
  * **Brand Accents:** `#FF2D55` (Accent Pink / Primary Highlight), `#E50914` (Cinema Red), `#F5C518` (IMDb Gold).
  * **Typography (`AppTypography`):** Google Fonts Outfit & Inter hierarchy, using display hero titles, crisp subtitles, and high-legibility caption badges.
* **Primitives (`lib/core/presentation/primitives/`):**
  * `AuraScaffold` & `AuraPageScaffold`: Base container with safe-area padding and dark surface tokens.
  * `AuraAdaptiveAppBar`: Pinned sticky navigation bar that dynamically transitions opacity based on scroll distance.
  * `AuraFloatingBottomPill`: Floating navigation bar with glassmorphic backdrop filter blur and glow indicator.
  * `AuraCard` & `AuraBadge`: Reusable high-contrast card shapes with subtle borders (`0x1AFFFFFF` / `0x22FFFFFF`).
  * `_PrivacyCurtainWrapper`: Automatically obscures the UI with a privacy shield when the app is backgrounded or minimized.

---

## 3. Deep Screen-by-Screen Breakdown & Functionality

### 3.1 Main Navigation Shell (`MainNavigationScaffold` & `AppRouter`)
* **Route:** Shell wrapping `/`, `/clips`, `/library`, `/downloads`, `/addons`, `/settings`.
* **Behavior:** Renders `AuraFloatingBottomPill` anchored at the bottom with 5 core tabs: **Discovery (Home)**, **Clips (Reels)**, **Library (Watchlist/History)**, **Add-ons (Hub)**, and **Settings**.
* **Navigation Isolation:** Overlays such as `/player`, `/category`, `/search`, `/person/:id`, and `/profiles` run on the root navigator to hide navigation bars and maximize screen real estate.

---

### 3.2 Discovery / Home Screen (`DiscoveryScreen`)
* **Route:** `/`
* **Purpose:** The primary content discovery feed.
* **Components & Functionality:**
  1. **Tier-1 Prestige Billboard Hero (`BillboardHeroBanner`):**
     * Automatically filters and presents top-tier media with vote count $\ge 500$, vote average $\ge 6.8$, valid backdrop, and clearart transparent logo.
     * Includes "Play", "Info", and quick action buttons. Supports drag-to-scroll hero slider pagination.
  2. **Top Filter Pills:**
     * Toggle between `All`, `Movies`, `Shows`, and `Categories ▾` dropdown modal.
  3. **Content Shelves (`HorizontalContentShelf`):**
     * **My List:** Quick access to saved watchlist items.
     * **Continue Watching:** 16:9 thumbnail shelf with progress bars for active in-progress media.
     * **Latest:** Dynamically fetched newest releases.
     * **Top Movies & Top Shows:** TMDB trending rankings.
     * **Top International & Asian Dramas:** Curated international hits.
  4. **Explore Grid:**
     * Infinite scrolling 3-column poster grid with pagination triggering at scroll threshold ($\le 400\text{px}$ from bottom).
  5. **Pull to Refresh:** Refreshes both TMDB catalog and local library watch progress.

---

### 3.3 Media Details Screen (`MediaDetailsScreen`)
* **Route:** `/detail/:type/:id`
* **Purpose:** Detailed metadata, stream resolution, watchlist toggling, episode picker, and offline download management.
* **Components & Functionality:**
  1. **Backdrop Sliver & Sticky Header (`DetailsBackdropSliver`):**
     * High-res blurred backdrop with linear gradient fade.
     * Poster thumbnail, release year, IMDb/Rotten Tomatoes ratings, genre tags, and quick actions.
  2. **Action Buttons (`DetailsActionButtons`):**
     * **Play Button:** Triggers Stremio stream resolution and opens `StreamPickerModal`.
     * **Download Button:** Initiates stream parsing and schedules background caching.
     * **Play Offline Button:** Directly launches offline player if media is already downloaded.
     * **Watchlist & Share:** Instant state updates.
  3. **Synopsis Section:** Expandable text synopsis with "Read More / Show Less".
  4. **Cast & Crew (`DetailsCastSection`):** Horizontal avatar list of actors; tapping navigates to `PersonDetailsScreen`.
  5. **Episodic Season Selector (`DetailsSeriesEpisodicSection`):**
     * Dropdown season picker.
     * Episode list with thumbnail, title, air date, overview, and individual play/download buttons.
  6. **Related Content Engine ("More Like This"):**
     * Smart recommendation algorithm matching genre IDs, genre names, release year, and vote ratings.

---

### 3.4 Hardware-Accelerated Video Player (`PlayerView` & `PlayerBloc`)
* **Route:** `/player`
* **Engine:** `media_kit` (native `libmpv` bindings) with hardware decoding (`hwdec: auto-safe`) and 32MB 4K buffer.
* **Key Capabilities:**
  1. **Playback Controls Overlay (`PlayerControlsOverlay`):**
     * Custom play/pause, scrub bar, remaining time, skip $\pm 10$s, playback speed selector ($0.5\times$ to $2.0\times$).
     * Aspect ratio switcher (`cover`, `contain`, `fill`, `fitWidth`, `fitHeight`).
  2. **Audio Enhancer (`AudioEnhancerService`):**
     * Night mode (dynamic range compression for clear dialogue at low volume).
     * Voice boost (speech frequency isolation) and bass boost equalizers.
  3. **Dual Subtitles & Subtitle Sync HUD:**
     * Primary and secondary simultaneous subtitles.
     * Subtitle track selector, offset adjuster ($\pm 50\text{ms}$ precision), and OpenSubtitles integration.
  4. **Skip Intro / Outro Pill (`SkipIntervalPill`):** Automatically ingests chapter markers and skip intervals.
  5. **Auto-Next Episode & Binge Prompt (`NextEpisodeCard`):** Displays countdown prompt during end credits for series.
  6. **Ambient Backlight Glow (`AuraGlowBackdrop`):** Real-time dynamic edge glow reflecting screen colors.
  7. **Lock Screen & Gesture Feedback:** Brightness and volume swipe gestures with visual HUD.
  8. **Watch Progress Synchronization:** Emits progress updates every 10 seconds to `LibraryBloc` and local storage.

---

### 3.5 Add-ons & Engine Hub (`AddonsScreen`)
* **Route:** `/addons`
* **Purpose:** Modular add-on management conforming to Stremio v3 protocol specifications.
* **Sections:**
  1. **Core Stream Engines:**
     * **Free Community Engine (Torrentio / Public Gateways):** 1-click install/uninstall/toggle.
  2. **Utility & Subtitles:**
     * **OpenSubtitles Engine:** Subtitle provider add-on.
  3. **Installed Add-ons & Custom Manifests:**
     * Add custom Stremio manifest URLs (e.g., Debrid-configured Cinemeta, CyberFlix, Torrentio, Comet).
     * Toggle status, test manifest health, and uninstall add-ons.

---

### 3.6 My Library & Offline Downloads (`DownloadsScreen` / `LibraryScreen`)
* **Route:** `/library` and `/downloads`
* **Structure (5 Tabbed Views):**
  1. **Wishlist:** Saved media items.
  2. **Downloads:**
     * Storage breakdown banner (Total, Available, Used by Aura).
     * Active background downloading tasks with speed (MB/s) and progress percentages.
     * Offline Vault: Categorized into **Offline Movies** and **Offline Episodes** with instant direct playback.
     * Delete all / single item deletion.
  3. **Watchlist:** Primary user watchlist.
  4. **Continue Watching:** Media in-progress cards with percentage bars and quick-resume buttons.
  5. **History:** Chronological watch history with individual item removal.

---

### 3.7 Clips Reel (`ClipsScreen` & `ClipsReelScreen`)
* **Route:** `/clips`
* **Purpose:** TikTok/Reels-style vertical swipe video feed showing high-definition trailers and preview clips.
* **Architecture:**
  * Uses `youtube_explode_dart` to extract direct progressive video streams from YouTube trailer IDs.
  * **3-Controller Window Memory Management:** Only active, next (+1), and previous (-1) video controllers are kept in memory; distant controllers are disposed to prevent GPU/RAM memory leaks.
  * Interactive overlay: Like button, sound mute toggle, share, and "Watch Now" navigation to details.

---

### 3.8 Search Screen (`AmbientSearchScreen`)
* **Route:** `/search`
* **Functionality:**
  1. **Minified Pill Search Bar:** Debounced real-time TMDB search with clear button.
  2. **Idle Discovery View:**
     * Recent searches with individual deletion chips and "Clear All".
     * Quick genre/category chips that route to `CategoryScreen`.
  3. **Active Results Grid:** 3-column responsive poster grid.

---

### 3.9 Category Screen (`CategoryScreen`)
* **Route:** `/category?genre=GenreName`
* **Functionality:**
  * Displays genre-specific hero carousel (featuring top-rated items with available clearart logos).
  * Filter pills: `Movies`, `Shows`, and `Short` (with sort options: Popular, New Release, Featured).
  * Infinite scroll media grid for the selected category.

---

### 3.10 Person Details Screen (`PersonDetailsScreen`)
* **Route:** `/person/:id`
* **Functionality:**
  * Fetches person biography, department, place of birth, and avatar from TMDB.
  * Expandable biography with "Read More / Show Less".
  * Full filmography poster grid.

---

### 3.11 Multi-Profile & Household Management
* **Route:** `/profiles` and Settings `Profile` sub-page.
* **Functionality:**
  * Support for up to 3 household profiles.
  * Gradient avatar customization, customizable display names, age restriction / content rating filters (Kids vs. Adults).
  * **4-Digit PIN Security (`PinEntryDialog`, `AuraPinModal`):** PIN protection for sensitive/adult profiles.
  * **Household Password System (`HouseholdPasswordSheet`):** Allows non-owner family members to log in using owner's email + household password without exposing the owner's Google password.

---

### 3.12 Settings Screen (`SettingsScreen`)
* **Route:** `/settings`
* **Sub-Pages:**
  1. **Account Details:** Google profile avatar, email, join date, Sign In / Sign Out modal.
  2. **Profile Sub-page:** Manage household profiles, PINs, and household password.
  3. **Interface Sub-page:** UI language, Quit on close, Escape exits fullscreen, Blur unwatched episodes, Gamepad support toggle.
  4. **Player Sub-page:** Default subtitle language, subtitle size, default audio track, surround sound toggle, auto-play next episode, hardware decoding toggle.
  5. **Streaming Sub-page:** Cache size allocation (`1GiB`, `2GiB`, `5GiB`, `10GiB`), Torrent profile (`Default`, `Fast`, `Low RAM`).
  6. **Policies & Licence Sub-pages:** Terms of Service, Privacy Policy disclosures, MIT license, and third-party attributions (TMDB, Firebase, MediaKit).

---

### 3.13 Watch Together (`WatchTogetherService` & `WatchTogetherOverlayHUD`)
* **Purpose:** Synchronized multi-user watch rooms with room code creation and joining.
* **Functionality:**
  * Drift detection algorithm: If client and host drift by $> 1.5\text{s}$, automatically seeks client to sync with host.
  * Host-only playback controls toggle.
  * Real-time floating emoji reaction overlay.

---

### 3.14 Trakt.tv Scrobbling (`TraktAuthService` & `TraktScrobbleService`)
* **Functionality:**
  * Trakt Device Code OAuth2 authentication flow (`/oauth/device/code`).
  * Automatic token refresh and secure storage.
  * Scrobble events: start (when media begins), pause, and stop (marking watched if $\ge 80\%$).

---

## 4. Strengths & Architectural Highlights

1. **Decoupled 100% Legal Architecture:** No copyrighted content is bundled or scraped in-app; all streams come from user-configured Stremio v3 add-ons or direct Debrid HTTPS gateways.
2. **Native Performance:** `media_kit` (libmpv) provides smooth hardware decoding for 4K HEVC/AV1 and styled ASS subtitles.
3. **Robust Offline System:** Sandboxed download execution with range request resumption, speed tracking, and offline scrobble vault.
4. **Memory Hygiene:** 3-controller window in Clips and lazy stream disposal prevent memory degradation.
5. **Modern Design Language:** Glassmorphism, tailored typography, custom shimmer skeletons, and ambient backdrop glow.

---

## 5. Areas for Improvement, Missing Links & Recommendations

### 5.1 Immediate Polish & Fixes (Short-Term)
1. **Duplicate Search Screen Cleanup:**
   * Currently, two search screens exist: `lib/features/search/presentation/screens/search_screen.dart` (AmbientSearchScreen) and `lib/features/catalog/presentation/screens/search_screen.dart`. Clean up any obsolete duplicate references.
2. **Settings Tab Navigation History:**
   * Ensure standard Android/iOS back swipe smoothly pops Settings sub-pages before exiting the screen.
3. **Debrid Service Settings UI:**
   * While `HttpDebridEngine` exists and supports headers, adding a dedicated Real-Debrid / TorBox API key management card in the Streaming settings tab would allow users to input credentials directly without relying exclusively on add-on URLs.

### 5.2 High-Impact Functional Features (Mid-Term)
1. **Trakt Full Sync:**
   * Wire the "Authenticate" button in `SettingsScreen` directly into `TraktAuthService.generateDeviceCode()` dialog, showing the user the 8-character code and activation URL.
2. **Android TV & D-Pad Optimization:**
   * Expand `DpadFocusCard` and `TvNavigationService` across the Discovery shelves, Details screen, and Player overlay for seamless 10-foot TV experience.
3. **Torrent Stream Sequential Proxy:**
   * Integrate a pure-Dart lightweight torrent engine or bridge for platforms supporting local torrent streaming when Debrid is not configured.

### 5.3 Advanced Features & Innovations (Long-Term)
1. **WebRTC Watch Together Integration:**
   * Connect `WatchTogetherService` to a live WebRTC signaling server or Supabase Realtime channel for instant zero-latency multi-device playback synchronization.
2. **Picture-in-Picture (PiP) on iOS & Android:**
   * Enable native PiP via `media_kit` / platform channels when the user navigates away from the player while playback is active.
3. **Subtitle Search via OpenSubtitles REST API:**
   * Add a direct "Search Subtitles Online" modal in the player controls to download and load `.srt` tracks on the fly.
