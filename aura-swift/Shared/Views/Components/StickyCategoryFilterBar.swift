//
//  StickyCategoryFilterBar.swift
//  Aura
//
//  Glassmorphic pinned header filter for Movies, TV Shows, and Categories.
//

import SwiftUI

public enum MediaCategoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case tvShows = "TV Shows"
    case movies = "Movies"
    case anime = "Anime"
    case documentary = "Documentaries"
    
    public var id: String { rawValue }
}

public struct StickyCategoryFilterBar: View {
    @Binding public var selectedFilter: MediaCategoryFilter
    public var onSelectGenre: ((String) -> Void)? = nil
    
    public init(selectedFilter: Binding<MediaCategoryFilter>, onSelectGenre: ((String) -> Void)? = nil) {
        self._selectedFilter = selectedFilter
        self.onSelectGenre = onSelectGenre
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            ForEach(MediaCategoryFilter.allCases) { filter in
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selectedFilter = filter
                    }
                }) {
                    Text(filter.rawValue)
                        .font(.system(size: 13, weight: selectedFilter == filter ? .bold : .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedFilter == filter
                                ? Color.white
                                : Color.white.opacity(0.1)
                        )
                        .foregroundColor(selectedFilter == filter ? .black : .white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(selectedFilter == filter ? 0.0 : 0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
        .background(
            Color.black.opacity(0.7)
        )
    }
}
