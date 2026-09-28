//
//  EpisodeItem.swift
//  Aura
//
//  Data model representing seasons and individual television episodes.
//

import Foundation

public struct EpisodeItem: Identifiable, Hashable, Codable {
    public let id: String
    public let seasonNumber: Int
    public let episodeNumber: Int
    public let title: String
    public let overview: String
    public let stillURL: URL?
    public let durationSeconds: Double
    public let streamURL: URL
    
    public init(
        id: String,
        seasonNumber: Int,
        episodeNumber: Int,
        title: String,
        overview: String,
        stillURL: URL? = nil,
        durationSeconds: Double = 3000,
        streamURL: URL
    ) {
        self.id = id
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.title = title
        self.overview = overview
        self.stillURL = stillURL
        self.durationSeconds = durationSeconds
        self.streamURL = streamURL
    }
    
    public var formattedNumber: String {
        return "S\(seasonNumber) E\(episodeNumber)"
    }
}

public struct SeasonItem: Identifiable, Hashable, Codable {
    public let id: String
    public let seasonNumber: Int
    public let name: String
    public let episodeCount: Int
    public let episodes: [EpisodeItem]
    
    public init(
        id: String,
        seasonNumber: Int,
        name: String,
        episodeCount: Int,
        episodes: [EpisodeItem] = []
    ) {
        self.id = id
        self.seasonNumber = seasonNumber
        self.name = name
        self.episodeCount = episodeCount
        self.episodes = episodes
    }
}
