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
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All") {}
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.purple.opacity(0.9))
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        Button(action: {
                            onItemTap(item)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.indigo.opacity(0.6), Color.purple.opacity(0.4)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 170, height: 240)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    
                                    AsyncImage(url: item.posterURL) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 170, height: 240)
                                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        }
                                    }
                                    
                                    if item.is4K {
                                        Text("4K")
                                            .font(.system(size: 9, weight: .black))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                            .padding(8)
                                    }
                                }
                                
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text("\(item.releaseYear) • \(item.subtitle)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 170)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
