//
//  MainFeedView.swift
//  Aura
//
//  Root catalog feed view presenting liquid glass architecture & video player overlay.
//

import SwiftUI

public struct MainFeedView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @State private var searchText: String = ""
    @State private var selectedMedia: MediaItem? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Deep Ambient Dark Background
            Color.black.ignoresSafeArea()
            
            // Dynamic Background Glow Spheres
            GeometryReader { geo in
                Circle()
                    .fill(Color.purple.opacity(0.18))
                    .blur(radius: 90)
                    .frame(width: 400, height: 400)
                    .position(x: 100, y: 100)
                
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .blur(radius: 110)
                    .frame(width: 500, height: 500)
                    .position(x: geo.size.width - 100, y: 350)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Floating Navigation Bar
                CustomToolbar(searchText: $searchText) {
                    // Profile callback
                }
                .padding(.top, 10)
                
                // Catalog Scroll View
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        HeroCarouselView(item: MediaItem.sampleHero) { selected in
                            playerManager.loadMedia(selected)
                        }
                        .padding(.top, 14)
                        
                        MediaRailView(
                            title: "Trending Movies & Shows",
                            items: MediaItem.sampleRailItems
                        ) { selected in
                            playerManager.loadMedia(selected)
                        }
                        
                        MediaRailView(
                            title: "Recently Added in 4K HDR",
                            items: MediaItem.sampleRailItems.reversed()
                        ) { selected in
                            playerManager.loadMedia(selected)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
            
            // Full-Screen AVPlayer Overlay when media is loaded
            if playerManager.currentItem != nil {
                VideoPlayerView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
    }
}
