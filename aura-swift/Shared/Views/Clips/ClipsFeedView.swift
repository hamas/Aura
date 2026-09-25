//
//  ClipsFeedView.swift
//  Aura
//
//  Vertical Short-Form Video Trailer Reel Feed for discovering trending titles.
//

import SwiftUI
import AVKit

public struct ClipItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let year: String
    public let genre: String
    public let videoURL: String
    public let backdropURL: String
    public let mediaItem: MediaItem
    
    public init(id: String, title: String, year: String, genre: String, videoURL: String, backdropURL: String, mediaItem: MediaItem) {
        self.id = id
        self.title = title
        self.year = year
        self.genre = genre
        self.videoURL = videoURL
        self.backdropURL = backdropURL
        self.mediaItem = mediaItem
    }
}

public struct ClipsFeedView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @State private var clips: [ClipItem] = [
        ClipItem(
            id: "clip_1",
            title: "Dune: Part Two",
            year: "2024",
            genre: "Sci-Fi / Adventure",
            videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
            backdropURL: "https://image.tmdb.org/t/p/w1280/xOMo8ScSu26yB6Xm43x0FQIOfF6.jpg",
            mediaItem: MediaItem.sampleHero
        ),
        ClipItem(
            id: "clip_2",
            title: "Oppenheimer",
            year: "2023",
            genre: "Biography / Drama",
            videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
            backdropURL: "https://image.tmdb.org/t/p/w1280/fm6KqXrmjC2T2yqKWm9egWxuvLI.jpg",
            mediaItem: MediaItem.sampleRailItems[0]
        ),
        ClipItem(
            id: "clip_3",
            title: "Cyberpunk: Edgerunners",
            year: "2023",
            genre: "Anime / Sci-Fi",
            videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            backdropURL: "https://image.tmdb.org/t/p/w1280/84XP7pWuF2vW68d6xpc5yP9Yjip.jpg",
            mediaItem: MediaItem.sampleRailItems[1]
        )
    ]
    @State private var currentIndex: Int = 0
    @State private var isMuted: Bool = false
    @State private var isLiked: [String: Bool] = [:]
    @State private var isSaved: [String: Bool] = [:]
    var onSelectMedia: ((MediaItem) -> Void)? = nil
    
    public init(onSelectMedia: ((MediaItem) -> Void)? = nil) {
        self.onSelectMedia = onSelectMedia
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if clips.indices.contains(currentIndex) {
                    let currentClip = clips[currentIndex]
                    
                    SingleClipPlayerView(clip: currentClip, isMuted: $isMuted)
                        .id(currentClip.id)
                        .ignoresSafeArea()
                    
                    // Liquid Glass Overlay Control Bar
                    VStack {
                        // Top Bar: Navigation & Title
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "film.stack.fill")
                                        .foregroundColor(Color(red: 255/255, green: 45/255, blue: 85/255))
                                    Text("Aura Clips Reel")
                                        .font(.headline.weight(.bold))
                                        .foregroundColor(.white)
                                }
                                Text("Discover trending trailers in full 4K HDR")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            // Mute Toggle Button
                            Button(action: { isMuted.toggle() }) {
                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        Spacer()
                        
                        // Bottom Control Panel: Title, Metadata, Action Buttons
                        HStack(alignment: .bottom, spacing: 16) {
                            // Left Side: Title & Info
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    Text(currentClip.year)
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Capsule())
                                    
                                    Text(currentClip.genre)
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Text(currentClip.title)
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 3)
                                
                                Button(action: {
                                    if let onSelect = onSelectMedia {
                                        onSelect(currentClip.mediaItem)
                                    } else {
                                        playerManager.loadMedia(currentClip.mediaItem)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "play.fill")
                                        Text("Play Movie")
                                    }
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Spacer()
                            
                            // Right Side Vertical Action Buttons (Like, Bookmark, Share, Next/Prev)
                            VStack(spacing: 18) {
                                Button(action: {
                                    let current = isLiked[currentClip.id] ?? false
                                    isLiked[currentClip.id] = !current
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: (isLiked[currentClip.id] ?? false) ? "heart.fill" : "heart")
                                            .font(.title2)
                                            .foregroundColor((isLiked[currentClip.id] ?? false) ? .red : .white)
                                        Text("Like")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    let current = isSaved[currentClip.id] ?? false
                                    isSaved[currentClip.id] = !current
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: (isSaved[currentClip.id] ?? false) ? "bookmark.fill" : "bookmark")
                                            .font(.title2)
                                            .foregroundColor((isSaved[currentClip.id] ?? false) ? Color(red: 255/255, green: 45/255, blue: 85/255) : .white)
                                        Text("Saved")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Up / Down Carousel Navigation Buttons
                                VStack(spacing: 8) {
                                    Button(action: {
                                        if currentIndex > 0 {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                currentIndex -= 1
                                            }
                                        }
                                    }) {
                                        Image(systemName: "chevron.up")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(currentIndex > 0 ? .white : .white.opacity(0.3))
                                            .padding(8)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                    }
                                    .disabled(currentIndex == 0)
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        if currentIndex < clips.count - 1 {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                currentIndex += 1
                                            }
                                        }
                                    }) {
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(currentIndex < clips.count - 1 ? .white : .white.opacity(0.3))
                                            .padding(8)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                    }
                                    .disabled(currentIndex == clips.count - 1)
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
    }
}

// MARK: - Single Clip AVPlayer Loop View
struct SingleClipPlayerView: View {
    let clip: ClipItem
    @Binding var isMuted: Bool
    @State private var avPlayer: AVPlayer?
    
    var body: some View {
        ZStack {
            if let player = avPlayer {
                VideoPlayer(player: player)
                    .disabled(true)
            } else {
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            if let url = URL(string: clip.videoURL) {
                let player = AVPlayer(url: url)
                player.isMuted = isMuted
                player.actionAtItemEnd = .none
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
                player.play()
                self.avPlayer = player
            }
        }
        .onDisappear {
            avPlayer?.pause()
            avPlayer = nil
        }
        .onChange(of: isMuted) { _, muted in
            avPlayer?.isMuted = muted
        }
    }
}
