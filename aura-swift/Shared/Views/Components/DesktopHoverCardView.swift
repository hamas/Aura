//
//  DesktopHoverCardView.swift
//  Aura
//
//  Netflix-style desktop hover expansion preview card (1.15x scale with quick action buttons).
//

import SwiftUI

public struct DesktopHoverCardView: View {
    public let item: MediaItem
    public let width: CGFloat
    public var onSelect: () -> Void
    public var onPlay: (() -> Void)? = nil
    public var onToggleWatchlist: (() -> Void)? = nil
    
    @State private var isHovered: Bool = false
    @State private var hoverTask: Task<Void, Never>?
    @State private var isBookmarked: Bool = false
    @State private var userRating: Int = 0 // 0: none, 1: thumbs up
    
    public init(
        item: MediaItem,
        width: CGFloat = 180,
        onSelect: @escaping () -> Void,
        onPlay: (() -> Void)? = nil,
        onToggleWatchlist: (() -> Void)? = nil
    ) {
        self.item = item
        self.width = width
        self.onSelect = onSelect
        self.onPlay = onPlay
        self.onToggleWatchlist = onToggleWatchlist
    }
    
    private var height: CGFloat {
        width * 1.5 // 2:3 aspect ratio
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Base Card Container
            VStack(alignment: .leading, spacing: 0) {
                // Key Art Image (Poster default -> Backdrop when hovered)
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: isHovered ? (item.highDefBackdropURL ?? item.backdropURL ?? item.posterURL) : (item.highDefPosterURL ?? item.posterURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: isHovered ? .fill : .fill)
                        default:
                            ZStack {
                                Color(red: 0.12, green: 0.12, blue: 0.15)
                                Image(systemName: "film")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(width: isHovered ? width * 1.15 : width, height: isHovered ? height * 0.55 : height)
                    .clipped()
                    
                    // Top 4K / HDR Badge
                    if item.is4K {
                        Text("4K")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.75))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(8)
                    }
                }
                
                // Hover Expanded Metadata & Action Buttons
                if isHovered {
                    VStack(alignment: .leading, spacing: 8) {
                        // Action Buttons Bar
                        HStack(spacing: 8) {
                            // Play Button
                            Button(action: { onPlay?() ?? onSelect() }) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Watchlist Button
                            Button(action: {
                                isBookmarked.toggle()
                                onToggleWatchlist?()
                            }) {
                                Image(systemName: isBookmarked ? "checkmark" : "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Thumbs Up
                            Button(action: {
                                userRating = userRating == 1 ? 0 : 1
                            }) {
                                Image(systemName: userRating == 1 ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(userRating == 1 ? Color(red: 184/255, green: 119/255, blue: 255/255) : .white)
                                    .padding(8)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            // Expand Details Chevron
                            Button(action: onSelect) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Match % and Certification Badges
                        HStack(spacing: 6) {
                            Text(item.matchScore)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 70/255, green: 211/255, blue: 105/255))
                            
                            Text(item.certification)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                                .foregroundColor(.white)
                            
                            if item.isHDR {
                                Text("HDR")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                                    .foregroundColor(.white)
                            }
                            
                            Text(item.releaseYear)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        // Genre Tags
                        Text(item.genres.prefix(3).joined(separator: " • "))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(12)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.12))
                }
            }
            .frame(width: isHovered ? width * 1.15 : width)
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered ? Color.white.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.75 : 0.25), radius: isHovered ? 20 : 6, x: 0, y: isHovered ? 10 : 2)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .zIndex(isHovered ? 99 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isHovered)
        }
        .onHover { hovering in
            hoverTask?.cancel()
            if hovering {
                hoverTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    if !Task.isCancelled {
                        withAnimation {
                            isHovered = true
                        }
                    }
                }
            } else {
                withAnimation {
                    isHovered = false
                }
            }
        }
        .onTapGesture {
            onSelect()
        }
    }
}
