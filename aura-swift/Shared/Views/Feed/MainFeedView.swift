//
//  MainFeedView.swift
//  Aura
//
//  Root catalog feed view presenting liquid glass architecture & video player overlay.
//

import SwiftUI

public struct MainFeedView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    #if os(macOS)
    @State private var selectedSidebarSection: SidebarSection? = .home
    #endif
    @State private var searchText: String = ""
    @State private var heroItem: MediaItem = MediaItem.sampleHero
    @State private var trendingItems: [MediaItem] = []
    @State private var popularMovies: [MediaItem] = []
    @State private var gridMovies: [MediaItem] = []
    @State private var searchResults: [MediaItem] = []
    @State private var selectedDetailsItem: MediaItem? = nil
    @State private var currentPage: Int = 1
    @State private var isLoading: Bool = true
    @State private var isLoadingMore: Bool = false
    @State private var isError: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Neutral Deep Ambient Background (#0D0E12)
            Color(red: 13/255, green: 14/255, blue: 18/255)
                .ignoresSafeArea()
            
            #if os(macOS)
            WindowAccessor()
            
            NavigationSplitView {
                MacOSSidebarView(
                    selectedSection: $selectedSidebarSection,
                    searchText: $searchText
                )
            } detail: {
                ZStack(alignment: .topTrailing) {
                    detailContentView
                        .ignoresSafeArea(.all, edges: .top)
                    
                    // Floating Mute Action Button in Top-Right Corner (Apple TV Style)
                    Button(action: {}) {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(9)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                    .zIndex(5)
                }
            }
            .navigationSplitViewStyle(.balanced)
            #else
            VStack(spacing: 0) {
                CustomToolbar(searchText: $searchText) {}
                    .padding(.top, 10)
                
                mainContentFeed
            }
            #endif
            
            // Single Page Media Details Overlay
            if let detailsItem = selectedDetailsItem {
                MediaDetailsView(
                    item: detailsItem,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedDetailsItem = nil
                        }
                    },
                    onPlayStream: { stream in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedDetailsItem = nil
                            playerManager.loadStream(item: detailsItem, option: stream)
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(9)
            }
            
            // Full-Screen AVPlayer Overlay when media is loaded
            if playerManager.currentItem != nil {
                VideoPlayerView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
    }
    
    @ViewBuilder
    private var detailContentView: some View {
        #if os(macOS)
        switch selectedSidebarSection ?? .home {
        case .search:
            searchResultsFeed
        case .home:
            mainContentFeed
        case .movies, .tvShows:
            MoviesView(onSelectItem: { item in
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedDetailsItem = item
                }
            })
        case .categories:
            UltraHDView(onSelectItem: { item in
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedDetailsItem = item
                }
            })
        case .wishlist:
            FavoritesView(onSelectItem: { item in
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedDetailsItem = item
                }
            })
        case .downloads:
            DownloadsView()
        case .watchlist, .history:
            LibraryView(onSelectItem: { item in
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedDetailsItem = item
                }
            })
        case .settings:
            SettingsView()
        }
        #else
        mainContentFeed
        #endif
    }
    
    // Main Content Scroll View Feed with Live Data
    private var mainContentFeed: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .accentColor(.white)
                        Text("Loading Live Catalog...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 350)
                    .frame(maxWidth: .infinity)
                } else if isError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                        Text("Unable to connect to Catalog API")
                            .font(.headline)
                            .foregroundColor(.white)
                        Button("Retry Connection") {
                            Task { await loadLiveData() }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .frame(height: 350)
                    .frame(maxWidth: .infinity)
                } else {
                    // Auto-scrolling Hero Carousel Banner without top margin
                    HeroCarouselView(items: trendingItems.isEmpty ? [heroItem] : trendingItems) { selected in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedDetailsItem = selected
                        }
                    }
                    
                    MediaRailView(
                        title: "Trending Movies & Shows",
                        items: trendingItems.isEmpty ? MediaItem.sampleRailItems : trendingItems
                    ) { selected in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedDetailsItem = selected
                        }
                    }
                    
                    MediaRailView(
                        title: "Popular Releases in 4K HDR",
                        items: popularMovies.isEmpty ? MediaItem.sampleRailItems.reversed() : popularMovies
                    ) { selected in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedDetailsItem = selected
                        }
                    }
                    
                    // Infinite Grid of Movies
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("Explore All Movies & Shows")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 165, maximum: 220), spacing: 20)],
                            spacing: 24
                        ) {
                            ForEach(gridMovies) { movie in
                                MediaCardItemView(item: movie) {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        selectedDetailsItem = movie
                                    }
                                }
                                .onAppear {
                                    if movie.id == gridMovies.last?.id {
                                        Task { await loadMoreMovies() }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        if isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(1.1)
                                    .padding(.vertical, 20)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.bottom, 60)
        }
        .ignoresSafeArea(.all, edges: .top)
        .task {
            await loadLiveData()
        }
        .onChange(of: searchText) { _, newQuery in
            Task {
                if !newQuery.isEmpty {
                    #if os(macOS)
                    selectedSidebarSection = .search
                    #endif
                    searchResults = (try? await APIClient.shared.search(query: newQuery)) ?? []
                }
            }
        }
    }
    
    private var searchResultsFeed: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Search Results for '\(searchText)'")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                
                if searchResults.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No titles matching '\(searchText)'")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    MediaRailView(
                        title: "Results",
                        items: searchResults
                    ) { selected in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedDetailsItem = selected
                        }
                    }
                }
            }
            .padding(.bottom, 60)
        }
    }
    
    private func loadLiveData() async {
        isLoading = true
        isError = false
        do {
            async let hero = APIClient.shared.fetchHeroItem()
            async let trending = APIClient.shared.fetchTrending()
            async let popular = APIClient.shared.fetchPopularMovies()
            async let initialGrid = APIClient.shared.fetchInfiniteMovies(page: 1)
            
            self.heroItem = try await hero
            self.trendingItems = try await trending
            self.popularMovies = try await popular
            self.gridMovies = try await initialGrid
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.isError = true
        }
    }
    
    private func loadMoreMovies() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        do {
            let nextPage = currentPage + 1
            let newMovies = try await APIClient.shared.fetchInfiniteMovies(page: nextPage)
            self.gridMovies.append(contentsOf: newMovies)
            self.currentPage = nextPage
        } catch {}
        self.isLoadingMore = false
    }
}

#Preview("Main Feed View") {
    MainFeedView()
        .environmentObject(AVPlayerManager())
        .preferredColorScheme(.dark)
        .frame(width: 1000, height: 700)
}
