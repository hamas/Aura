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
    public let progress: Double
    public let isCompleted: Bool
}

public struct DownloadsView: View {
    @State private var downloads: [DownloadItem] = [
        DownloadItem(title: "Cyberpunk: Edgerunners S1:E1", quality: "4K HDR • AV1", sizeMB: 1850.0, progress: 1.0, isCompleted: true),
        DownloadItem(title: "Dune: Part Two", quality: "4K Dolby Vision • HEVC", sizeMB: 14200.0, progress: 0.74, isCompleted: false),
        DownloadItem(title: "Arcane S2:E3", quality: "1080p 60fps", sizeMB: 840.0, progress: 0.35, isCompleted: false)
    ]
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Title Header & Storage Meter Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Offline Downloads")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    
                    // Storage Gauge Card
                    HStack(spacing: 16) {
                        Image(systemName: "internaldrive.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.9))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Storage Manager")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("16.89 GB of 512 GB Used")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: 16.89, total: 512.0)
                                .accentColor(.white)
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
                    
                    VStack(spacing: 12) {
                        ForEach(downloads) { item in
                            HStack(spacing: 14) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(item.isCompleted ? .green : .white.opacity(0.85))
                                
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
                                            .accentColor(.white)
                                            .padding(.top, 4)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Image(systemName: item.isCompleted ? "trash" : "pause.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(16)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
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
