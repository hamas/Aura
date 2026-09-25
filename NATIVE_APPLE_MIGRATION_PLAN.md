# Aura — Native Apple Platform (iOS & macOS) Implementation Plan & Task List

> **Project:** `aura-swift` (Native Apple Migration to match 100% Android/Flutter functionality)  
> **Target Frameworks:** SwiftUI, Combine, AVFoundation, SwiftData, Keychain, WebSockets, AppIntents  
> **Platforms:** iOS 17+, iPadOS 17+, macOS 14+ (Sonoma/Sequoia)

---

## 1. Architectural Strategy & Phased Roadmap

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 PHASE 1: NATIVE APPLE NAVIGATION & HIG SHELL                │
│  • iOS: AuraFloatingBottomTabBar + NavigationStack tab containers           │
│  • macOS: NavigationSplitView + vibrancy visual effects + keyboard shortcuts│
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                    PHASE 2: CATALOG & METADATA EXPANSION                    │
│  • SeasonEpisodePickerView (season tabs, episode cards, progress indicators)│
│  • PersonDetailsView (actor bio, credits, filmography grid)                 │
│  • Live debounced TMDB Search & Category Filter Modals                     │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                 PHASE 3: CLIPS REELS & WATCH TOGETHER ROOMS                 │
│  • ClipsFeedView (vertical paging ScrollView + auto-looping AVPlayers)      │
│  • WatchTogetherEngine (WebSocket clock sync, host controls, in-room chat) │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                 PHASE 4: STREMIO ADDONS & DEBRID STREAM ENGINE              │
│  • StremioAddonEngine (v3 manifest.json parser, dynamic stream queries)    │
│  • DebridService (Real-Debrid, Premiumize, TorBox HTTP unrestricting)       │
│  • StreamRanker (score streams by 4K, HDR, Atmos, seeders & Debrid cache)   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│              PHASE 5: TRAKT SCROBBLER, DOWNLOAD VAULT & PROFILES            │
│  • TraktManager (OAuth2 PKCE, auto-scrobble, watchlist cloud sync)          │
│  • DownloadManager (background URLSession, encrypted vault, offline queue) │
│  • ProfileManager (multi-profile switcher, kids filter, FaceID / 4-digit PIN)│
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│              PHASE 6: VIDEO PLAYER & APPLE ECOSYSTEM INTEGRATION            │
│  • AVPlayer aspect ratios (Fit/Fill/16:9/21:9), subtitle delay & audio boost│
│  • Double-tap ±10s seek, vertical drag brightness/volume, iOS Haptics      │
│  • Control Center MPNowPlayingInfoCenter & macOS Native Menu Commands       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Detailed Milestone & Task Breakdown

### Phase 1: Native Apple Navigation & HIG Shell
- **Objective:** Establish fluid navigation architecture on iOS and macOS.
- **Tasks:**
  - [ ] Create `AuraFloatingBottomTabBar.swift` for iOS with glassmorphism blur and selection glow
  - [ ] Create `iOSAppShellView.swift` managing 5 core tabs (Home, Clips, Library, Addons, Settings)
  - [ ] Wrap each tab in a native SwiftUI `NavigationStack`
  - [ ] Enhance `MacOSSidebarView.swift` with vibrant `NSVisualEffectView` background and badge counts
  - [ ] Add macOS Native Menu Bar commands (`.commands`) for File, View, Playback, and Window controls
  - [ ] Replace root ZStack overlays with native `.sheet` / `.fullScreenCover` presentation

### Phase 2: Catalog Expansion & Metadata Views
- **Objective:** Add full episodic season/episode management and actor filmography views.
- **Tasks:**
  - [ ] Create `SeasonEpisodePickerView.swift` with season tabs, episode thumbnails, synopsis, and air dates
  - [ ] Add per-episode watch progress indicators and quick play stream actions
  - [ ] Create `PersonDetailsView.swift` displaying actor bio, birthplace, birthday, and filmography grid
  - [ ] Wire cast item taps in `MediaDetailsView` to push `PersonDetailsView` on navigation stack
  - [ ] Implement live debounced search in `CustomToolbar` with year, rating, and genre filters

### Phase 3: Clips Feed & WatchTogether System
- **Objective:** Port vertical video short reels and synchronized multi-user watch rooms.
- **Tasks:**
  - [ ] Create `ClipsFeedView.swift` leveraging vertical paged `ScrollView` with `.scrollTargetBehavior(.paging)`
  - [ ] Implement lightweight `AVPlayer` pool for instant video trailer pre-loading and looping
  - [ ] Add liquid glass overlay buttons (Like, Add to Watchlist, Play Full Movie, Mute/Unmute)
  - [ ] Create `WatchTogetherEngine.swift` managing WebSocket real-time room sessions
  - [ ] Implement NTP network clock synchronization for millisecond-accurate seek alignment
  - [ ] Create `WatchTogetherRoomView.swift` with room code generation, participant status avatars, and floating chat overlay

### Phase 4: Stremio Add-on Protocol & Debrid Stream Engine
- **Objective:** Build decentralized add-on parsing and Debrid stream unrestricting.
- **Tasks:**
  - [ ] Create `StremioAddonEngine.swift` parsing v3 `manifest.json` endpoints
  - [ ] Add custom add-on repository URL installer and preset directory
  - [ ] Create `DebridService.swift` supporting Real-Debrid, Premiumize, and TorBox APIs
  - [ ] Create `StreamRankerService.swift` scoring streams by resolution (4K), HDR, Atmos audio, seeders, and Debrid cache
  - [ ] Create `StreamPickerSheet.swift` displaying stream metadata tags (4K, HDR, Dolby Vision, seeders, file size)

### Phase 5: Trakt Scrobbler, Smart Download Vault & Profiles
- **Objective:** Port cloud scrobbling, offline storage vault, and multi-user PIN security.
- **Tasks:**
  - [ ] Create `TraktManager.swift` with OAuth2 PKCE authentication and secure Keychain storage
  - [ ] Integrate automatic scrobble events (start, pause, 80% completion) into `AVPlayerManager`
  - [ ] Create `DownloadManager.swift` wrapping background `URLSessionDownloadTask` with pause/resume
  - [ ] Implement sandboxed encrypted storage under `Application Support/OfflineVault/`
  - [ ] Create `OfflineScrobbleVault.swift` to buffer watched progress offline and sync to Trakt when reconnected
  - [ ] Create `ProfileManager.swift` supporting multi-user profiles with Kids content filters
  - [ ] Create `AuraPinModal.swift` with FaceID / TouchID biometric authentication and 4-digit PIN unlock

### Phase 6: Video Player Engine & Apple Ecosystem Polish
- **Objective:** Finalize AVPlayer capabilities, gestures, Control Center, and macOS integrations.
- **Tasks:**
  - [ ] Change default video gravity to `.resizeAspect` and add Aspect Ratio toggle button (Fit / Fill / 16:9 / 21:9)
  - [ ] Add Subtitle Offset Delay adjuster (+/- 0.5s) in player HUD
  - [ ] Add Audio Enhancer selector (Night mode, Vocal clarity, Volume boost)
  - [ ] Implement double-tap left/right screen halves to seek ±10 seconds with ripple animations
  - [ ] Add vertical edge drag gestures for Screen Brightness (left) and System Volume (right)
  - [ ] Implement `NowPlayingService.swift` updating `MPNowPlayingInfoCenter` and handling `MPRemoteCommandCenter` commands
  - [ ] Wire `iOSHapticsManager` to all tab switches, card taps, and HUD button presses
  - [ ] Add macOS keyboard shortcuts ($\text{⌘F}$ Fullscreen, $\text{⌘P}$ PiP, Space Play/Pause, Left/Right arrows)
  - [ ] Add `.refreshable` pull-to-refresh on home feed and catalog screens
  - [ ] Audit player resource cleanup on player close/dismissal

---

## 3. Verification & Compliance Checklist

- [ ] **100% Feature Parity:** Verify all 15 feature modules from `aura-flutter` are fully operational in native `aura-swift`.
- [ ] **Apple HIG Compliance:** Confirm native SwiftUI navigation, liquid glass materials, SF Symbols 5+, and proper macOS/iOS UI adaptations.
- [ ] **Performance Baseline:** 60/120 FPS liquid scrolling with zero frame drops using `ImageCacheService`.
- [ ] **Simulator & Hardware Test:** Build, install, and execute verified test runs on iOS Simulator and macOS desktop.
