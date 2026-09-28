//
//  InPlayerEpisodeSheet.swift
//  Aura
//
//  In-player slide-out sheet for browsing and switching seasons & episodes.
//

import SwiftUI

public struct InPlayerEpisodeSheet: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    public var onClose: () -> Void
    
    @State private var selectedSeasonNumber: Int = 1
    
    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    // Sample seasons for demo / playback switching if not preloaded
    private var seasons: [SeasonItem] {
        if !playerManager.availableSeasons.isEmpty {
            return playerManager.availableSeasons
        }
        
        let sampleStreams = [
            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
            "https://vjs.zencdn.net/v/oceans.mp4",
            "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"
        ]
        
        return (1...3).map { seasonNum in
            let episodes = (1...8).map { epNum in
                EpisodeItem(
                    id: "s\(seasonNum)-e\(epNum)",
                    seasonNumber: seasonNum,
                    episodeNumber: epNum,
                    title: "Episode \(epNum): The Journey Continues",
                    overview: "The party ventures deeper into the unknown as new threats emerge from the shadows.",
                    stillURL: URL(string: "https://image.tmdb.org/t/p/w500/sample.jpg"),
                    durationSeconds: 3120,
                    streamURL: URL(string: sampleStreams[epNum % sampleStreams.count])!
                )
            }
            return SeasonItem(
                id: "season-\(seasonNum)",
                seasonNumber: seasonNum,
                name: "Season \(seasonNum)",
                episodeCount: 8,
                episodes: episodes
            )
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Episodes & Seasons")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Season Selector Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(seasons) { season in
                        Button(action: { selectedSeasonNumber = season.seasonNumber }) {
                            Text(season.name)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    selectedSeasonNumber == season.seasonNumber
                                        ? Color(red: 184/255, green: 119/255, blue: 255/255)
                                        : Color.white.opacity(0.12)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Episode List
            if let currentSeason = seasons.first(where: { $0.seasonNumber == selectedSeasonNumber }) {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 10) {
                        ForEach(currentSeason.episodes) { ep in
                            Button(action: {
                                if let item = playerManager.currentItem {
                                    let option = StreamOption(
                                        id: ep.id,
                                        quality: "1080p HD",
                                        resolution: "1920x1080",
                                        codec: "H.264",
                                        audio: "AAC 2.0",
                                        size: "3.2 GB",
                                        seeders: 120,
                                        leechers: 10,
                                        provider: "⚡️ Real-Debrid CDN",
                                        streamURL: ep.streamURL
                                    )
                                    playerManager.loadStream(item: item, option: option)
                                }
                                onClose()
                            }) {
                                HStack(spacing: 12) {
                                    // Thumbnail / Index
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
                                            .frame(width: 90, height: 56)
                                        
                                        Image(systemName: "play.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.white.opacity(0.85))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(ep.episodeNumber). \(ep.title)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Text(ep.overview)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(Int(ep.durationSeconds / 60))m")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .frame(maxHeight: 340)
            }
        }
        .padding(20)
        .frame(width: 480)
        .background(
            Color.black.opacity(0.92)
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.7), radius: 30, x: 0, y: 10)
    }
}
