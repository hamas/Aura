//
//  CategoriesView.swift
//  Aura
//
//  Categories & Genre Discovery Vault View.
//

import SwiftUI

public struct CategoryCardItem: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let colors: [Color]
    public let genreQuery: String
}

public struct CategoriesView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    var onSelectItem: ((MediaItem) -> Void)? = nil
    
    @State private var selectedCategory: CategoryCardItem? = nil
    @State private var categoryItems: [MediaItem] = []
    @State private var isLoadingItems: Bool = false
    
    private let categories: [CategoryCardItem] = [
        CategoryCardItem(id: "c1", title: "4K Ultra HD", subtitle: "2160p HDR10+ releases", iconName: "4k.tv.fill", colors: [Color.purple, Color.indigo], genreQuery: "4K"),
        CategoryCardItem(id: "c2", title: "Action & Adventure", subtitle: "High octane blockbusters", iconName: "bolt.shield.fill", colors: [Color.orange, Color.red], genreQuery: "Action"),
        CategoryCardItem(id: "c3", title: "Sci-Fi & Cyberpunk", subtitle: "Futuristic worlds & space epics", iconName: "atom", colors: [Color.blue, Color.cyan], genreQuery: "Sci-Fi"),
        CategoryCardItem(id: "c4", title: "Drama & Award Winners", subtitle: "Critically acclaimed cinema", iconName: "star.bubble.fill", colors: [Color.pink, Color.purple], genreQuery: "Drama"),
        CategoryCardItem(id: "c5", title: "Anime & Animation", subtitle: "Top rated series & animated feature films", iconName: "sparkles.tv.fill", colors: [Color.teal, Color.blue], genreQuery: "Animation"),
        CategoryCardItem(id: "c6", title: "Thriller & Mystery", subtitle: "Edge of your seat suspense", iconName: "eye.trianglebadge.exclamationmark.fill", colors: [Color.red, Color.black], genreQuery: "Thriller"),
        CategoryCardItem(id: "c7", title: "Comedy & Standup", subtitle: "Hilarious shows & lighthearted films", iconName: "face.smiling.fill", colors: [Color.yellow, Color.orange], genreQuery: "Comedy"),
        CategoryCardItem(id: "c8", title: "Documentary", subtitle: "Real world stories & nature epics", iconName: "globe.americas.fill", colors: [Color.green, Color.teal], genreQuery: "Documentary")
    ]
    
    public init(onSelectItem: ((MediaItem) -> Void)? = nil) {
        self.onSelectItem = onSelectItem
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if selectedCategory != nil {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = nil
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Categories")
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(Color(red: 255/255, green: 45/255, blue: 85/255))
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Text("Categories & Genres")
                                .font(.title.weight(.bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    
                    Text(selectedCategory != nil ? "Showing titles in \(selectedCategory!.title)" : "Explore curated genre collections, high bitrate 4K releases, and animation vaults.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // MARK: - Category Selected View vs Category Grid
                if let cat = selectedCategory {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 12) {
                            Image(systemName: cat.iconName)
                                .font(.title)
                                .foregroundColor(.white)
                            Text(cat.title)
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 24)
                        
                        if isLoadingItems {
                            LoadingView(title: "Loading \(cat.title) items...", minHeight: 300)
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 165, maximum: 220), spacing: 20)],
                                spacing: 24
                            ) {
                                ForEach(categoryItems) { item in
                                    MediaCardItemView(item: item) {
                                        if let onSelect = onSelectItem {
                                            onSelect(item)
                                        } else {
                                            playerManager.loadMedia(item)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                } else {
                    // Category Cards Grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 20)], spacing: 20) {
                        ForEach(categories) { cat in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedCategory = cat
                                }
                                Task { await loadCategoryData(cat: cat) }
                            }) {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        Image(systemName: cat.iconName)
                                            .font(.title2.weight(.bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(cat.title)
                                            .font(.headline.weight(.bold))
                                            .foregroundColor(.white)
                                        
                                        Text(cat.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                            .lineLimit(1)
                                    }
                                }
                                .padding(20)
                                .frame(height: 130)
                                .background(
                                    LinearGradient(
                                        colors: cat.colors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                                .shadow(color: cat.colors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    private func loadCategoryData(cat: CategoryCardItem) async {
        isLoadingItems = true
        do {
            if cat.genreQuery == "4K" {
                self.categoryItems = try await APIClient.shared.fetch4KCollection()
            } else {
                let allTrending = try await APIClient.shared.fetchTrending()
                let filtered = allTrending.filter { $0.genres.contains(cat.genreQuery) }
                self.categoryItems = filtered.isEmpty ? MediaItem.sampleRailItems : filtered
            }
            self.isLoadingItems = false
        } catch {
            self.categoryItems = MediaItem.sampleRailItems
            self.isLoadingItems = false
        }
    }
}

#Preview("Categories View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        CategoriesView()
            .environmentObject(AVPlayerManager())
    }
    .frame(width: 900, height: 700)
}
