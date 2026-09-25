//
//  BookmarkManager.swift
//  Aura
//
//  Persistent User Library Store for Favorites, Watchlist, Watch History, and Offline Downloads.
//

import SwiftUI
import Foundation

public final class BookmarkManager: ObservableObject {
    public static let shared = BookmarkManager()
    
    @Published public var favorites: [MediaItem] = []
    @Published public var watchlist: [MediaItem] = []
    @Published public var watchHistory: [MediaItem] = []
    @Published public var watchProgress: [String: Double] = [:] // itemId -> progress (0.0 to 1.0)
    
    private let favoritesKey = "aura_user_favorites"
    private let watchlistKey = "aura_user_watchlist"
    private let historyKey = "aura_user_history"
    private let progressKey = "aura_user_progress"
    
    private init() {
        loadData()
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
        saveData()
    }
    
    // MARK: - Watchlist
    public func inWatchlist(_ item: MediaItem) -> Bool {
        watchlist.contains(where: { $0.id == item.id })
    }
    
    public func toggleWatchlist(_ item: MediaItem) {
        if inWatchlist(item) {
            watchlist.removeAll(where: { $0.id == item.id })
        } else {
            watchlist.append(item)
        }
        saveData()
    }
    
    // MARK: - History & Progress
    public func addToHistory(_ item: MediaItem, progress: Double = 0.0) {
        if let idx = watchHistory.firstIndex(where: { $0.id == item.id }) {
            watchHistory.remove(at: idx)
        }
        watchHistory.insert(item, at: 0)
        watchProgress[item.id] = progress
        saveData()
    }
    
    public func getProgress(_ item: MediaItem) -> Double {
        watchProgress[item.id] ?? 0.0
    }
    
    // MARK: - Persistence
    private func saveData() {
        let encoder = JSONEncoder()
        if let favData = try? encoder.encode(favorites) {
            UserDefaults.standard.set(favData, forKey: favoritesKey)
        }
        if let watchData = try? encoder.encode(watchlist) {
            UserDefaults.standard.set(watchData, forKey: watchlistKey)
        }
        if let histData = try? encoder.encode(watchHistory) {
            UserDefaults.standard.set(histData, forKey: historyKey)
        }
        UserDefaults.standard.set(watchProgress, forKey: progressKey)
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        if let favData = UserDefaults.standard.data(forKey: favoritesKey),
           let decodedFavs = try? decoder.decode([MediaItem].self, from: favData) {
            self.favorites = decodedFavs
        } else {
            self.favorites = MediaItem.sampleRailItems
        }
        
        if let watchData = UserDefaults.standard.data(forKey: watchlistKey),
           let decodedWatch = try? decoder.decode([MediaItem].self, from: watchData) {
            self.watchlist = decodedWatch
        } else {
            self.watchlist = Array(MediaItem.sampleRailItems.prefix(2))
        }
        
        if let histData = UserDefaults.standard.data(forKey: historyKey),
           let decodedHist = try? decoder.decode([MediaItem].self, from: histData) {
            self.watchHistory = decodedHist
        } else {
            self.watchHistory = MediaItem.sampleRailItems
        }
        
        if let progDict = UserDefaults.standard.dictionary(forKey: progressKey) as? [String: Double] {
            self.watchProgress = progDict
        } else {
            self.watchProgress = [
                MediaItem.sampleRailItems[0].id: 0.65,
                MediaItem.sampleRailItems[1].id: 0.30
            ]
        }
    }
}
