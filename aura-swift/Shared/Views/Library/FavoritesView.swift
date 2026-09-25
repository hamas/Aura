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
                        Button(action: {
                            if let onSelect = onSelectItem {
                                onSelect(item)
                            } else {
                                playerManager.loadMedia(item)
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    AsyncImage(url: item.posterURL) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 240)
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color(white: 0.15))
                                                .frame(height: 240)
                                        }
                                    }
                                    
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red.opacity(0.9))
                                        .padding(8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .padding(8)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                                
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
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
