//
//  MacOSKeyboardShortcutManager.swift
//  Aura (macOS target)
//
//  Global Netflix-grade keyboard navigation and hotkey event handler for macOS.
//

#if os(macOS)
import SwiftUI
import AppKit

public struct MacOSKeyboardShortcutModifier: ViewModifier {
    @EnvironmentObject private var playerManager: AVPlayerManager
    
    public func body(content: Content) -> some View {
        content
            // Play / Pause Toggle (Space / K)
            .keyboardShortcut(.space, modifiers: [])
            // Fullscreen Toggle (F)
            .background(
                Button("") {
                    playerManager.togglePlayPause()
                }
                .keyboardShortcut("k", modifiers: [])
                .opacity(0)
            )
            .background(
                Button("") {
                    playerManager.isFullScreen.toggle()
                }
                .keyboardShortcut("f", modifiers: [])
                .opacity(0)
            )
            // Mute / Unmute Toggle (M)
            .background(
                Button("") {
                    playerManager.toggleMute()
                }
                .keyboardShortcut("m", modifiers: [])
                .opacity(0)
            )
            // Skip Intro / Skip Recap (S)
            .background(
                Button("") {
                    playerManager.skipCurrentInterval()
                }
                .keyboardShortcut("s", modifiers: [])
                .opacity(0)
            )
            // Next Episode (N)
            .background(
                Button("") {
                    playerManager.triggerNextEpisode()
                }
                .keyboardShortcut("n", modifiers: [])
                .opacity(0)
            )
            // Seek Backward 10s (Left Arrow)
            .background(
                Button("") {
                    playerManager.seekWithFeedback(delta: -10)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .opacity(0)
            )
            // Seek Forward 10s (Right Arrow)
            .background(
                Button("") {
                    playerManager.seekWithFeedback(delta: 10)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .opacity(0)
            )
            // Subtitles Toggle (C)
            .background(
                Button("") {
                    playerManager.showSubtitleModal.toggle()
                }
                .keyboardShortcut("c", modifiers: [])
                .opacity(0)
            )
            // Dismiss Modals / Exit (Escape)
            .background(
                Button("") {
                    if playerManager.showEpisodeDrawer {
                        playerManager.showEpisodeDrawer = false
                    } else if playerManager.showSubtitleModal {
                        playerManager.showSubtitleModal = false
                    } else if playerManager.showNextEpisodeCountdown {
                        playerManager.dismissNextEpisodeCountdown()
                    }
                }
                .keyboardShortcut(.escape, modifiers: [])
                .opacity(0)
            )
    }
}

extension View {
    public func enableNetflixKeyboardShortcuts() -> some View {
        self.modifier(MacOSKeyboardShortcutModifier())
    }
}
#else
import SwiftUI

extension View {
    public func enableNetflixKeyboardShortcuts() -> some View {
        self
    }
}
#endif
