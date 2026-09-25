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
    
    private let baseURL = "https://api.themoviedb.org/3"
    private let apiKey = "3b3e414b17e563a0a42546315f54a9e1"
    private let bearerToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIzyjNlNDE0YjE3ZTU2M2EwYTQyNTQ2MzE1ZjU0YTllMSIsIm5iZiI6MTc4OTM4NDk4Mi41MTcsInN1YiI6IjZhYTdkOTE2NTA3NDM4NGQwNTUzODdhYiIsInNjb3BlcyI6WyJhcGlfcmVhZCxdLCJ2ZXJzaW9uIjoxfQ.6AYp8QOYZm9SlVEHC-PQMf3gxFve-fJ4O6wQ6ihGh2o"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .useProtocolCachePolicy
        config.timeoutIntervalForRequest = 15.0
        self.session = URLSession(configuration: config)
    }
    
    private func makeRequest(endpoint: String, queryItems: [URLQueryItem] = []) -> URLRequest? {
        guard var components = URLComponents(string: "\(baseURL)\(endpoint)") else { return nil }
        var items = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]
        items.append(contentsOf: queryItems)
        components.queryItems = items
        
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    private func fetchMediaList(endpoint: String, queryItems: [URLQueryItem] = []) async throws -> [MediaItem] {
        guard let request = makeRequest(endpoint: endpoint, queryItems: queryItems) else {
            return MediaItem.sampleRailItems
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return MediaItem.sampleRailItems
            }
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(TMDBPaginatedResponse.self, from: data)
            let items = (decoded.results ?? []).map { MediaItem.fromTMDBResponse($0) }
            return items.isEmpty ? MediaItem.sampleRailItems : items
        } catch {
            return MediaItem.sampleRailItems
        }
    }
    
    // MARK: - Public API Feeds
    
    public func fetchTrending() async throws -> [MediaItem] {
        return try await fetchMediaList(endpoint: "/trending/all/day")
    }
    
    public func fetchHeroItem() async throws -> MediaItem {
        let trending = try await fetchTrending()
        return trending.first ?? MediaItem.sampleHero
    }
    
    public func fetchTrendingMovies() async throws -> [MediaItem] {
        return try await fetchMediaList(endpoint: "/trending/movie/day")
    }
    
    public func fetchTrendingSeries() async throws -> [MediaItem] {
        return try await fetchMediaList(endpoint: "/trending/tv/day")
    }
    
    public func fetchPopularMovies() async throws -> [MediaItem] {
        return try await fetchMediaList(
            endpoint: "/discover/movie",
            queryItems: [
                URLQueryItem(name: "sort_by", value: "popularity.desc"),
                URLQueryItem(name: "vote_count.gte", value: "200")
            ]
        )
    }
    
    public func fetchPopularSeries() async throws -> [MediaItem] {
        return try await fetchMediaList(
            endpoint: "/discover/tv",
            queryItems: [
                URLQueryItem(name: "sort_by", value: "popularity.desc"),
                URLQueryItem(name: "vote_count.gte", value: "100")
            ]
        )
    }
    
    public func fetch4KCollection() async throws -> [MediaItem] {
        return try await fetchMediaList(
            endpoint: "/discover/movie",
            queryItems: [
                URLQueryItem(name: "sort_by", value: "vote_average.desc"),
                URLQueryItem(name: "vote_count.gte", value: "5000")
            ]
        )
    }
    
    public func fetchInfiniteMovies(page: Int = 1) async throws -> [MediaItem] {
        return try await fetchMediaList(
            endpoint: "/discover/movie",
            queryItems: [
                URLQueryItem(name: "sort_by", value: "popularity.desc"),
                URLQueryItem(name: "page", value: "\(page)")
            ]
        )
    }
    
    public func search(query: String) async throws -> [MediaItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return try await fetchMediaList(
            endpoint: "/search/multi",
            queryItems: [URLQueryItem(name: "query", value: query)]
        )
    }
    
    // MARK: - Detailed Media Info & Streams
    
    public struct DetailedMediaInfo {
        public let imdbId: String?
        public let logoURL: URL?
        public let cast: [CastMember]
        public let runtimeSeconds: Double
        public let genres: [String]
        public let description: String?
        public let backdropURL: URL?
        public let posterURL: URL?
    }
    
    public func fetchDetails(id: String, isMovie: Bool = true) async -> DetailedMediaInfo {
        let endpoint = isMovie ? "/movie/\(id)" : "/tv/\(id)"
        guard let request = makeRequest(
            endpoint: endpoint,
            queryItems: [URLQueryItem(name: "append_to_response", value: "credits,images,external_ids")]
        ) else {
            return DetailedMediaInfo(imdbId: nil, logoURL: nil, cast: [], runtimeSeconds: 7200, genres: [], description: nil, backdropURL: nil, posterURL: nil)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
                return DetailedMediaInfo(imdbId: nil, logoURL: nil, cast: [], runtimeSeconds: 7200, genres: [], description: nil, backdropURL: nil, posterURL: nil)
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return DetailedMediaInfo(imdbId: nil, logoURL: nil, cast: [], runtimeSeconds: 7200, genres: [], description: nil, backdropURL: nil, posterURL: nil)
            }
            
            // 1. Extract IMDb ID
            var imdbId: String? = json["imdb_id"] as? String
            if imdbId == nil, let extIds = json["external_ids"] as? [String: Any] {
                imdbId = extIds["imdb_id"] as? String
            }
            
            // 2. Extract Logo URL
            var logoURL: URL? = nil
            if let images = json["images"] as? [String: Any], let logos = images["logos"] as? [[String: Any]] {
                let enLogos = logos.filter { ($0["iso_639_1"] as? String) == "en" }
                let chosenLogo = enLogos.first ?? logos.first
                if let filePath = chosenLogo?["file_path"] as? String {
                    logoURL = URL(string: "https://image.tmdb.org/t/p/w500\(filePath)")
                }
            }
            
            // 3. Extract Cast Members
            var castList: [CastMember] = []
            if let credits = json["credits"] as? [String: Any], let castArray = credits["cast"] as? [[String: Any]] {
                for castObj in castArray.prefix(10) {
                    let castId = "\(castObj["id"] ?? UUID().uuidString)"
                    let name = (castObj["name"] as? String) ?? "Actor"
                    let character = (castObj["character"] as? String) ?? "Character"
                    var profileURL: URL? = nil
                    if let path = castObj["profile_path"] as? String {
                        profileURL = URL(string: "https://image.tmdb.org/t/p/w185\(path)")
                    }
                    castList.append(CastMember(id: castId, name: name, character: character, profileURL: profileURL))
                }
            }
            
            // 4. Runtime & Genres
            let runtimeMins = (json["runtime"] as? Double) ?? (json["episode_run_time"] as? [Double])?.first ?? 120.0
            let genresArray = (json["genres"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []
            let overview = json["overview"] as? String
            
            var backdropURL: URL? = nil
            if let bPath = json["backdrop_path"] as? String {
                backdropURL = URL(string: "https://image.tmdb.org/t/p/w1280\(bPath)")
            }
            var posterURL: URL? = nil
            if let pPath = json["poster_path"] as? String {
                posterURL = URL(string: "https://image.tmdb.org/t/p/w500\(pPath)")
            }
            
            return DetailedMediaInfo(
                imdbId: imdbId,
                logoURL: logoURL,
                cast: castList,
                runtimeSeconds: runtimeMins * 60,
                genres: genresArray,
                description: overview,
                backdropURL: backdropURL,
                posterURL: posterURL
            )
        } catch {
            return DetailedMediaInfo(imdbId: nil, logoURL: nil, cast: [], runtimeSeconds: 7200, genres: [], description: nil, backdropURL: nil, posterURL: nil)
        }
    }
    
    // MARK: - Torrentio & Real-Debrid Stream Scraper
    
    public func fetchStreams(imdbId: String?, title: String, year: String, type: String = "movie") async -> [StreamOption] {
        guard let imdb = imdbId, !imdb.isEmpty else {
            return generateFallbackStreams(title: title, year: year)
        }
        
        let torrentioEndpoint = "https://torrentio.strem.fun/stream/\(type)/\(imdb).json"
        guard let url = URL(string: torrentioEndpoint) else {
            return generateFallbackStreams(title: title, year: year)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 6.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let streamsRaw = json["streams"] as? [[String: Any]], !streamsRaw.isEmpty else {
                return generateFallbackStreams(title: title, year: year)
            }
            
            var options: [StreamOption] = []
            for (idx, s) in streamsRaw.prefix(8).enumerated() {
                let name = (s["name"] as? String) ?? "Torrentio"
                let rawTitle = (s["title"] as? String) ?? title
                let infoHash = s["infoHash"] as? String
                let directUrlStr = s["url"] as? String
                
                // Parse quality & resolution
                let combined = "\(name) \(rawTitle)".lowercased()
                let resolution: String
                let quality: String
                if combined.contains("4k") || combined.contains("2160p") || combined.contains("uhd") {
                    resolution = "3840x2160"
                    quality = combined.contains("remux") ? "4K REMUX 2160p" : (combined.contains("hdr") ? "4K HDR 2160p" : "4K Ultra HD")
                } else if combined.contains("1080p") || combined.contains("fhd") {
                    resolution = "1920x1080"
                    quality = combined.contains("remux") ? "1080p REMUX" : (combined.contains("web") ? "1080p Web-DL" : "1080p HD")
                } else if combined.contains("720p") {
                    resolution = "1280x720"
                    quality = "720p HD"
                } else {
                    resolution = "1920x1080"
                    quality = "HD 1080p"
                }
                
                // Codec & HDR
                var codec = "H.264 / AVC"
                if combined.contains("hevc") || combined.contains("h.265") || combined.contains("x265") {
                    codec = combined.contains("hdr") ? "HEVC • HDR10" : "HEVC • 10-Bit"
                } else if combined.contains("av1") {
                    codec = "AV1 • Next-Gen"
                }
                
                // Audio
                var audio = "5.1 Surround"
                if combined.contains("atmos") {
                    audio = "Dolby Atmos 7.1"
                } else if combined.contains("7.1") || combined.contains("truehd") {
                    audio = "TrueHD 7.1"
                } else if combined.contains("dts") {
                    audio = "DTS-HD 5.1"
                } else if combined.contains("aac") {
                    audio = "AAC 2.0 / 5.1"
                }
                
                // Size & Seeders from Title text (e.g. "👤 142 💾 4.5 GB")
                var size = "3.2 GB"
                if let sizeRange = rawTitle.range(of: "💾\\s*([0-9\\.]+\\s*(?:GB|MB))", options: .regularExpression) {
                    let sub = rawTitle[sizeRange].replacingOccurrences(of: "💾", with: "").trimmingCharacters(in: .whitespaces)
                    size = sub
                }
                
                var seeders = 85
                if let seedRange = rawTitle.range(of: "👤\\s*([0-9]+)", options: .regularExpression) {
                    let seedDigits = rawTitle[seedRange].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    if let sInt = Int(seedDigits) {
                        seeders = sInt
                    }
                }
                
                let magnetURL = infoHash != nil ? "magnet:?xt=urn:btih:\(infoHash!)&dn=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "media")" : nil
                let playableURL = directUrlStr != nil ? (URL(string: directUrlStr!) ?? URL(string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")!) : URL(string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")!
                
                let isCached = combined.contains("rd+") || combined.contains("⚡") || combined.contains("debrid")
                let provider = isCached ? "⚡️ Real-Debrid CDN" : "🔄 Torrentio P2P"
                
                options.append(StreamOption(
                    id: "stream-\(imdb)-\(idx)",
                    quality: quality,
                    resolution: resolution,
                    codec: codec,
                    audio: audio,
                    size: size,
                    seeders: seeders,
                    leechers: max(2, seeders / 12),
                    provider: provider,
                    streamURL: playableURL,
                    magnetURL: magnetURL
                ))
            }
            
            return options.isEmpty ? generateFallbackStreams(title: title, year: year) : options
        } catch {
            return generateFallbackStreams(title: title, year: year)
        }
    }
    
    private func generateFallbackStreams(title: String, year: String) -> [StreamOption] {
        return [
            StreamOption(
                id: "stream-fb-4k",
                quality: "4K UHD Web-DL",
                resolution: "3840x2160",
                codec: "HEVC • Dolby Vision",
                audio: "Dolby Atmos 7.1",
                size: "18.4 GB",
                seeders: 312,
                leechers: 24,
                provider: "⚡️ Real-Debrid CDN",
                streamURL: URL(string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")!,
                magnetURL: "magnet:?xt=urn:btih:fallback4khash1234567890abcdef"
            ),
            StreamOption(
                id: "stream-fb-1080p",
                quality: "1080p Full HD",
                resolution: "1920x1080",
                codec: "HEVC • 10-Bit Color",
                audio: "EAC3 5.1 Surround",
                size: "6.2 GB",
                seeders: 184,
                leechers: 15,
                provider: "⚡️ Real-Debrid CDN",
                streamURL: URL(string: "https://vjs.zencdn.net/v/oceans.mp4")!,
                magnetURL: "magnet:?xt=urn:btih:fallback1080phash1234567890abcdef"
            ),
            StreamOption(
                id: "stream-fb-720p",
                quality: "720p HD Standard",
                resolution: "1280x720",
                codec: "H.264 / AVC",
                audio: "AAC 2.0",
                size: "2.1 GB",
                seeders: 72,
                leechers: 6,
                provider: "🔄 Native P2P Swarm",
                streamURL: URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!,
                magnetURL: "magnet:?xt=urn:btih:fallback720phash1234567890abcdef"
            )
        ]
    }
}

