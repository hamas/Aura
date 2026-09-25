# Aura iOS — Optimization Plan & Task List

> **Project:** `aura-swift` (iOS / iPadOS Native Optimization)  
> **Goal:** Transform `aura-swift` into a fluid, multi-tab, hardware-accelerated, Apple TV+-grade mobile app.

---

## 1. Architectural Strategy & Phased Execution

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             PHASE 1: NAVIGATION                             │
│  • Floating Glass Bottom Tab Bar (Home, Movies/Shows, Library, Addons, Settings)│
│  • NavigationStack hierarchy for deep navigation & native swipe back        │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                            PHASE 2: RESPONSIVE UI                           │
│  • Dynamic 2-column mobile grid math (375pt–430pt adaptive sizing)          │
│  • Dynamic Island & Notch safe-area header blur integration                 │
│  • Shimmer loading skeletons & card aspect ratio fixes                      │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                         PHASE 3: VIDEO PLAYER ENGINE                        │
│  • Fix video cropping (.resizeAspect default + Fit/Fill/16:9/21:9 toggle)   │
│  • Gesture controls (Double-tap ±10s seek, vertical drag brightness/volume)  │
│  • MPNowPlayingInfoCenter & MPRemoteCommandCenter lock screen integration   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                     PHASE 4: PERFORMANCE & CACHING                          │
│  • NSCache + Disk ImageCacheService for instant poster scrolling            │
│  • Haptic feedback integration (iOSHapticsManager)                          │
│  • Pull-to-refresh & Memory release lifecycle listeners                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Phase-by-Phase Milestone Breakdown

### Phase 1: Navigation Architecture & Tab Bar System
- **Objective:** Enable full iOS screen access across all modules (Home, Discovery, Movies, TV, Library, Downloads, Addons, Settings, WatchTogether, Profile).
- **Deliverables:**
  1. `AuraFloatingBottomTabBar.swift`: Floating glassmorphic tab bar with blur backdrop, selection glow, and smooth animations.
  2. `iOSAppShellView.swift`: Container view managing tab switching and root `NavigationStack` boundaries.
  3. Presentation refactoring: Replace root ZStack overlays with native `.sheet` / `.fullScreenCover` for details and full-screen video playback.

### Phase 2: Responsive Mobile Layout & Visual Polish
- **Objective:** Ensure pixel-perfect layout across iPhone SE, iPhone 14/15/16/17/18, and iPad screens.
- **Deliverables:**
  1. Dynamic grid items calculation: `GridItem(.flexible())` for 2-column mobile viewports.
  2. Safe Area Inset toolbar adjustment (`.safeAreaInset(edge: .top)`).
  3. Integrated hero carousel flow under transparent progressive blur navigation bar.
  4. Shimmer loading skeleton component (`ShimmerView.swift`).

### Phase 3: Video Player Subsystem & Mobile Interactions
- **Objective:** Fix aspect ratio cropping and introduce standard touch gestures & lock screen integration.
- **Deliverables:**
  1. Aspect Ratio selector in `CustomPlayerHUD`: Aspect Fit, Aspect Fill, 16:9, 21:9.
  2. Touch gestures overlay: Left/Right double-tap seek (±10 seconds) with feedback animations.
  3. Vertical drag gestures on screen edges for Screen Brightness and Volume.
  4. `NowPlayingService.swift`: Sync title, artwork, playback progress with iOS Control Center & Lock Screen.

### Phase 4: Performance, Memory & Platform Features
- **Objective:** Achieve 60/120 FPS liquid scrolling and instant image rendering.
- **Deliverables:**
  1. `ImageCacheService.swift`: In-memory `NSCache` and sandboxed disk cache.
  2. Integration of `iOSHapticsManager` into buttons, tabs, card taps, and scrubbers.
  3. Pull-to-refresh (`.refreshable`) on home and catalog scroll views.
  4. Memory cleanup on player stop/dismissal to prevent memory growth during long 4K playback sessions.

---

## 3. Master Task List Checklist

### Phase 1: Navigation & Structure
- [ ] Create `AuraFloatingBottomTabBar.swift` with glassmorphism blur and tab selection state
- [ ] Build `iOSAppShellView.swift` to house bottom navigation bar and tab routing
- [ ] Wrap main sections in `NavigationStack` for deep navigation into media details
- [ ] Refactor `MainFeedView.swift` to adopt `iOSAppShellView` on iOS builds
- [ ] Convert `MediaDetailsView` presentation to native `.sheet` / `.fullScreenCover`
- [ ] Convert `VideoPlayerView` presentation to managed `.fullScreenCover`

### Phase 2: Mobile UI & Layout Adaptation
- [ ] Update `LazyVGrid` across `MainFeedView`, `LibraryView`, `MoviesView`, and `FavoritesView` to 2 flex columns on mobile
- [ ] Fix `CustomToolbar` top padding to handle Dynamic Island & Notch safe areas cleanly
- [ ] Enable hero carousel scrolling under transparent progressive blur header
- [ ] Create `ShimmerView.swift` for network loading placeholder animations
- [ ] Standardize poster card aspect ratios to 2:3 and rail thumbnails to 16:9

### Phase 3: Player Enhancements & Gestures
- [ ] Change default `AVPlayerLayer.videoGravity` to `.resizeAspect` in `VideoPlayerView.swift`
- [ ] Add Aspect Ratio selector button (Fit / Fill / 16:9 / 21:9) to `CustomPlayerHUD.swift`
- [ ] Implement double-tap left/right screen halves to seek -10s / +10s with visual indicator ripples
- [ ] Add vertical drag gesture handlers for Screen Brightness (left) and System Volume (right)
- [ ] Implement `NowPlayingService.swift` for `MPNowPlayingInfoCenter` & `MPRemoteCommandCenter` integration

### Phase 4: Performance & Platform Integration
- [ ] Implement `ImageCacheService.swift` with `NSCache` and disk persistence
- [ ] Wire `iOSHapticsManager` to tab bar switches, card taps, and HUD button presses
- [ ] Add `.refreshable` pull-to-refresh to catalog and feed scroll views
- [ ] Audit player resource cleanup on player close/dismissal
- [ ] Verify build and install updated iOS app on simulator

---

## 4. Verification & Testing Criteria

- [ ] **Tab Access:** Verify all 5 core tabs (Home, Movies/Shows, Library, Addons, Settings) are accessible on iPhone.
- [ ] **Responsive Grid:** Confirm 2 cards per row rendering on 375pt, 390pt, and 430pt iPhone widths without horizontal overflow.
- [ ] **Player Aspect Ratio:** Verify 21:9 cinematic movies play in Aspect Fit by default without cropping side content.
- [ ] **Gesture Seek:** Verify double-tap seeks ±10 seconds with haptic feedback.
- [ ] **Lock Screen Controls:** Verify control center shows title, artwork, and responds to pause/play remote commands.
- [ ] **Zero Lag Scrolling:** Confirm smooth 60/120 FPS poster scrolling without network image re-fetch jitter.
