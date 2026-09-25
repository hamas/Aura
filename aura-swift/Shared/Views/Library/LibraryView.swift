//
//  LibraryView.swift
//  Aura
//
//  Library, Watchlist, Continue Watching, and History Grid View.
//

import SwiftUI

public struct LibraryView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @ObservedObject private var bookmarkManager = BookmarkManager.shared
    @State private var selectedFilter: LibraryFilter
    var onSelectItem: ((MediaItem) -> Void)? = nil
    
    public enum LibraryFilter: String, CaseIterable, Identifiable {
        case continueWatching = "Continue Watching"
        case watchlist = "My Watchlist"
        case favorites = "Favorites"
        case history = "History"
        
        public var id: String { rawValue }
    }
    
    public init(initialFilter: LibraryFilter = .continueWatching, onSelectItem: ((MediaItem) -> Void)? = nil) {
        self._selectedFilter = State(initialValue: initialFilter)
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
                
                // Active List Content
                let currentItems = displayItems(for: selectedFilter)
                
                if currentItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: emptyIcon(for: selectedFilter))
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("No items in \(selectedFilter.rawValue)")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Media titles you watch or bookmark will appear here automatically.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .padding(.horizontal, 24)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170, maximum: 200), spacing: 20)], spacing: 24) {
                        ForEach(currentItems) { item in
                            MediaGridCardView(item: item, action: {
                                if let onSelect = onSelectItem {
                                    onSelect(item)
                                } else {
                                    playerManager.loadMedia(item)
                                }
                            }) {
                                if selectedFilter == .continueWatching {
                                    let progress = bookmarkManager.getProgress(item)
                                    VStack {
                                        Spacer()
                                        ProgressView(value: progress > 0 ? progress : 0.45)
                                            .accentColor(Color(red: 255/255, green: 45/255, blue: 85/255))
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
            }
            .padding(.bottom, 40)
        }
    }
    
    private func displayItems(for filter: LibraryFilter) -> [MediaItem] {
        switch filter {
        case .continueWatching:
            return bookmarkManager.watchHistory.isEmpty ? MediaItem.sampleRailItems : bookmarkManager.watchHistory
        case .watchlist:
            return bookmarkManager.watchlist.isEmpty ? Array(MediaItem.sampleRailItems.prefix(3)) : bookmarkManager.watchlist
        case .favorites:
            return bookmarkManager.favorites.isEmpty ? MediaItem.sampleRailItems : bookmarkManager.favorites
        case .history:
            return bookmarkManager.watchHistory.isEmpty ? MediaItem.sampleRailItems : bookmarkManager.watchHistory
        }
    }
    
    private func emptyIcon(for filter: LibraryFilter) -> String {
        switch filter {
        case .continueWatching: return "play.circle"
        case .watchlist: return "bookmark"
        case .favorites: return "heart"
        case .history: return "clock"
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
