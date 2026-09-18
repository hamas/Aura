# Store Submission & App Reviewer Guidelines

**Target Platforms:** Apple App Store (iOS/macOS) & Google Play Console (Android/Android TV)  
**Compliance Baseline:** App Store Guideline 4.2 / 5.2 & Google Play IP / Content Policy  

---

## 1. App Store Connect & Google Play Console Metadata

### App Title & Subtitle
- **App Title:** Aura — Cinematic Media Player
- **Subtitle (iOS):** TMDb Catalog & Subtitle Sync
- **Short Description (Android):** Modern media organizer & player powered by TMDb and open JSON manifests.

### Compliance-Safe Full Description

```text
Aura is a high-performance media organizer and player engineered for custom media catalog management.

KEY FEATURES:

• UNIFIED TMDb DISCOVERY: Browse trending movies, TV series, episode guides, cast profiles, and high-resolution backdrop artwork powered by The Movie Database (TMDb) API.
• EXTENSIBLE OPEN PROTOCOLS: Connect user-owned HTTP/JSON manifests conforming to the open Stremio v3 protocol specification for dynamic stream resolution.
• HARDWARE-ACCELERATED PLAYBACK: Render 4K HDR content seamlessly with multi-audio container track switching, ASS/SSA subtitle styling, and custom buffer management.
• TV SERIES BINGE FLOW: Next-episode countdown cards during end credits, episode transitions, and in-player season navigation sheets.
• DYNAMIC SUBTITLE ENGINE: Resolve external .srt and .vtt subtitle tracks with language badging and custom timing offset synchronization.
• OFFLINE MEDIA VAULT: Download media directly to sandboxed local storage with network constraint guards (Wi-Fi only) and gallery privacy protection.
• MULTI-PROFILE HOUSEHOLD: Manage up to 3 individual profiles with custom avatars, PIN protection, and personal watch histories.

NOTE: Aura functions purely as a neutral media manager and client interface. It does not host, provide, scrape, or distribute media content. Playback relies entirely on third-party APIs (TMDb) and user-configured open manifest endpoints.
```

### Compliant Search Keywords
`media catalog, tmdb organizer, video player, subtitle sync, movie tracker, episode guide, stream player, media vault`

---

## 2. App Reviewer Guidance Notes (For Apple & Google Testers)

### Functionality Walkthrough
Reviewers can test full app capabilities immediately upon first launch without requiring third-party add-ons:
1. **Catalog Browsing:** Launch the app to explore live TMDb trending media, genre rails, search filters, and cast biographies.
2. **Trailer Playback:** Tap any movie title on the home discovery rail and press **"Watch Trailer"** to view high-resolution official trailers.
3. **Watchlist & History:** Tap the **+ Library** button on any media page to test offline persistent state management across app launches.

### Neutral Protocol Statement for App Store Reviewers
> *"Aura is a neutral media client and organizer utilizing official APIs (The Movie Database) for metadata and trailers. It offers an open, extensible playback surface supporting user-configured Stremio v3 JSON manifests. Aura hosts, indexes, provides, or bundles zero copyrighted media or scraping endpoints."*

### Demo Credentials for Multi-Profile Testing
- **Owner Account:** `demo.reviewer@aura.app`
- **Owner Password:** `AuraReview2026!`
- **Household Member Email:** `demo.reviewer@aura.app`
- **Household Password:** `AuraReview2026!`
- **Test Profile PIN:** `1234`
