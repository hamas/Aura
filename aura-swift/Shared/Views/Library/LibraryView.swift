//
//  LibraryView.swift
//  Aura
//
//  Library, Watchlist, Continue Watching, and Favorites Grid View.
//

import SwiftUI

public struct LibraryView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @State private var selectedFilter: LibraryFilter = .continueWatching
    var onSelectItem: ((MediaItem) -> Void)? = nil
    
    public enum LibraryFilter: String, CaseIterable, Identifiable {
        case continueWatching = "Continue Watching"
        case watchlist = "My Watchlist"
        case favorites = "Favorites"
        case history = "History"
        
        public var id: String { rawValue }
    }
    
    public init(onSelectItem: ((MediaItem) -> Void)? = nil) {
        self.onSelectItem = onSelectItem
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header & Filter Pills
                VStack(alignment: .leading, spacing: 12) {
                    Text("Media Library")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 10) {
                        ForEach(LibraryFilter.allCases) { filter in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }) {
                                Text(filter.rawValue)
                                    .font(.callout.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Group {
                                            if selectedFilter == filter {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(Color.white.opacity(0.20))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                                    )
                                            } else {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(.ultraThinMaterial)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    )
                                    .foregroundColor(selectedFilter == filter ? .white : .secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Grid of Items
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
                                ZStack(alignment: .bottomLeading) {
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
                                    
                                    // Continue Watching Progress Bar Overlay
                                    if selectedFilter == .continueWatching {
                                        VStack {
                                            Spacer()
                                            ProgressView(value: 0.65)
                                                .accentColor(.white)
                                                .padding(8)
                                                .background(.ultraThinMaterial)
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                                .padding(8)
                                        }
                                    }
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

#Preview("Library View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        LibraryView()
            .environmentObject(AVPlayerManager())
    }
}
