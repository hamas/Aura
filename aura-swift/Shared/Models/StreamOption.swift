//
//  StreamOption.swift
//  Aura
//
//  Model representing stream quality options, torrent seeders/leechers, resolution and provider info.
//

import Foundation

public struct StreamOption: Identifiable, Hashable, Codable {
    public let id: String
    public let quality: String // e.g. "4K REMUX 2160p", "1080p Web-DL", "720p HD"
    public let resolution: String // e.g. "3840x2160"
    public let codec: String // e.g. "HEVC / Main 10 HDR"
    public let audio: String // e.g. "Dolby Atmos 7.1"
    public let size: String // e.g. "48.2 GB"
    public let seeders: Int
    public let leechers: Int
    public let provider: String // e.g. "⚡️ Real-Debrid CDN", "🔄 P2P Swarm"
    public let streamURL: URL
    public let magnetURL: String?
    
    public init(
        id: String,
        quality: String,
        resolution: String,
        codec: String,
        audio: String,
        size: String,
        seeders: Int,
        leechers: Int,
        provider: String,
        streamURL: URL,
        magnetURL: String? = nil
    ) {
        self.id = id
        self.quality = quality
        self.resolution = resolution
        self.codec = codec
        self.audio = audio
        self.size = size
        self.seeders = seeders
        self.leechers = leechers
        self.provider = provider
        self.streamURL = streamURL
        self.magnetURL = magnetURL
    }
}
