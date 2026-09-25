//
//  FavoritesView.swift
//  Aura
//
//  User Bookmarked & Favorite Titles View.
//

import SwiftUI

public struct FavoritesView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    var onSelectItem: ((MediaItem) -> Void)? = nil
    
    public init(onSelectItem: ((MediaItem) -> Void)? = nil) {
        self.onSelectItem = onSelectItem
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(.red.opacity(0.9))
                        
                        Text("My Favorites")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Your saved movies, shows, and bookmarked releases across all connected accounts.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170, maximum: 200), spacing: 20)], spacing: 24) {
                    ForEach(MediaItem.sampleRailItems) { item in
                        MediaGridCardView(item: item, action: {
                            if let onSelect = onSelectItem {
                                onSelect(item)
                            } else {
                                playerManager.loadMedia(item)
                            }
                        }) {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red.opacity(0.9))
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .padding(8)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview("Favorites View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        FavoritesView()
            .environmentObject(AVPlayerManager())
    }
    .frame(width: 900, height: 600)
}
