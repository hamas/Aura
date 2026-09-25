# Aura — Native Apple Platform (iOS & macOS) Audit & Migration Analysis

> **Goal:** Achieve 100% feature parity with the Android/Flutter (`aura-flutter`) client on native Apple platforms (`aura-swift`) using pure SwiftUI, AVFoundation, and Apple Human Interface Guidelines (HIG) native design aesthetics.
> **Date:** September 25, 2026  
> **Status:** Gap Analysis & Native Architectural Audit

---

## 1. Executive Summary

The Android/Flutter client (`aura-flutter`) is a feature-complete media center engine containing 15 distinct modules (Stremio v3 add-on parsing, Real-Debrid/TorBox unrestrictors, Trakt.tv scrobbling, Clips vertical shorts reel, WatchTogether real-time rooms, Smart Download Vault, Multi-Profiles with PIN protection, Episodic Season/Episode pickers, and Cast filmography).

In contrast, the native Apple implementation (`aura-swift`) currently contains basic UI prototypes for catalog browsing and video playback, but lacks over **70% of the core functionality, protocol engines, state synchronization, and native Apple HIG design integration**.

This document details every screen, feature, protocol engine, and design element present in `aura-flutter` that must be implemented natively in `aura-swift` for iOS and macOS.

---

## 2. Feature & Screen Parity Matrix

| Feature / Screen Module | Android / Flutter (`aura-flutter`) | Native Swift (`aura-swift`) Current State | Required Native Swift (`aura-swift`) Action |
| :--- | :---: | :---: | :--- |
| **Catalog & Hero Carousel** | ✅ Fully Featured + Filters | ⚠️ Prototype UI Only | Connect live TMDB v3/v4 API, category modals, and search debouncing |
| **Episodic Season/Episode Picker** | ✅ Full Seasons & Episode Lists | ❌ Missing | Build `SeasonEpisodePickerView` with episode thumbnails, synopsis, air dates & progress |
| **Cast & Person Filmography** | ✅ `PersonDetailsScreen` | ❌ Missing | Build `PersonDetailsView` with bio, credits, and filmography grid |
| **Clips (Shorts Reel)** | ✅ Vertical Video Reel Feed | ❌ Completely Missing | Build `ClipsFeedView` with vertical swipe gestures, auto-looping trailer player, and watchlist triage |
| **WatchTogether Rooms** | ✅ WebSockets + Supabase Sync | ❌ Stub Placeholder View | Build `WatchTogetherRoomView` with 6-character room codes, synchronized clock, host controls, and room chat |
| **Trakt.tv Integration** | ✅ OAuth2, Scrobble & Sync | ❌ Completely Missing | Build `TraktService.swift` with OAuth2 PKCE, auto-scrobble (start/pause/80% milestone), and cloud sync |
| **Stremio Add-on Protocol** | ✅ Full v3 Manifest & Stream Parser | ⚠️ Hardcoded Sample List | Build `AddonEngine.swift` parsing `manifest.json`, dynamic stream resolution, and custom repository URL installation |
| **Debrid & Stream Scoring** | ✅ Real-Debrid, TorBox, Stream Ranker | ⚠️ Basic Resolver Stub | Build `DebridService.swift` and `StreamRanker.swift` scoring by 4K/HDR, bitrate, seeders, codec & Debrid cache |
| **Smart Download Vault** | ✅ Offline Vault + Chunk Downloader | ⚠️ Static UI Mockup | Build `DownloadManager.swift` using `URLSessionDownloadDelegate`, encrypted vault, and offline Trakt scrobble queuing |
| **Profiles & Kids PIN** | ✅ Multi-Profiles + 4-digit PIN | ⚠️ Static UI Mockup | Build `ProfileManager.swift`, avatar picker, PIN lock modal, and rating filters |
| **Advanced Video Player** | ✅ Subtitles, Audio Boost, Chapters | ⚠️ Basic AVPlayer Controls | Add Subtitle Sync Delay adjuster, Audio Night/Clarity Enhancer, Chapter markers, Next Episode auto-play prompt, Aspect Fit/Fill/16:9/21:9 toggle |
| **iOS Navigation System** | ✅ Bottom Pill Bar + Shell | ❌ Missing on iOS | Build `AuraFloatingBottomTabBar` for iPhone + `NavigationStack` boundaries |
| **macOS Desktop Integration** | ✅ Native Shortcuts & Responsive | ⚠️ Basic Sidebar | Add macOS Native Menu Bar commands, keyboard shortcuts ($\text{⌘F}$, $\text{⌘P}$, Space, $\leftarrow/\rightarrow$), multi-monitor output, and Touch Bar |
| **Lock Screen / Control Center** | ✅ Supported | ❌ Missing | Integrate `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` |
| **Image Caching & Performance** | ✅ Cached Network Images | ❌ Un-cached `AsyncImage` | Build `ImageCacheService.swift` (`NSCache` + Disk cache) with shimmer loading skeletons |

---

## 3. Deep Feature-by-Feature Gap Breakdown

### 3.1 Clips Feed Module (`lib/features/clips`)
- **Android Capability:** Vertical TikTok/Reels-style media trailer player. Users can swipe up/down to discover trending trailers, like clips, add movies to watchlist instantly, share trailers, or launch full movie playback.
- **Swift Deficit:** Completely absent in `aura-swift`.
- **Native Apple Requirement:**
  - Build `ClipsFeedView.swift` leveraging SwiftUI `ScrollView` with `.scrollTargetBehavior(.paging)`.
  - Instantiate lightweight `AVPlayer` instances with pre-fetching for instant vertical scrolling.
  - Add liquid glass overlay action buttons (Like, Add to Library, Play Full Movie, Mute/Unmute).

### 3.2 WatchTogether Synchronized Rooms (`lib/features/watch_together`)
- **Android Capability:** Real-time multi-user watch rooms over WebSockets and Supabase. Room hosts create 6-character room codes; guests join to synchronize video playback time, play/pause states, and seek timestamps with latency compensation. Includes floating overlay chat and participant avatars.
- **Swift Deficit:** `WatchTogetherView.swift` is a static placeholder screen displaying placeholder text.
- **Native Apple Requirement:**
  - Implement `WatchTogetherEngine.swift` using Apple's `URLSessionWebSocketTask` or Supabase Realtime SDK.
  - Implement NTP network clock synchronization for millisecond-accurate seek alignment.
  - Add room creation/joining dialogs, participant status avatars, and floating HUD overlay during video playback.

### 3.3 Trakt.tv Cloud Scrobbler (`lib/features/trakt`)
- **Android Capability:** Complete Trakt.tv ecosystem integration. Authenticates via OAuth2 PKCE, automatically scrobbles playback progress (starts scrobble on play, pauses on hold, completes watched status at 80% completion mark), and syncs watchlist/history bi-directionally.
- **Swift Deficit:** Completely absent in `aura-swift`.
- **Native Apple Requirement:**
  - Build `TraktManager.swift` for OAuth2 authentication, token refresh, and secure Keychain storage.
  - Integrate automatic scrobble events into `AVPlayerManager` time observers.
  - Add Trakt sync controls in Settings and Library.

### 3.4 Stremio v3 Add-on Engine (`lib/features/addons`)
- **Android Capability:** Full compliance with Stremio v3 add-on specification (`manifest.json`, `/catalog`, `/meta`, `/stream`, `/subtitles`). Supports installing add-ons from HTTPS URLs, community presets, enabling/disabling add-ons, and dynamic multi-provider stream querying.
- **Swift Deficit:** `AddonsView.swift` is a hardcoded UI list with sample strings; cannot parse manifests or execute real HTTP add-on requests.
- **Native Apple Requirement:**
  - Build `StremioAddonEngine.swift` for async JSON manifest parsing (`URLSession`).
  - Store installed add-on configurations in `SwiftData` or `UserDefaults`.
  - Query stream links asynchronously across all enabled add-on manifests in parallel (`withTaskGroup`).

### 3.5 Debrid HTTPS Engine & Torrent Ranker (`lib/features/engine` & `lib/features/streams`)
- **Android Capability:** Unrestricts torrent magnet hashes into high-speed HTTPS streams via Real-Debrid, Premiumize, and TorBox APIs. Filters and ranks streams by resolution (4K, 1080p), HDR format (HDR10+, Dolby Vision), audio channel count (7.1, 5.1, Atmos), seeder count, and instant Debrid cache status.
- **Swift Deficit:** `StreamResolverService.swift` returns mock URLs.
- **Native Apple Requirement:**
  - Build `DebridService.swift` implementing Real-Debrid, Premiumize, and TorBox REST endpoints.
  - Build `StreamRankerService.swift` to evaluate and score stream options based on user settings (prefer 4K, prefer HDR, prefer Atmos).
  - Present custom `StreamPickerSheet` displaying stream tags, bitrate, seeders, and file size.

### 3.6 Smart Download Vault & Offline Scrobbler (`lib/features/downloads`)
- **Android Capability:** Sandboxed offline media downloader supporting pause/resume, Wi-Fi-only restrictions, storage quota alerts, and an **Offline Scrobble Vault** that buffers watched media progress offline and auto-scrobbles to Trakt when internet is restored.
- **Swift Deficit:** `DownloadsView.swift` is a static UI layout.
- **Native Apple Requirement:**
  - Build `DownloadManager.swift` wrapping `URLSessionDownloadDelegate` for background downloads.
  - Store encrypted media files in the app's sandboxed `Application Support/OfflineVault/` directory.
  - Build `OfflineScrobbleVault.swift` to store offline watch progress and push to Trakt on network reconnect.

### 3.7 Profiles & Kids Security PIN (`lib/features/profiles`)
- **Android Capability:** Multi-profile switching with custom avatars, profile names, Kids content filtering, and 4-digit PIN protection for parent/admin profiles.
- **Swift Deficit:** `ProfileView.swift` is a placeholder.
- **Native Apple Requirement:**
  - Build `ProfileManager.swift` supporting profile persistence.
  - Build `AuraPinModal.swift` with biometric (FaceID / TouchID) and 4-digit PIN unlock.
  - Apply profile content filters to catalog queries.

### 3.8 Episodic Season/Episode Picker & Cast Details (`lib/features/catalog`)
- **Android Capability:** Comprehensive TV show breakdown with Season tabs, episode list/grid, episode backdrop thumbnail, synopsis, air date, and watch progress bar per episode. Also includes `PersonDetailsScreen` showing actor biography, birthplace, birthday, and filmography grid.
- **Swift Deficit:** `MediaDetailsView.swift` only shows movie-level metadata; lacks season/episode pickers and person filmography views.
- **Native Apple Requirement:**
  - Build `SeasonEpisodePickerView.swift` with season tabs and episode lists.
  - Build `PersonDetailsView.swift` with biography and filmography media grid.

---

## 4. Native Apple UI/UX & Design System Architecture

To ensure `aura-swift` looks and feels like a native, premium Apple application on iOS, iPadOS, and macOS, the UI must adhere strictly to **Apple Human Interface Guidelines (HIG)**:

### 4.1 iOS / iPadOS Navigation Design
- **Floating Glass Tab Bar (`AuraFloatingBottomTabBar`)**: Elevated blur pill anchored at screen bottom with SF Symbols 5 icons, selection glow animations, and responsive hidden behavior during full-screen video playback.
- **NavigationStack Boundaries**: Wrap each tab (Home, Clips, Library, Addons, Settings) in a native `NavigationStack` for fluid push/pop transitions and native iOS swipe-to-dismiss edge gestures.
- **Native Sheet & Modal Presentation**: Use `.sheet` and `.fullScreenCover` for details, stream pickers, profile editors, and video playback.

### 4.2 macOS Desktop Interface Design
- **NavigationSplitView**: Native 3-column or 2-column sidebar navigation (`MacOSSidebarView`) with semi-transparent vibrancy background (`NSVisualEffectView`).
- **Native Menu Bar Commands (`.commands`)**: Map macOS main menu shortcuts:
  - `File` $\rightarrow$ Open Stream URL ($\text{⌘O}$).
  - `Playback` $\rightarrow$ Play/Pause (Space), Toggle Mute ($\text{⌘M}$), Fullscreen ($\text{⌘F}$).
  - `Window` $\rightarrow$ Picture-in-Picture ($\text{⌘P}$).
- **Keyboard Shortcuts**: Arrow keys for video seeking ($\leftarrow / \rightarrow$), Volume up/down ($\uparrow / \downarrow$).

### 4.3 Design Tokens & Glassmorphism
- **Color Tokens**: Surface Background (`#0D0E12`), Surface Card (`#14161B`), Glow Pink (`#FF2D55`), Cinema Red (`#E50914`), IMDb Gold (`#F5C518`).
- **Typography**: San Francisco (`.system(size:weight:design:)`) / SF Pro Display & SF Compact across all views.
- **Glass Materials**: Native `.ultraThinMaterial` and `.thinMaterial` with 1pt border stroke (`Color.white.opacity(0.12)`).

---

## 5. Summary

By building out these protocol engines, screens, and design systems natively in Swift, `aura-swift` will provide Apple users with 100% of the functionality found in `aura-flutter`, elevated by native Apple performance, hardware acceleration, and HIG aesthetic excellence.
