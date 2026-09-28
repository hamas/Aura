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
    @StateObject private var dataStore = AuraDataStore.shared
    @StateObject private var traktService = TraktScrobblerService.shared
    @StateObject private var vaultManager = OfflineVaultManager.shared
    
    init() {
        AudioSessionManager.shared.configurePlaybackSession()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                #if os(iOS)
                iPadAdaptiveNavigationView()
                #else
                MainFeedView()
                #endif
            }
            .environmentObject(playerManager)
            .environmentObject(dataStore)
            .environmentObject(traktService)
            .environmentObject(vaultManager)
            .preferredColorScheme(.dark)
            .onAppear {
                #if os(macOS)
                MacOSNowPlayingManager.shared.configureRemoteCommands(playerManager: playerManager)
                #endif
            }
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
                
                Button("Skip Intro / Recap") {
                    playerManager.skipCurrentInterval()
                }
                .keyboardShortcut("s", modifiers: [])
                
                Button("Next Episode") {
                    playerManager.triggerNextEpisode()
                }
                .keyboardShortcut("n", modifiers: [])
                
                Button("Toggle Mute") {
                    playerManager.toggleMute()
                }
                .keyboardShortcut("m", modifiers: [.command])
                
                Divider()
                
                Button("Seek Forward 10s") {
                    playerManager.seekWithFeedback(delta: 10)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                
                Button("Seek Backward 10s") {
                    playerManager.seekWithFeedback(delta: -10)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
                
                Divider()
                
                Button("Toggle Dialogue Boost") {
                    playerManager.toggleDialogueBoost()
                }
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
