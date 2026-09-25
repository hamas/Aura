//
//  MediaRailView.swift
//  Aura
//
//  Horizontal scrolling media rail with liquid glass item cards.
//

import SwiftUI

public struct MediaRailView: View {
    let title: String
    let items: [MediaItem]
    let onItemTap: (MediaItem) -> Void
    
    public init(title: String, items: [MediaItem], onItemTap: @escaping (MediaItem) -> Void) {
        self.title = title
        self.items = items
        self.onItemTap = onItemTap
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All") {}
                    .buttonStyle(PlainButtonStyle())
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        MediaCardItemView(item: item) {
                            onItemTap(item)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

public struct MediaCardItemView: View {
    let item: MediaItem
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(item: MediaItem, action: @escaping () -> Void) {
        self.item = item
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.22), Color(white: 0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 170, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    AsyncImage(url: item.posterURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 170, height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    
                    if item.is4K {
                        Text("4K")
                            .font(.caption2.weight(.black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .padding(8)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isHovered ? Color.white.opacity(0.35) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(isHovered ? 0.35 : 0.15),
                    radius: isHovered ? 14 : 6,
                    x: 0,
                    y: isHovered ? 6 : 3
                )
                .scaleEffect(isHovered ? 1.03 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
                
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isHovered ? .white : .white.opacity(0.9))
                    .lineLimit(1)
                
                Text("\(item.releaseYear) • \(item.subtitle)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 170)
        }
        .buttonStyle(PlainButtonStyle())
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
    }
}

#Preview("Media Rail View") {
    ZStack {
        Color.black.ignoresSafeArea()
        MediaRailView(title: "Trending Movies", items: MediaItem.sampleRailItems) { _ in }
    }
    .frame(width: 800, height: 320)
}
