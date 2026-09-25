//
//  MoviesView.swift
//  Aura
//
//  Movies & TV Shows Dedicated Catalog View with mode support and genre filters.
//

import SwiftUI

public enum MoviesViewMode {
    case movies
    case tvShows
}

public struct MoviesView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    public let mode: MoviesViewMode
    @State private var selectedGenre: String = "All Genres"
    @State private var items: [MediaItem] = []
    @State private var popularItems: [MediaItem] = []
    @State private var isLoading: Bool = true
    
    var onSelectItem: ((MediaItem) -> Void)? = nil
    let genres = ["All Genres", "Action", "Sci-Fi", "Drama", "Animation", "Thriller", "Comedy"]
    
    public init(mode: MoviesViewMode = .movies, onSelectItem: ((MediaItem) -> Void)? = nil) {
        self.mode = mode
        self.onSelectItem = onSelectItem
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header & Genre Selector
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: mode == .movies ? "film.fill" : "tv.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                        
                        Text(mode == .movies ? "Movies Catalog" : "TV Series & Shows")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(genres, id: \.self) { genre in
                                FilterPillButton(
                                    title: genre,
                                    isSelected: selectedGenre == genre
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedGenre = genre
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if isLoading {
                    LoadingView(title: mode == .movies ? "Loading Movies..." : "Loading TV Series...", minHeight: 350)
                } else {
                    // Featured Rails
                    MediaRailView(
                        title: mode == .movies ? "Trending Movies" : "Trending TV Series",
                        items: filteredItems(items)
                    ) { item in
                        if let onSelect = onSelectItem {
                            onSelect(item)
                        } else {
                            playerManager.loadMedia(item)
                        }
                    }
                    
                    MediaRailView(
                        title: mode == .movies ? "Top Popular Releases" : "Popular Bingeable Shows",
                        items: filteredItems(popularItems)
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
            await loadCatalog()
        }
    }
    
    private func filteredItems(_ rawItems: [MediaItem]) -> [MediaItem] {
        if selectedGenre == "All Genres" {
            return rawItems.isEmpty ? MediaItem.sampleRailItems : rawItems
        }
        let filtered = rawItems.filter { $0.genres.contains(selectedGenre) }
        return filtered.isEmpty ? rawItems : filtered
    }
    
    private func loadCatalog() async {
        isLoading = true
        do {
            if mode == .movies {
                async let fetchedTrending = APIClient.shared.fetchTrendingMovies()
                async let fetchedPopular = APIClient.shared.fetchPopularMovies()
                self.items = try await fetchedTrending
                self.popularItems = try await fetchedPopular
            } else {
                async let fetchedTrendingSeries = APIClient.shared.fetchTrendingSeries()
                async let fetchedPopularSeries = APIClient.shared.fetchPopularSeries()
                self.items = try await fetchedTrendingSeries
                self.popularItems = try await fetchedPopularSeries
            }
            self.isLoading = false
        } catch {
            self.isLoading = false
        }
    }
}

#Preview("Movies View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        MoviesView(mode: .tvShows)
            .environmentObject(AVPlayerManager())
    }
    .frame(width: 900, height: 600)
}
