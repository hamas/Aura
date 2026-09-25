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
                            FilterPillButton(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Grid of Items
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170, maximum: 200), spacing: 20)], spacing: 24) {
                    ForEach(MediaItem.sampleRailItems) { item in
                        MediaGridCardView(item: item, action: {
                            if let onSelect = onSelectItem {
                                onSelect(item)
                            } else {
                                playerManager.loadMedia(item)
                            }
                        }) {
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
