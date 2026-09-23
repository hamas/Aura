//
//  MacOSWindowControls.swift
//  Aura (macOS target override)
//
//  Window behavior, transparent titlebar styling, and full-screen toggle for macOS target.
//

import Foundation
#if os(macOS)
import AppKit

public final class MacOSWindowControls {
    public static let shared = MacOSWindowControls()
    
    private init() {}
    
    public func configureTransparentWindow() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true
                window.backgroundColor = .clear
            }
        }
    }
    
    public func toggleFullScreen() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.toggleFullScreen(nil)
            }
        }
    }
}
#endif
