//
//  HeroCarouselView.swift
//  Aura
//
//  Hero Feature Banner with Liquid Glass details overlay.
//

import SwiftUI

public struct HeroCarouselView: View {
    let item: MediaItem
    let onPlayTap: (MediaItem) -> Void
    
    public init(item: MediaItem, onPlayTap: @escaping (MediaItem) -> Void) {
        self.item = item
        self.onPlayTap = onPlayTap
    }
    
    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image / Gradient Placeholder
            GeometryReader { geo in
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.3), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottom
                    )
                    
                    AsyncImage(url: item.backdropURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        default:
                            Color.clear
                        }
                    }
                    
                    // Gradient Fade Overlay
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.1),
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .frame(height: 480)
            
            // Floating Glass Content Card
            VStack(alignment: .leading, spacing: 12) {
                // Badges
                HStack(spacing: 8) {
                    if item.is4K {
                        Text("4K ULTRA HD")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    if item.isHDR {
                        Text("HDR10+")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.yellow.opacity(0.3))
                            .foregroundColor(.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    Text(item.rating)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                
                Text(item.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(item.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
                    .frame(maxWidth: 540, alignment: .leading)
                
                HStack(spacing: 14) {
                    SquircleButton(
                        title: "Play Now",
                        iconName: "play.fill",
                        isPrimary: true
                    ) {
                        onPlayTap(item)
                    }
                    
                    SquircleButton(
                        title: "Watch Trailer",
                        iconName: "film",
                        isPrimary: false
                    ) {}
                }
                .padding(.top, 6)
            }
            .padding(24)
            .liquidGlass(cornerRadius: 24, opacity: 0.8)
            .padding(20)
        }
        .frame(height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal)
    }
}
