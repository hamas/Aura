//
//  SearchView.swift
//  Aura
//
//  Dedicated Search & Discovery View with Instant API Search & Quick Filter Pills.
//

import SwiftUI

public struct SearchView: View {
    @Binding public var searchText: String
    var onSelectItem: ((MediaItem) -> Void)? = nil
    
    @State private var searchResults: [MediaItem] = []
    @State private var selectedSearchType: SearchType = .all
    @State private var isLoading: Bool = false
    @State private var isSearching: Bool = false
    
    private let popularSearchTags = [
        "Dune: Part Two", "Cyberpunk", "Oppenheimer", "Arcane", "4K HDR", "Anime", "Action Movies", "Sci-Fi Series"
    ]
    
    public enum SearchType: String, CaseIterable, Identifiable {
        case all = "All Titles"
        case movies = "Movies Only"
        case series = "TV Shows Only"
        
        public var id: String { rawValue }
    }
    
    public init(searchText: Binding<String>, onSelectItem: ((MediaItem) -> Void)? = nil) {
        self._searchText = searchText
        self.onSelectItem = onSelectItem
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Search Input Bar & Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Search & Discovery")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    
                    // Search Bar Field
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                        
                        TextField("Search movies, TV shows, actors, or genres...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .onSubmit {
                                Task { await performSearch() }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults.removeAll()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    
                    // Popular Search Tag Chips
                    VStack(alignment: .leading, spacing: 10) {
                        Text("POPULAR SEARCHES")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(popularSearchTags, id: \.self) { tag in
                                    Button(action: {
                                        searchText = tag
                                        Task { await performSearch() }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "sparkles")
                                                .font(.caption2)
                                                .foregroundColor(Color(red: 255/255, green: 45/255, blue: 85/255))
                                            Text(tag)
                                                .font(.caption.weight(.medium))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.08))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                    
                    // Type Filter Pills
                    if !searchText.isEmpty {
                        HStack(spacing: 10) {
                            ForEach(SearchType.allCases) { type in
                                FilterPillButton(
                                    title: type.rawValue,
                                    isSelected: selectedSearchType == type
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedSearchType = type
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // MARK: - Results Grid or Initial Suggestion View
                if isLoading {
                    LoadingView(title: "Searching catalog...", minHeight: 300)
                } else if searchText.isEmpty {
                    // Initial State / Suggested Titles
                    VStack(alignment: .leading, spacing: 16) {
                        Text("RECOMMENDED DISCOVERIES")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                        
                        MediaRailView(
                            title: "Trending Movies",
                            items: MediaItem.sampleRailItems
                        ) { item in
                            onSelectItem?(item)
                        }
                    }
                } else if filteredResults.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No titles found for '\(searchText)'")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Try checking spelling or search for popular genres like Sci-Fi or Action.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .padding(.horizontal, 24)
                } else {
                    // Results Grid
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Found \(filteredResults.count) titles for '\(searchText)'")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                        
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 165, maximum: 220), spacing: 20)],
                            spacing: 24
                        ) {
                            ForEach(filteredResults) { item in
                                MediaCardItemView(item: item) {
                                    onSelectItem?(item)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .onChange(of: searchText) { _, newQuery in
            Task {
                await performSearch()
            }
        }
    }
    
    private var filteredResults: [MediaItem] {
        switch selectedSearchType {
        case .all:
            return searchResults
        case .movies:
            return searchResults.filter { !$0.subtitle.lowercased().contains("series") && !$0.subtitle.lowercased().contains("season") }
        case .series:
            return searchResults.filter { $0.subtitle.lowercased().contains("series") || $0.subtitle.lowercased().contains("season") }
        }
    }
    
    private func performSearch() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults.removeAll()
            return
        }
        
        isLoading = true
        do {
            let items = try await APIClient.shared.search(query: searchText)
            withAnimation(.easeInOut(duration: 0.2)) {
                self.searchResults = items
                self.isLoading = false
            }
        } catch {
            self.isLoading = false
        }
    }
}

#Preview("Search View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        SearchView(searchText: .constant("Dune"))
    }
    .frame(width: 900, height: 700)
}
