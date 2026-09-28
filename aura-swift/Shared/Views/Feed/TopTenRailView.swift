//
//  TopTenRailView.swift
//  Aura
//
//  Netflix-style Top 10 ranked content rail with giant metallic typography glyphs.
//

import SwiftUI

public struct TopTenRailView: View {
    public let title: String
    public let items: [MediaItem]
    public var onSelect: (MediaItem) -> Void
    public var onPlay: ((MediaItem) -> Void)? = nil
    
    public init(
        title: String = "Top 10 Worldwide Today",
        items: [MediaItem],
        onSelect: @escaping (MediaItem) -> Void,
        onPlay: ((MediaItem) -> Void)? = nil
    ) {
        self.title = title
        self.items = items
        self.onSelect = onSelect
        self.onPlay = onPlay
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                Text("TOP 10")
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                Spacer()
            }
            .padding(.horizontal, 28)
            
            // Horizontal Numbered Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(items.prefix(10).enumerated()), id: \.element.id) { index, item in
                        TopTenRankCard(
                            rank: index + 1,
                            item: item,
                            onSelect: { onSelect(item) },
                            onPlay: onPlay != nil ? { onPlay!(item) } : nil
                        )
                    }
                }
                .padding(.horizontal, 28)
            }
        }
    }
}

public struct TopTenRankCard: View {
    public let rank: Int
    public let item: MediaItem
    public let onSelect: () -> Void
    public var onPlay: (() -> Void)? = nil
    
    @State private var isHovered: Bool = false
    
    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: -24) {
                // Giant Metallic Outline Rank Number
                ZStack {
                    // Shadow / Border Stroke
                    Text("\(rank)")
                        .font(.system(size: 130, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .offset(x: 2, y: 2)
                    
                    // Metallic Gradient Text
                    Text("\(rank)")
                        .font(.system(size: 130, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.8, green: 0.8, blue: 0.85),
                                    Color(red: 0.35, green: 0.35, blue: 0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(width: rank == 1 ? 75 : 95, alignment: .trailing)
                .zIndex(0)
                
                // Poster Card
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: item.highDefPosterURL ?? item.posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            ZStack {
                                Color(red: 0.12, green: 0.12, blue: 0.15)
                                Image(systemName: "film")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(width: 140, height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isHovered ? Color.white.opacity(0.6) : Color.white.opacity(0.12), lineWidth: 1.5)
                    )
                    
                    // Red Top 10 Corner Tag
                    Text("TOP\n10")
                        .font(.system(size: 8, weight: .black))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(6)
                }
                .shadow(color: Color.black.opacity(isHovered ? 0.6 : 0.35), radius: isHovered ? 14 : 8, x: 0, y: isHovered ? 6 : 3)
                .scaleEffect(isHovered ? 1.08 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isHovered)
                .zIndex(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
