# Tasks: Stream Hardening, TV Binge Flow, Download Integrity & Web Directory

- [ ] Phase 1: Playback Core & Stream Compatibility <!-- id: 0 -->
  - [ ] Full Stremio `behaviorHints` parsing (`proxyHeaders`, `bingeGroup`, `filename`, `videoHash`, `videoSize`) <!-- id: 1 -->
  - [ ] Container audio track extraction & language picker modal in `PlayerTrackPickers` <!-- id: 2 -->
  - [ ] Buffer cushion telemetry calculation & 15-second network stall toast prompt <!-- id: 3 -->
- [ ] Phase 2: TV Series Binge Flow & Navigation <!-- id: 4 -->
  - [ ] Next episode countdown overlay triggered at remaining duration $\le$ 20s <!-- id: 5 -->
  - [ ] Seamless episode stream resolution & transition in `PlayerBloc` without unmounting player <!-- id: 6 -->
  - [ ] In-player episode selector modal drawer with season selector dropdown & episode tiles <!-- id: 7 -->
- [ ] Phase 3: Offline Download Engine Hardening <!-- id: 8 -->
  - [ ] Storage capacity guard before starting/resuming downloads (free space $\ge$ `contentLength + 500MB`) <!-- id: 9 -->
  - [ ] Wi-Fi connection enforcement (`downloadOnWifiOnly`) pausing downloads on cellular network <!-- id: 10 -->
  - [ ] Vault cleanup and file purge on task deletion <!-- id: 11 -->
- [ ] Phase 4: Static Add-on Directory Web Page <!-- id: 12 -->
  - [ ] Build `web_addon_directory/index.html` with Stremio add-on registry fetching <!-- id: 13 -->
  - [ ] Category filters, "Install to Aura" deep-link actions, Debrid setup guide, & legal footer <!-- id: 14 -->
- [ ] Phase 5: Verification & Test Suite <!-- id: 15 -->
  - [ ] Unit & widget tests: `audio_track_and_buffer_test.dart`, `binge_navigation_test.dart`, `storage_guard_test.dart` <!-- id: 16 -->
  - [ ] Run `flutter analyze` & `flutter test` to ensure 0 errors/warnings and 100% test pass rate <!-- id: 17 -->
