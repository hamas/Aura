//
//  AuraApp.swift
//  Aura
//
//  Created for Aura Native Apple Track (iOS & macOS)
//  Bundle Identifier: com.aura.app.aura
//

import SwiftUI
import AVFoundation

@main
struct AuraApp: App {
    @StateObject private var playerManager = AVPlayerManager()
    
    init() {
        AudioSessionManager.shared.configurePlaybackSession()
    }
    
    var body: some Scene {
        WindowGroup {
            MainFeedView()
                .environmentObject(playerManager)
                .preferredColorScheme(.dark)
                #if os(macOS)
                .frame(minWidth: 1000, minHeight: 700)
                #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
