//
//  MediaItem.swift
//  Aura
//
//  Model representing catalog media items and streaming metadata.
//

import Foundation

public struct MediaItem: Identifiable, Hashable, Codable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let description: String
    public let posterURL: URL?
    public let backdropURL: URL?
    public let logoURL: URL?
    public let streamURL: URL
    public let durationSeconds: Double
    public let rating: String
    public let releaseYear: String
    public let genres: [String]
    public let isHDR: Bool
    public let is4K: Bool
    
    public init(
        id: String,
        title: String,
        subtitle: String,
        description: String,
        posterURL: URL?,
        backdropURL: URL?,
        logoURL: URL? = nil,
        streamURL: URL,
        durationSeconds: Double,
        rating: String,
        releaseYear: String,
        genres: [String],
        isHDR: Bool = true,
        is4K: Bool = true
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.posterURL = posterURL
        self.backdropURL = backdropURL
        self.logoURL = logoURL
        self.streamURL = streamURL
        self.durationSeconds = durationSeconds
        self.rating = rating
        self.releaseYear = releaseYear
        self.genres = genres
        self.isHDR = isHDR
        self.is4K = is4K
    }
}

// MARK: - TMDB Raw Network Models
public struct TMDBPaginatedResponse: Codable {
    public let page: Int?
    public let results: [TMDBMediaItemResponse]?
    public let total_pages: Int?
    public let total_results: Int?
}

public struct TMDBMediaItemResponse: Codable {
    public let id: Int
    public let title: String?
    public let name: String?
    public let overview: String?
    public let poster_path: String?
    public let backdrop_path: String?
    public let vote_average: Double?
    public let release_date: String?
    public let first_air_date: String?
    public let media_type: String?
    public let genre_ids: [Int]?
}

extension MediaItem {
    public static func fromTMDBResponse(_ dto: TMDBMediaItemResponse) -> MediaItem {
        let title = dto.title ?? dto.name ?? "Untitled Release"
        let releaseDate = dto.release_date ?? dto.first_air_date ?? "2024"
        let year = String(releaseDate.prefix(4))
        
        let poster: URL? = dto.poster_path != nil ? URL(string: "https://image.tmdb.org/t/p/w500\(dto.poster_path!)") : nil
        let backdrop: URL? = dto.backdrop_path != nil ? URL(string: "https://image.tmdb.org/t/p/w1280\(dto.backdrop_path!)") : poster
        let logo: URL? = dto.backdrop_path != nil ? URL(string: "https://image.tmdb.org/t/p/w500\(dto.backdrop_path!)") : nil
        
        // Sample video stream URLs for playback demonstration
        let sampleStreams = [
            "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
            "https://vjs.zencdn.net/v/oceans.mp4",
            "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
            "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8",
            "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        ]
        let streamIndex = abs(dto.id) % sampleStreams.count
        let streamURL = URL(string: sampleStreams[streamIndex])!
        
        let genres = dto.genre_ids?.map { mapGenreIdToString($0) } ?? ["Movie"]
        let ratingStr = dto.vote_average != nil ? String(format: "%.1f ★", dto.vote_average!) : "PG-13"
        
        return MediaItem(
            id: "\(dto.id)",
            title: title,
            subtitle: "\(year) • \(genres.first ?? "Feature")",
            description: dto.overview?.isEmpty == false ? dto.overview! : "No overview available for this title.",
            posterURL: poster,
            backdropURL: backdrop,
            logoURL: logo,
            streamURL: streamURL,
            durationSeconds: 7200,
            rating: ratingStr,
            releaseYear: year.isEmpty ? "2024" : year,
            genres: genres.isEmpty ? ["Movie"] : genres,
            isHDR: (dto.vote_average ?? 0) >= 7.0,
            is4K: true
        )
    }
    
    private static func mapGenreIdToString(_ id: Int) -> String {
        switch id {
        case 28, 10759: return "Action"
        case 12: return "Adventure"
        case 16: return "Animation"
        case 35: return "Comedy"
        case 80: return "Crime"
        case 99: return "Documentary"
        case 18: return "Drama"
        case 10751, 10762: return "Family"
        case 14, 10765: return "Fantasy"
        case 36: return "History"
        case 27: return "Horror"
        case 9648: return "Mystery"
        case 10749: return "Romance"
        case 878: return "Sci-Fi"
        case 53: return "Thriller"
        default: return "Movie"
        }
    }
}

// MARK: - Stream Options & Cast Helpers
extension MediaItem {
    public var streamOptions: [StreamOption] {
        return [
            StreamOption(
                id: "\(id)-4k",
                quality: "4K UHD 2160p",
                resolution: "3840x2160",
                codec: "HEVC • HDR10+",
                audio: "Dolby Atmos 7.1",
                size: "14.8 GB",
                seeders: 284,
                leechers: 19,
                provider: "⚡️ Real-Debrid CDN",
                streamURL: streamURL,
                magnetURL: "magnet:?xt=urn:btih:\(id.hashValue)4k&dn=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "media")"
            ),
            StreamOption(
                id: "\(id)-1080p",
                quality: "1080p Full HD",
                resolution: "1920x1080",
                codec: "HEVC • 10-Bit",
                audio: "EAC3 5.1",
                size: "4.8 GB",
                seeders: 165,
                leechers: 12,
                provider: "⚡️ Real-Debrid CDN",
                streamURL: streamURL,
                magnetURL: "magnet:?xt=urn:btih:\(id.hashValue)1080p&dn=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "media")"
            ),
            StreamOption(
                id: "\(id)-720p",
                quality: "720p HD Compact",
                resolution: "1280x720",
                codec: "H.264 / AVC",
                audio: "AAC 2.0",
                size: "1.9 GB",
                seeders: 58,
                leechers: 4,
                provider: "🔄 Torrentio P2P",
                streamURL: streamURL,
                magnetURL: "magnet:?xt=urn:btih:\(id.hashValue)720p&dn=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "media")"
            )
        ]
    }
    
    public var castMembers: [CastMember] {
        return []
    }
}

// MARK: - Mock Data Preview Sample
extension MediaItem {
    public static let sampleHero = MediaItem(
        id: "hero-1",
        title: "Cyberpunk: Edgerunners",
        subtitle: "Night City Odyssey",
        description: "A street kid trying to survive in a technology and body modification-obsessed city of the future. Having everything to lose, he chooses to stay alive by becoming an edgerunner.",
        posterURL: URL(string: "https://image.tmdb.org/t/p/w500/vTEm9iZ6pG33P7f21151.jpg"),
        backdropURL: URL(string: "https://image.tmdb.org/t/p/original/s16o5UdP1V2aY7G.jpg"),
        streamURL: URL(string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")!,
        durationSeconds: 7320,
        rating: "TV-MA",
        releaseYear: "2024",
        genres: ["Sci-Fi", "Action", "Cyberpunk"],
        isHDR: true,
        is4K: true
    )
    
    public static let sampleRailItems: [MediaItem] = [
        MediaItem(
            id: "m-1",
            title: "Tears of Steel",
            subtitle: "VFX Sci-Fi Short",
            description: "Exploring dystopian Amsterdam with open source high definition render engine technology.",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/6KErc22tJLwImfD1H12.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/6KErc22tJLwImfD1H12.jpg"),
            streamURL: URL(string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")!,
            durationSeconds: 734,
            rating: "PG-13",
            releaseYear: "2023",
            genres: ["Sci-Fi", "Short"],
            isHDR: true,
            is4K: true
        ),
        MediaItem(
            id: "m-2",
            title: "Oceans",
            subtitle: "Nature Documentary",
            description: "Journey into the depths of the ocean and witness marine wildlife like never before.",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/sintel.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/sintel_bg.jpg"),
            streamURL: URL(string: "https://vjs.zencdn.net/v/oceans.mp4")!,
            durationSeconds: 888,
            rating: "G",
            releaseYear: "2023",
            genres: ["Documentary", "Nature"],
            isHDR: false,
            is4K: true
        ),
        MediaItem(
            id: "m-3",
            title: "Big Buck Bunny",
            subtitle: "Animation Classic",
            description: "A large and lovable rabbit takes revenge on bullying rodents.",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/bbb.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/bbb_bg.jpg"),
            streamURL: URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!,
            durationSeconds: 596,
            rating: "G",
            releaseYear: "2022",
            genres: ["Animation", "Comedy"],
            isHDR: false,
            is4K: false
        )
    ]
}

