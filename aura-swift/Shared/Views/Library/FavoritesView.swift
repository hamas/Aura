//
//  FavoritesView.swift
//  Aura
//
//  User Bookmarked & Favorite Titles View with Live Persistence.
//

import SwiftUI

public struct FavoritesView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @ObservedObject private var bookmarkManager = BookmarkManager.shared
    var onSelectItem: ((MediaItem) -> Void)? = nil
    
    public init(onSelectItem: ((MediaItem) -> Void)? = nil) {
        self.onSelectItem = onSelectItem
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
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
                
                // Content Grid
                if bookmarkManager.favorites.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No Favorite Titles Saved")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Tap the heart icon on any movie or series to bookmark it here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .padding(.horizontal, 24)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170, maximum: 200), spacing: 20)], spacing: 24) {
                        ForEach(bookmarkManager.favorites) { item in
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
                                        Button(action: {
                                            bookmarkManager.toggleFavorite(item)
                                        }) {
                                            Image(systemName: "heart.fill")
                                                .foregroundColor(.red.opacity(0.9))
                                                .padding(8)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Circle())
                                                .padding(8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
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
