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
    
    // MARK: - Stremio Addons & Debrid Stream Aggregator
    
    public func fetchStreams(imdbId: String?, title: String, year: String, type: String = "movie") async -> [StreamOption] {
        return await StremioAddonManager.shared.fetchAggregatedStreams(
            type: type,
            id: imdbId ?? "",
            imdbId: imdbId,
            title: title,
            year: year
        )
    }
}

