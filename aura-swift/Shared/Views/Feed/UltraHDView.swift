//
//  UltraHDView.swift
//  Aura
//
//  4K HDR10+ and Dolby Vision Showcase Catalog View.
//

import SwiftUI

public struct UltraHDView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @State private var ultraHDItems: [MediaItem] = []
    @State private var isLoading: Bool = true
    
    var onSelectItem: ((MediaItem) -> Void)? = nil
    
    public init(onSelectItem: ((MediaItem) -> Void)? = nil) {
        self.onSelectItem = onSelectItem
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header Banner
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text("4K ULTRA HD")
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .foregroundColor(.white)
                        
                        Text("DOLBY VISION")
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .foregroundColor(.yellow)
                    }
                    
                    Text("4K HDR Vault")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    
                    Text("High bitrate 2160p content master releases with wide color gamut and spatial audio.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if isLoading {
                    LoadingView()
                } else {
                    // 4K Rails
                    MediaRailView(
                        title: "Recently Mastered in 4K HDR",
                        items: ultraHDItems.isEmpty ? MediaItem.sampleRailItems : ultraHDItems
                    ) { item in
                        if let onSelect = onSelectItem {
                            onSelect(item)
                        } else {
                            playerManager.loadMedia(item)
                        }
                    }
                    
                    MediaRailView(
                        title: "Dolby Atmos & Vision Showcase",
                        items: ultraHDItems.isEmpty ? MediaItem.sampleRailItems.reversed() : ultraHDItems.reversed()
                    ) { item in
                        if let onSelect = onSelectItem {
                            onSelect(item)
                        } else {
                            playerManager.loadMedia(item)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .task {
            await load4KCatalog()
        }
    }
    
    private func load4KCatalog() async {
        isLoading = true
        do {
            self.ultraHDItems = try await APIClient.shared.fetch4KCollection()
            self.isLoading = false
        } catch {
            self.isLoading = false
        }
    }
}

#Preview("Ultra HD View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        UltraHDView()
            .environmentObject(AVPlayerManager())
    }
    .frame(width: 900, height: 600)
}
