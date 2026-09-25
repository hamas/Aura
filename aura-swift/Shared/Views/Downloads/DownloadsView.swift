//
//  DownloadsView.swift
//  Aura
//
//  Offline Downloads Manager & Storage Usage View.
//

import SwiftUI

public struct DownloadItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let quality: String
    public let sizeMB: Double
    public var progress: Double
    public var isCompleted: Bool
    public var mediaItem: MediaItem
}

public struct DownloadsView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @State private var downloads: [DownloadItem] = [
        DownloadItem(title: "Cyberpunk: Edgerunners S1:E1", quality: "4K HDR • AV1", sizeMB: 1850.0, progress: 1.0, isCompleted: true, mediaItem: MediaItem.sampleRailItems[1]),
        DownloadItem(title: "Dune: Part Two", quality: "4K Dolby Vision • HEVC", sizeMB: 14200.0, progress: 0.74, isCompleted: false, mediaItem: MediaItem.sampleHero),
        DownloadItem(title: "Arcane S2:E3", quality: "1080p 60fps", sizeMB: 840.0, progress: 0.35, isCompleted: false, mediaItem: MediaItem.sampleRailItems[0])
    ]
    @State private var storageUsedGB: Double = 16.89
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Title Header & Storage Meter Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Offline Downloads")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if !downloads.isEmpty {
                            Button("Clear All") {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    downloads.removeAll()
                                    storageUsedGB = 0
                                }
                            }
                            .font(.caption.weight(.bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Capsule())
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Storage Gauge Card
                    HStack(spacing: 16) {
                        Image(systemName: "internaldrive.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.9))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Offline Storage Vault")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(String(format: "%.2f GB of 512 GB Used", storageUsedGB))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: storageUsedGB, total: 512.0)
                                .accentColor(Color(red: 255/255, green: 45/255, blue: 85/255))
                        }
                    }
                    .padding(18)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Downloads Item List
                VStack(alignment: .leading, spacing: 14) {
                    Text("ACTIVE & COMPLETED DOWNLOADS")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    
                    if downloads.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary)
                            Text("No Offline Downloads")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Downloaded movies and episodes will appear here for offline playback.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 12) {
                            ForEach($downloads) { $item in
                                HStack(spacing: 14) {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(item.isCompleted ? .green : Color(red: 0/255, green: 122/255, blue: 255/255))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white)
                                        
                                        HStack(spacing: 8) {
                                            Text(item.quality)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("•")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(String(format: "%.1f MB", item.sizeMB))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if !item.isCompleted {
                                            ProgressView(value: item.progress)
                                                .accentColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                                                .padding(.top, 4)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if item.isCompleted {
                                        Button(action: {
                                            playerManager.loadMedia(item.mediaItem)
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "play.fill")
                                                Text("Play Offline")
                                            }
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(Color.white)
                                            .clipShape(Capsule())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if let idx = downloads.firstIndex(where: { $0.id == item.id }) {
                                                downloads.remove(at: idx)
                                            }
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.subheadline)
                                            .foregroundColor(.red.opacity(0.8))
                                            .padding(6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(16)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview("Downloads View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        DownloadsView()
    }
}
