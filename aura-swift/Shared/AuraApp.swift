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
        .commands {
            CommandMenu("Playback") {
                Button("Play / Pause") {
                    playerManager.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Button("Toggle Mute") {
                    playerManager.toggleMute()
                }
                .keyboardShortcut("m", modifiers: [.command])
                
                Divider()
                
                Button("Seek Forward 10s") {
                    playerManager.seek(by: 10)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                
                Button("Seek Backward 10s") {
                    playerManager.seek(by: -10)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
            }
            
            CommandGroup(replacing: .windowList) {
                Button("Toggle Full Screen") {
                    MacOSWindowControls.shared.toggleFullScreen()
                }
                .keyboardShortcut("f", modifiers: [.command])
            }
        }
        #endif
    }
}
