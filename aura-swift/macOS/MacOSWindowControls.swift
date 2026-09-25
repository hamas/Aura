//
//  MacOSWindowControls.swift
//  Aura (macOS target override)
//
//  Window behavior, transparent titlebar styling, visual effects, and full-screen toggle for macOS target.
//

import Foundation
#if os(macOS)
import AppKit
import SwiftUI

public final class MacOSWindowControls {
    public static let shared = MacOSWindowControls()
    
    private init() {}
    
    private var activeWindow: NSWindow? {
        NSApplication.shared.keyWindow
            ?? NSApplication.shared.mainWindow
            ?? NSApplication.shared.windows.first(where: { $0.isVisible })
    }
    
    public func configureTransparentWindow() {
        DispatchQueue.main.async { [weak self] in
            if let window = self?.activeWindow {
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = true
            }
        }
    }
    
    public func toggleFullScreen() {
        DispatchQueue.main.async { [weak self] in
            if let window = self?.activeWindow {
                window.toggleFullScreen(nil)
            }
        }
    }
}

/// Helper NSViewRepresentable to transparently hook into NSWindow on appearance.
public struct WindowAccessor: NSViewRepresentable {
    public init() {}
    
    public class Coordinator {
        var isConfigured = false
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window, !context.coordinator.isConfigured else { return }
            context.coordinator.isConfigured = true
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
        }
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Native macOS Visual Effect View Blur (Vibrancy)
public struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    public init(
        material: NSVisualEffectView.Material = .fullScreenUI,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.material = material
        effectView.blendingMode = blendingMode
        effectView.state = .active
        return effectView
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
#endif

