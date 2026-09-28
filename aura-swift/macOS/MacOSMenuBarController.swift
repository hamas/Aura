//
//  MacOSMenuBarController.swift
//  Aura (macOS)
//
//  Created for Aura Media Suite on 2026-09-28.
//  Status Bar Menu Item & Mini Popover Controller for background playback controls and quick actions.
//

import SwiftUI

#if os(macOS)
import AppKit

@MainActor
public final class MacOSMenuBarController: NSObject {
    public static let shared = MacOSMenuBarController()
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    private override init() {
        super.init()
    }
    
    public func setupMenuBar() {
        guard statusItem == nil else { return }
        
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "play.tv.fill", accessibilityDescription: "Aura Media")
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        self.statusItem = item
        
        let popoverInstance = NSPopover()
        popoverInstance.contentSize = NSSize(width: 300, height: 320)
        popoverInstance.behavior = .transient
        popoverInstance.contentViewController = NSHostingController(rootView: MacOSMenuBarPopoverView())
        self.popover = popoverInstance
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let popover = popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

// MARK: - Menu Bar Popover SwiftUI View

public struct MacOSMenuBarPopoverView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles.tv.fill")
                    .foregroundColor(.red)
                Text("Aura Quick Hub")
                    .font(.headline)
                Spacer()
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                }) {
                    Image(systemName: "arrow.up.forward.app")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("NOW PLAYING")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "film.fill")
                        .foregroundColor(.red)
                    Text("Aura Media Player")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
            
            Spacer()
            
            Divider()
            
            HStack {
                Button("Open Aura") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                
                Spacer()
                
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 6)
        }
        .padding(12)
        .frame(width: 300, height: 260)
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
    }
}
#endif
