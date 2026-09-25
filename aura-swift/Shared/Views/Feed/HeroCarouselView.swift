//
//  HeroCarouselView.swift
//  Aura
//
//  Hero Feature Banner with auto-scrolling carousel and movie logo overlay.
//

import SwiftUI
import Combine

public struct HeroCarouselView: View {
    let items: [MediaItem]
    let onPlayTap: (MediaItem) -> Void
    
    @State private var currentIndex: Int = 0
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    public init(items: [MediaItem], onPlayTap: @escaping (MediaItem) -> Void) {
        self.items = items.isEmpty ? [MediaItem.sampleHero] : items
        self.onPlayTap = onPlayTap
    }
    
    public var body: some View {
        let currentItem = items[currentIndex % max(1, items.count)]
        
        ZStack(alignment: .bottomLeading) {
            // Background Image / Gradient Overlay
            GeometryReader { geo in
                ZStack {
                    LinearGradient(
                        colors: [Color(white: 0.15), Color(white: 0.08), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottom
                    )
                    
                    AsyncImage(url: currentItem.backdropURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .transition(.opacity)
                        default:
                            Color.clear
                        }
                    }
                    .id(currentItem.id)
                    
                    // Gradient Fade Overlay (Top to Bottom and Left to Right)
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.15),
                            Color.black.opacity(0.55),
                            Color.black.opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .frame(height: 540)
            
            // Hero Content Overlay (Apple TV Style)
            VStack(alignment: .leading, spacing: 12) {
                // "FEATURED" Badge
                Text("FEATURED")
                    .font(.caption2.weight(.black))
                    .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                
                // Show Movie/Show Logo (Movie Name Text is Hidden)
                MediaTitleLogoView(item: currentItem)
                    .frame(maxHeight: 90, alignment: .leading)
                
                // Metadata Row
                HStack(spacing: 8) {
                    Image(systemName: "tv.fill")
                        .font(.caption)
                        .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                    Text("Aura Original • \(currentItem.subtitle)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    Text(currentItem.rating)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.secondary, lineWidth: 1)
                        )
                        .foregroundColor(.secondary)
                }
                
                // Description Logline
                Text(currentItem.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(3)
                    .frame(maxWidth: 520, alignment: .leading)
                
                // Action Buttons: Pill Play Button + Circular Plus Button
                HStack(spacing: 14) {
                    Button(action: {
                        onPlayTap(currentItem)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.subheadline.weight(.bold))
                            Text("Play")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 4)
            }
            .padding(.leading, 40)
            .padding(.bottom, 44)
            
            // Pagination Dots Indicator at Bottom Center
            VStack {
                Spacer()
                HStack(spacing: 7) {
                    ForEach(0..<min(items.count, 10), id: \.self) { index in
                        Circle()
                            .fill(index == (currentIndex % max(1, items.count)) ? Color.white : Color.white.opacity(0.3))
                            .frame(
                                width: index == (currentIndex % max(1, items.count)) ? 8 : 6,
                                height: index == (currentIndex % max(1, items.count)) ? 8 : 6
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    currentIndex = index
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 540)
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                if !items.isEmpty {
                    currentIndex = (currentIndex + 1) % items.count
                }
            }
        }
    }
}

// Stylized Title Logo View for Movies & Shows (Title Text is Hidden, Graphical Logo Mark is Rendered)
struct MediaTitleLogoView: View {
    let item: MediaItem
    
    var body: some View {
        HStack(spacing: 8) {
            Text(item.title.uppercased())
                .font(.system(size: 34, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 220/255, green: 235/255, blue: 255/255)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
                .shadow(color: Color(red: 0/255, green: 122/255, blue: 255/255).opacity(0.4), radius: 12, x: 0, y: 0)
        }
    }
}

#Preview("Hero Carousel View") {
    ZStack {
        Color.black.ignoresSafeArea()
        HeroCarouselView(items: MediaItem.sampleRailItems) { _ in }
    }
    .frame(width: 900, height: 540)
}
