//
//  OfflineVaultManager.swift
//  Aura
//
//  Sandboxed background offline download engine and storage manager for macOS.
//

import Foundation
import Combine

public struct DownloadItemRecord: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let posterURL: URL?
    public let localFilePath: String
    public var progress: Double
    public var downloadSpeedMBps: Double
    public var isCompleted: Bool
    public var totalSizeBytes: Int64
    public var downloadedBytes: Int64
    
    public init(
        id: String,
        title: String,
        subtitle: String,
        posterURL: URL?,
        localFilePath: String,
        progress: Double = 0.0,
        downloadSpeedMBps: Double = 0.0,
        isCompleted: Bool = false,
        totalSizeBytes: Int64 = 1024 * 1024 * 800,
        downloadedBytes: Int64 = 0
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.posterURL = posterURL
        self.localFilePath = localFilePath
        self.progress = progress
        self.downloadSpeedMBps = downloadSpeedMBps
        self.isCompleted = isCompleted
        self.totalSizeBytes = totalSizeBytes
        self.downloadedBytes = downloadedBytes
    }
    
    public var formattedSpeed: String {
        return String(format: "%.1f MB/s", downloadSpeedMBps)
    }
}

@MainActor
public final class OfflineVaultManager: ObservableObject {
    public static let shared = OfflineVaultManager()
    
    @Published public var downloads: [DownloadItemRecord] = []
    @Published public var isDownloading: Bool = false
    @Published public var smartDownloadsEnabled: Bool = true
    
    private let fileManager = FileManager.default
    public var vaultDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vault = appSupport.appendingPathComponent("Aura/AuraVault", isDirectory: true)
        if !fileManager.fileExists(atPath: vault.path) {
            try? fileManager.createDirectory(at: vault, withIntermediateDirectories: true)
        }
        return vault
    }
    
    private init() {
        // Load initial records
        loadSampleDownloads()
    }
    
    public func startDownload(item: MediaItem) {
        let sanitized = item.title.replacingOccurrences(of: "[^a-zA-Z0-9_.-]", with: "_", options: .regularExpression)
        let destinationURL = vaultDirectoryURL.appendingPathComponent("\(sanitized).mp4")
        
        let record = DownloadItemRecord(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            posterURL: item.highDefPosterURL ?? item.posterURL,
            localFilePath: destinationURL.path,
            progress: 0.05,
            downloadSpeedMBps: 14.8,
            isCompleted: false
        )
        downloads.insert(record, at: 0)
        isDownloading = true
        
        print("💾 [VAULT] Initiating background download for '\(item.title)' to \(destinationURL.path)")
        
        // Simulate high-speed download progress
        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if let idx = self.downloads.firstIndex(where: { $0.id == item.id }) {
                    self.downloads[idx].progress = Double(i) / 10.0
                    self.downloads[idx].downloadedBytes = Int64(Double(self.downloads[idx].totalSizeBytes) * (Double(i) / 10.0))
                    if i == 10 {
                        self.downloads[idx].isCompleted = true
                        self.downloads[idx].downloadSpeedMBps = 0.0
                        print("✅ [VAULT] Download complete for '\(item.title)'!")
                    }
                }
            }
            self.isDownloading = self.downloads.contains(where: { !$0.isCompleted })
        }
    }
    
    public func deleteDownload(id: String) {
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            let path = downloads[idx].localFilePath
            try? fileManager.removeItem(atPath: path)
            downloads.remove(at: idx)
            print("🗑️ [VAULT] Deleted download item: \(id)")
        }
    }
    
    public func isItemDownloaded(_ id: String) -> Bool {
        downloads.contains(where: { $0.id == id && $0.isCompleted })
    }
    
    public func isItemDownloading(_ id: String) -> Bool {
        downloads.contains(where: { $0.id == id && !$0.isCompleted })
    }
    
    private func loadSampleDownloads() {
        let sample = DownloadItemRecord(
            id: "m-1",
            title: "Tears of Steel",
            subtitle: "1080p Full HD",
            posterURL: URL(string: "https://image.tmdb.org/t/p/w500/6KErc22tJLwImfD1H12.jpg"),
            localFilePath: vaultDirectoryURL.appendingPathComponent("Tears_of_Steel.mp4").path,
            progress: 1.0,
            downloadSpeedMBps: 0.0,
            isCompleted: true,
            totalSizeBytes: 1024 * 1024 * 650,
            downloadedBytes: 1024 * 1024 * 650
        )
        self.downloads = [sample]
    }
}
