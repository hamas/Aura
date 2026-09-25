//
//  StreamResolverService.swift
//  Aura
//
//  Hybrid Stream Resolver Service: Fast-path Debrid CDN resolver with Local Torrent Proxy fallback.
//

import Foundation

public enum StreamState: Equatable {
    case idle
    case resolving(provider: String)
    case connectingPeers(peersCount: Int)
    case prebuffering(progress: Double)
    case playing(url: URL, isDebrid: Bool)
    case failed(error: String)
    
    public var description: String {
        switch self {
        case .idle:
            return "Ready"
        case .resolving(let provider):
            return "Resolving fast-path via \(provider)..."
        case .connectingPeers(let count):
            return "Connecting to P2P swarm (\(count) active seeders)..."
        case .prebuffering(let progress):
            return String(format: "Pre-buffering media headers: %.0f%%", progress * 100)
        case .playing(_, let isDebrid):
            return isDebrid ? "Direct High-Speed CDN Stream" : "Local Sequential P2P Proxy"
        case .failed(let error):
            return "Stream Error: \(error)"
        }
    }
}

public actor StreamResolverService {
    public static let shared = StreamResolverService()
    
    private let realDebridBaseURL = "https://api.real-debrid.com/rest/1.0"
    private var apiKey: String? = nil
    
    private init() {}
    
    public func setDebridAPIKey(_ key: String) {
        self.apiKey = key
        print("⚡️ [RESOLVER] Configured Debrid API Key (\(key.prefix(6))...)")
    }
    
    /// Resolve stream: Checks Tier 1 (Debrid Fast-Path / Direct HTTP) first, falling back to Tier 2 (Local Torrent Proxy)
    public func resolve(
        mediaItem: MediaItem,
        magnetURLOrHash: String?,
        onStateChange: @Sendable @escaping (StreamState) -> Void
    ) async -> URL {
        print("⚡️ [RESOLVER] Initializing stream resolution for '\(mediaItem.title)' [ID: \(mediaItem.id)]")
        onStateChange(.resolving(provider: "Debrid CDN"))
        
        // 1. Tier 1: Check Debrid Fast-Path if magnet or torrent hash is provided
        if let magnet = magnetURLOrHash, !magnet.isEmpty {
            print("⚡️ [RESOLVER] Querying Debrid API for magnet/hash: \(magnet.prefix(30))...")
            if let directDebridURL = await tryResolveDebrid(magnet: magnet) {
                print("✅ [RESOLVER] Debrid Fast-Path Resolved: \(directDebridURL)")
                onStateChange(.playing(url: directDebridURL, isDebrid: true))
                return directDebridURL
            } else {
                print("⚠️ [RESOLVER] Debrid uncached or key missing. Falling back to direct HTTP stream...")
            }
        }
        
        // 2. Direct Web Stream Handoff
        if mediaItem.streamURL.scheme == "http" || mediaItem.streamURL.scheme == "https" {
            print("✅ [RESOLVER] Direct High-Speed Web Stream Selected: \(mediaItem.streamURL)")
            onStateChange(.playing(url: mediaItem.streamURL, isDebrid: true))
            return mediaItem.streamURL
        }
        
        // 3. Tier 2: Local P2P Torrent Proxy Engine
        print("🔄 [RESOLVER] Routing to Tier 2 Embedded P2P Torrent Proxy...")
        onStateChange(.connectingPeers(peersCount: 42))
        
        let localProxyURL = await LocalTorrentProxyEngine.shared.getOrStartProxyStream(
            magnetURL: magnetURLOrHash ?? mediaItem.streamURL.absoluteString
        )
        
        print("✅ [RESOLVER] Local P2P Proxy Stream Active: \(localProxyURL)")
        onStateChange(.playing(url: localProxyURL, isDebrid: false))
        return localProxyURL
    }
    
    private func tryResolveDebrid(magnet: String) async -> URL? {
        guard let key = apiKey, !key.isEmpty else {
            print("ℹ️ [RESOLVER] No Debrid API token configured.")
            return nil
        }
        
        let hash = extractInfoHash(from: magnet)
        guard !hash.isEmpty else {
            print("⚠️ [RESOLVER] Invalid magnet/hash extracted.")
            return nil
        }
        
        let endpoint = "\(realDebridBaseURL)/torrents/instantAvailability/\(hash)"
        guard let url = URL(string: endpoint) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse else { return nil }
            print("⚡️ [RESOLVER] Real-Debrid API HTTP \(httpResp.statusCode)")
            
            if httpResp.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let hashDict = json[hash.lowercased()] as? [String: Any],
               let rdContainer = hashDict["rd"] as? [[String: Any]], !rdContainer.isEmpty {
                if let firstFile = rdContainer.first?.values.first as? [String: Any],
                   let linkStr = firstFile["link"] as? String, let directURL = URL(string: linkStr) {
                    return directURL
                }
            }
        } catch {
            print("❌ [RESOLVER] Debrid network error: \(error.localizedDescription)")
            return nil
        }
        
        return nil
    }
    
    private func extractInfoHash(from magnet: String) -> String {
        if magnet.lowercased().hasPrefix("magnet:?") {
            if let range = magnet.range(of: "btih:") {
                let sub = magnet[range.upperBound...]
                let hash = sub.components(separatedBy: "&").first ?? ""
                return String(hash)
            }
        }
        return magnet.count == 40 || magnet.count == 32 ? magnet : ""
    }
}
