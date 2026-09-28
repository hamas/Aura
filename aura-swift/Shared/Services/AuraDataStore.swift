//
//  AuraDataStore.swift
//  Aura
//
//  Unified persistent data store for Watchlist, Continue Watching, History, and Downloads.
//

import Foundation
import SwiftUI
import Combine

public struct WatchProgressRecord: Codable, Hashable {
    public let mediaId: String
    public var positionSeconds: Double
    public var durationSeconds: Double
    public var seasonNumber: Int?
    public var episodeNumber: Int?
    public var lastWatchedAt: Date
    
    public init(
        mediaId: String,
        positionSeconds: Double,
        durationSeconds: Double,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        lastWatchedAt: Date = Date()
    ) {
        self.mediaId = mediaId
        self.positionSeconds = positionSeconds
        self.durationSeconds = durationSeconds
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.lastWatchedAt = lastWatchedAt
    }
    
    public var progressPercent: Double {
        guard durationSeconds > 0 else { return 0.0 }
        return min(1.0, max(0.0, positionSeconds / durationSeconds))
    }
}

@MainActor
public final class AuraDataStore: ObservableObject {
    public static let shared = AuraDataStore()
    
    @Published public var watchlist: [MediaItem] = []
    @Published public var favorites: [MediaItem] = []
    @Published public var continueWatching: [MediaItem] = []
    @Published public var progressMap: [String: WatchProgressRecord] = [:]
    
    private let fileManager = FileManager.default
    private var storeURL: URL {
        let docs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let auraDir = docs.appendingPathComponent("Aura", isDirectory: true)
        if !fileManager.fileExists(atPath: auraDir.path) {
            try? fileManager.createDirectory(at: auraDir, withIntermediateDirectories: true)
        }
        return auraDir.appendingPathComponent("aura_library.json")
    }
    
    private init() {
        loadFromDisk()
    }
    
    // MARK: - Watchlist
    public func isInWatchlist(_ item: MediaItem) -> Bool {
        watchlist.contains(where: { $0.id == item.id })
    }
    
    public func toggleWatchlist(_ item: MediaItem) {
        if isInWatchlist(item) {
            watchlist.removeAll(where: { $0.id == item.id })
        } else {
            watchlist.append(item)
        }
        saveToDisk()
    }
    
    // MARK: - Favorites
    public func isFavorite(_ item: MediaItem) -> Bool {
        favorites.contains(where: { $0.id == item.id })
    }
    
    public func toggleFavorite(_ item: MediaItem) {
        if isFavorite(item) {
            favorites.removeAll(where: { $0.id == item.id })
        } else {
            favorites.append(item)
        }
        saveToDisk()
    }
    
    // MARK: - Continue Watching & Progress
    public func updateProgress(
        item: MediaItem,
        positionSeconds: Double,
        durationSeconds: Double,
        season: Int? = nil,
        episode: Int? = nil
    ) {
        let record = WatchProgressRecord(
            mediaId: item.id,
            positionSeconds: positionSeconds,
            durationSeconds: durationSeconds,
            seasonNumber: season,
            episodeNumber: episode,
            lastWatchedAt: Date()
        )
        progressMap[item.id] = record
        
        // Update Continue Watching list (if > 10s watched and < 95% complete)
        let percent = record.progressPercent
        if percent > 0.02 && percent < 0.95 {
            if let idx = continueWatching.firstIndex(where: { $0.id == item.id }) {
                continueWatching.remove(at: idx)
            }
            continueWatching.insert(item, at: 0)
        } else if percent >= 0.95 {
            continueWatching.removeAll(where: { $0.id == item.id })
        }
        
        saveToDisk()
    }
    
    public func getProgress(for item: MediaItem) -> WatchProgressRecord? {
        return progressMap[item.id]
    }
    
    // MARK: - Persistence IO
    private struct StorePayload: Codable {
        let watchlist: [MediaItem]
        let favorites: [MediaItem]
        let continueWatching: [MediaItem]
        let progressMap: [String: WatchProgressRecord]
    }
    
    private func saveToDisk() {
        let payload = StorePayload(
            watchlist: watchlist,
            favorites: favorites,
            continueWatching: continueWatching,
            progressMap: progressMap
        )
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: storeURL, options: .atomic)
        }
    }
    
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storeURL),
              let payload = try? JSONDecoder().decode(StorePayload.self, from: data) else {
            // Default sample items for clean first launch
            self.watchlist = Array(MediaItem.sampleRailItems.prefix(2))
            self.favorites = MediaItem.sampleRailItems
            return
        }
        self.watchlist = payload.watchlist
        self.favorites = payload.favorites
        self.continueWatching = payload.continueWatching
        self.progressMap = payload.progressMap
    }
}
