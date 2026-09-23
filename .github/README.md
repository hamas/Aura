# Aura Media Center Platform

![Swift](https://img.shields.io/badge/Swift-5.10+-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-17.0+-000000?style=for-the-badge&logo=apple&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-14.0+-000000?style=for-the-badge&logo=apple&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

Aura is a modular, high-performance streaming media client platform designed under a **dual-track architecture** for hardware-accelerated playback, top-tier Apple HIG aesthetics, and multi-platform expansion.

```text
Aura Monorepo Architecture
├── .github/
│   └── README.md          # Consolidated master documentation
├── .gitattributes         # Line endings & GitHub Linguist language overrides
├── .gitignore             # Multi-technology monorepo ignore rules
├── LICENSE                # MIT License (Copyright (c) 2026 Hamas Younis)
│
├── aura-swift/            # Standalone Native Apple Multiplatform App (iOS & macOS)
│   ├── Aura.xcodeproj/    # Native Xcode Project & Shared Target Scheme
│   ├── Shared/            # SwiftUI Views, AVPlayer Services, Models, Networking
│   │   ├── AuraApp.swift  # Main Application Entry Point (@main)
│   │   ├── Models/        # Media Catalog Data Models
│   │   ├── Networking/    # Async/Await HTTP Network Client
│   │   ├── Services/      # AVPlayerManager & AudioSessionManager
│   │   └── Views/         # Liquid Glass Design System, Catalog Feed, Video Player
│   ├── iOS/               # iOS Touch Haptics & Feedback Overrides
│   ├── macOS/             # macOS Window & Titlebar Overrides
│   └── Assets.xcassets/   # Liquid Glass Materials, AppIcon & Branding Assets
│
└── aura-flutter/          # Cross-Platform Client Track (Android, Windows, Web, TV)
    ├── lib/               # BLoC State Management & UI Components
    ├── android/           # Android Runner & Gradle build scripts
    ├── ios/               # Flutter iOS Runner
    └── macos/             # Flutter macOS Runner
```

---

## 🏛️ Dual-Track Architecture Strategy

Aura decouples native Apple development from cross-platform targets to eliminate performance compromises and deliver platform-native user experiences:

### 🍎 1. `aura-swift` (Native Apple Track)
- **Target Platforms:** iOS 17.0+ & macOS 14.0+
- **Technology Stack:** Pure Swift 5.10+, SwiftUI, `AVFoundation` (`AVPlayer`, `AVAudioSession`, `AVPictureInPictureController`).
- **Design System:** Apple Human Interface Guidelines (HIG), liquid glass `.ultraThinMaterial` backgrounds, continuous squircle curvature (`RoundedRectangle(cornerRadius: 18, style: .continuous)`), 120Hz ProMotion fluid animations.
- **Battery & Performance Optimization:** Zero-bridge hardware-accelerated 4K/HDR streaming engine. Features an **auto-hiding HUD overlay** (3.5s inactivity timer) that lets the screen compositor idle to conserve CPU/GPU energy during video playback.

### 💙 2. `aura-flutter` (Cross-Platform Track)
- **Target Platforms:** Android (Mobile & TV), Windows Desktop, Web.
- **Technology Stack:** Flutter 3.16+, Dart 3.x, BLoC Architecture (`flutter_bloc`, `hydrated_bloc`), `media_kit` (libmpv engine wrapper).
- **Capabilities:** D-Pad navigation management for Android TV, deep link handling, Stremio addon ingestion, remote cloud synchronization.

---

## 📋 System Prerequisites

- **Operating System:** macOS Sonoma 14.0 or macOS Sequoia 15.0+
- **Xcode:** Xcode 15.4 or Xcode 16+ (with iOS 17+ & macOS 14+ SDKs installed)
- **Flutter SDK:** Flutter 3.16.0 or newer (`sdk: '>=3.2.0 <4.0.0'`)
- **CocoaPods:** 1.13.0+ (required for `aura-flutter` native runners)

---

## 🚀 Building & Running

### 🍎 1. Running `aura-swift` (Xcode)

1. Open `aura-swift/Aura.xcodeproj` in Xcode:
   ```bash
   open aura-swift/Aura.xcodeproj
   ```
2. Select target scheme **Aura** and destination device (iOS Simulator, iPhone, or Mac).
3. Press **Cmd + R** to Build & Run.

Or compile via Xcode command line tools:
```bash
xcodebuild -project aura-swift/Aura.xcodeproj -scheme Aura -destination 'platform=macOS' build
```

---

### 💙 2. Running `aura-flutter` (Flutter CLI)

```bash
# Navigate to aura-flutter directory
cd aura-flutter

# Fetch dependencies
flutter pub get

# Execute static code analysis
flutter analyze

# Launch on target device or emulator
flutter run
```

---

## 📄 License

This repository is licensed under the terms of the MIT License. See [LICENSE](../LICENSE) for full details.

Copyright (c) 2026 Hamas Younis
