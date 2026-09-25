# Aura macOS — Native Desktop Optimization Plan & Task List

> **Target:** `aura-swift` (macOS Target)  
> **Goal:** Transform `aura-swift` on macOS into a desktop-native, hardware-accelerated, Apple TV+ / Mac App Store-grade cinematic application with 100% feature parity with the Android/Flutter client.  
> **Frameworks:** SwiftUI, AppKit, AVFoundation, Combine, SwiftData, WebSockets  
> **System Requirements:** macOS 14.0+ (Sonoma / Sequoia)

---

## 1. Architectural Strategy & Desktop HIG Paradigm

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 PHASE 1: DESKTOP NAVIGATION & SIDEBAR SHELL                 │
│  • macOS NavigationSplitView with vibrant NSVisualEffectView sidebar        │
│  • Comprehensive sidebar sections (Home, Clips, Addons, WatchTogether, etc.)│
│  • Native macOS window titlebar transparency & traffic light padding        │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                    PHASE 2: DESKTOP FEATURE PARITY PORT                     │
│  • Clips Feed (macOS keyboard/trackpad paged trailer viewer)                │
│  • WatchTogether Rooms (multi-user synchronized player + side chat panel)   │
│  • Add-on Manager & Debrid Stream Engine (Stremio v3 parser + Real-Debrid)  │
│  • Trakt.tv Scrobbler, Smart Downloads & Profile Switcher Footer            │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                  PHASE 3: DESKTOP VIDEO PLAYER & PIP ENGINE                 │
│  • Hardware-accelerated AVPlayerView with transparent HUD & cursor auto-hide │
│  • Aspect Ratio modes (Aspect Fit default, Fill, 16:9, 21:9)                │
│  • Native macOS Picture-in-Picture (AVPictureInPictureController)           │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│            PHASE 4: MAC COMMAND MENU BAR & KEYBOARD SHORTCUTS               │
│  • macOS Commands (.commands): File, Edit, View, Playback, Audio, Window    │
│  • Global keyboard shortcuts (Space, ⌘F, ⌘P, ⌘M, Arrow Keys)                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Phase-by-Phase Milestone Breakdown

### Phase 1: Desktop Navigation & Sidebar Shell
- **Objective:** Upgrade `MacOSSidebarView.swift` to include all 15 core feature sections with native macOS vibrancy and window titlebar integration.
- **Deliverables:**
  1. Complete `SidebarSection` enumeration: Home, Discovery, Movies, TV Shows, Categories, **Clips**, **WatchTogether**, **Add-ons**, Wishlist, Downloads, Watchlist, History, **Trakt**, and Settings.
  2. Bottom profile switcher footer displaying active user avatar, profile name, and quick profile switcher button.
  3. Window titlebar transparency with `WindowAccessor` and native `NSVisualEffectView` translucent blur.

### Phase 2: Complete Desktop Feature Parity Port
- **Objective:** Connect all feature screens to the macOS detail view router.
- **Deliverables:**
  1. `ClipsFeedView`: Trackpad scroll / arrow-key paged trailer reels for desktop screens.
  2. `WatchTogetherRoomView`: Split-pane layout with video player on left and live room chat/participants panel on right.
  3. `AddonsView`: Stremio v3 add-on repository hub, custom URL installation dialog, and manifest parser.
  4. `DebridService` & `StreamRankerService`: Stream resolver fetching Real-Debrid, Premiumize, TorBox HTTP links and displaying stream quality tags.
  5. `TraktManager`: Trakt OAuth2 login, auto-scrobbling, and watchlist cloud sync.
  6. `DownloadManager`: Background file downloader with sandboxed storage manager.
  7. `SeasonEpisodePickerView` & `PersonDetailsView`: Episode list tabs and actor filmography grid.

### Phase 3: Desktop Video Player Subsystem
- **Objective:** Optimize native macOS video playback, cursor hiding, aspect ratios, and Picture-in-Picture.
- **Deliverables:**
  1. Set default video gravity to `.resizeAspect` (Aspect Fit) to avoid cropping 21:9 cinematic movies on 16:9 or 16:10 Mac displays (MacBook Pro XDR, Studio Display).
  2. Add Aspect Ratio toggle button (Fit / Fill / 16:9 / 21:9) to `CustomPlayerHUD`.
  3. Cursor auto-hide timer: Hide mouse pointer after 3 seconds of inactivity during video playback.
  4. Native macOS Picture-in-Picture via `AVPictureInPictureController`.

### Phase 4: macOS Menu Bar Commands & Keyboard Shortcuts
- **Objective:** Full compliance with macOS Human Interface Guidelines (HIG) keyboard shortcuts and app commands.
- **Deliverables:**
  1. `.commands` modifier on `WindowGroup`:
     - **File Menu:** Open Stream URL ($\text{⌘O}$), Install Add-on ($\text{⌘I}$).
     - **Playback Menu:** Play / Pause ($\text{Space}$), Mute ($\text{⌘M}$), Skip Forward +10s ($\rightarrow$), Skip Backward -10s ($\leftarrow$), Aspect Ratio ($\text{⌘A}$).
     - **Window Menu:** Toggle Fullscreen ($\text{⌘F}$), Toggle Picture-in-Picture ($\text{⌘P}$).
  2. Native macOS Touch Bar controls (if hardware present).

---

## 3. Master Task List Checklist for macOS

### Phase 1: Navigation & Sidebar
- [ ] Update `SidebarSection` in `MacOSSidebarView.swift` to include `Clips`, `WatchTogether`, `Addons`, `Trakt`, and `Profiles`
- [ ] Add profile switcher footer button at bottom of sidebar
- [ ] Polish `NSVisualEffectView` vibrancy background on sidebar
- [ ] Ensure proper titlebar top spacing (`38pt`) for window traffic lights (Red/Yellow/Green)

### Phase 2: Feature Parity & Views
- [ ] Connect `ClipsFeedView` to `.clips` sidebar section with trackpad page scroll
- [ ] Connect `WatchTogetherView` to `.watchTogether` sidebar section with desktop split-pane layout
- [ ] Connect `AddonsView` to `.addons` sidebar section with add-on installer dialog
- [ ] Connect `SettingsView` with Trakt OAuth2 login and Debrid API Key inputs
- [ ] Implement `DebridService.swift` and `StreamRankerService.swift` for stream resolution
- [ ] Implement `TraktManager.swift` auto-scrobble integration with `AVPlayerManager`
- [ ] Build `SeasonEpisodePickerView.swift` for TV show details on macOS
- [ ] Build `PersonDetailsView.swift` for actor filmography grids on macOS

### Phase 3: Player & Picture-in-Picture
- [ ] Fix default video gravity to `.resizeAspect` in `AVPlayerView` (macOS wrapper)
- [ ] Add Aspect Ratio selector button to `CustomPlayerHUD.swift`
- [ ] Add mouse pointer auto-hide mechanism on 3-second cursor idle during video playback
- [ ] Enable native macOS Picture-in-Picture windowing
- [ ] Support multi-monitor display output selection

### Phase 4: macOS Keyboard Shortcuts & Commands
- [ ] Add `.commands` modifier to `AuraApp.swift` with File, Playback, and Window menus
- [ ] Bind `Space` key to Play/Pause toggle
- [ ] Bind `Left Arrow` / `Right Arrow` to seek -10s / +10s
- [ ] Bind `⌘F` to toggle full-screen windowing
- [ ] Bind `⌘P` to toggle Picture-in-Picture windowing
- [ ] Bind `⌘M` to toggle audio mute

---

## 4. Verification & Testing Criteria

- [ ] **Sidebar Complete:** Confirm all 15 sections are navigable from macOS sidebar.
- [ ] **No Aspect Cropping:** Confirm 21:9 movies display in Aspect Fit by default without cropping on MacBook liquid retina displays.
- [ ] **Shortcuts Working:** Verify Space bar toggles play/pause, Arrow keys seek, and $\text{⌘F}$ enters fullscreen.
- [ ] **Stream Resolution:** Verify add-on stream links resolve via Debrid engine and play in AVPlayer.
- [ ] **PiP Windowing:** Verify Picture-in-Picture detaches cleanly into a floating desktop window.
