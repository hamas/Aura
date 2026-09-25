//
//  MoviesView.swift
//  Aura
//
//  Movies & TV Shows Dedicated Catalog View with genre filters and media rails.
//

import SwiftUI

public struct MoviesView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @State private var selectedGenre: String = "All Genres"
    @State private var movies: [MediaItem] = []
    @State private var series: [MediaItem] = []
    @State private var isLoading: Bool = true
    
    var onSelectItem: ((MediaItem) -> Void)? = nil
    let genres = ["All Genres", "Action", "Sci-Fi", "Drama", "Animation", "Thriller", "Comedy"]
    
    public init(onSelectItem: ((MediaItem) -> Void)? = nil) {
        self.onSelectItem = onSelectItem
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header & Genre Selector
                VStack(alignment: .leading, spacing: 14) {
                    Text("Movies & TV Shows")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    
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
                    LoadingView()
                } else {
                    // Featured Rails
                    MediaRailView(
                        title: "Trending Blockbusters",
                        items: filteredItems(movies)
                    ) { item in
                        if let onSelect = onSelectItem {
                            onSelect(item)
                        } else {
                            playerManager.loadMedia(item)
                        }
                    }
                    
                    MediaRailView(
                        title: "Top Rated Series",
                        items: filteredItems(series)
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
    
    private func filteredItems(_ items: [MediaItem]) -> [MediaItem] {
        if selectedGenre == "All Genres" {
            return items.isEmpty ? MediaItem.sampleRailItems : items
        }
        let filtered = items.filter { $0.genres.contains(selectedGenre) }
        return filtered.isEmpty ? items : filtered
    }
    
    private func loadCatalog() async {
        isLoading = true
        do {
            async let fetchedMovies = APIClient.shared.fetchTrendingMovies()
            async let fetchedSeries = APIClient.shared.fetchTrendingSeries()
            
            self.movies = try await fetchedMovies
            self.series = try await fetchedSeries
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
        MoviesView()
            .environmentObject(AVPlayerManager())
    }
    .frame(width: 900, height: 600)
}
