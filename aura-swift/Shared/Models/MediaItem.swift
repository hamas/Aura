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
        self.streamURL = streamURL
        self.durationSeconds = durationSeconds
        self.rating = rating
        self.releaseYear = releaseYear
        self.genres = genres
        self.isHDR = isHDR
        self.is4K = is4K
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
        streamURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4")!,
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
            streamURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4")!,
            durationSeconds: 734,
            rating: "PG-13",
            releaseYear: "2023",
            genres: ["Sci-Fi", "Short"],
            isHDR: true,
            is4K: true
        ),
        MediaItem(
            id: "m-2",
            title: "Sintel",
            subtitle: "The Dragon Quest",
            description: "A lonely young woman searches for a baby dragon she nursed back to health.",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/sintel.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/sintel_bg.jpg"),
            streamURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4")!,
            durationSeconds: 888,
            rating: "PG",
            releaseYear: "2023",
            genres: ["Fantasy", "Animation"],
            isHDR: false,
            is4K: true
        ),
        MediaItem(
            id: "m-3",
            title: "Big Buck Bunny",
            subtitle: "Forest Tales",
            description: "A large and lovable rabbit takes revenge on bullying rodents.",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/bbb.jpg"),
            backdropURL: URL(string: "https://image.tmdb.org/t/p/w1280/bbb_bg.jpg"),
            streamURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
            durationSeconds: 596,
            rating: "G",
            releaseYear: "2022",
            genres: ["Animation", "Comedy"],
            isHDR: false,
            is4K: false
        )
    ]
}
