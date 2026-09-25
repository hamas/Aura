//
//  MediaGridCardView.swift
//  Aura
//
//  Reusable media grid item card view with customizable overlay.
//

import SwiftUI

public struct MediaGridCardView<Overlay: View>: View {
    let item: MediaItem
    let action: () -> Void
    let overlay: Overlay
    
    public init(item: MediaItem, action: @escaping () -> Void, @ViewBuilder overlay: () -> Overlay = { EmptyView() }) {
        self.item = item
        self.action = action
        self.overlay = overlay()
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: item.posterURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(white: 0.15))
                                .frame(height: 240)
                        }
                    }
                    
                    overlay
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
