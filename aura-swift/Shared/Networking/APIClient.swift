//
//  APIClient.swift
//  Aura
//
//  Async/Await native HTTP Client for Apple Multiplatform target.
//

import Foundation

public final class APIClient {
    public static let shared = APIClient()
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadRevalidatingCacheData
        config.timeoutIntervalForRequest = 15.0
        self.session = URLSession(configuration: config)
    }
    
    public func fetchCatalog() async throws -> [MediaItem] {
        // Return structured mock catalog or remote payload
        return MediaItem.sampleRailItems
    }
    
    public func fetchHeroItem() async throws -> MediaItem {
        return MediaItem.sampleHero
    }
}
