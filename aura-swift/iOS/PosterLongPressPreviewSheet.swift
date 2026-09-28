//
//  PosterLongPressPreviewSheet.swift
//  Aura (iOS target)
//
//  Netflix-grade 3D Touch / Haptic Long-Press quick-action preview modal.
//

import SwiftUI

#if os(iOS)
import UIKit

public struct PosterLongPressPreviewSheet: View {
    public let item: MediaItem
    public let onPlay: () -> Void
    public let onSelect: () -> Void
    public let onDismiss: () -> Void
    
    @ObservedObject private var dataStore = AuraDataStore.shared
    @ObservedObject private var vaultManager = OfflineVaultManager.shared
    
    public init(
        item: MediaItem,
        onPlay: @escaping () -> Void,
        onSelect: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.item = item
        self.onPlay = onPlay
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            backdropHeader
            overviewText
            actionButtonsRow
        }
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.7), radius: 30, x: 0, y: 15)
        .padding(20)
    }
    
    private var backdropHeader: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: item.highDefBackdropURL ?? item.backdropURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color(white: 0.12))
                        .aspectRatio(16/9, contentMode: .fit)
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()
            
            LinearGradient(
                colors: [.clear, .black.opacity(0.85), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(alignment: .leading, spacing: 6) {
                if let clearart = item.clearartURL {
                    AsyncImage(url: clearart) { phase in
                        if let img = phase.image {
                            img.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 44)
                        } else {
                            fallbackTitle
                        }
                    }
                } else {
                    fallbackTitle
                }
                
                metadataBadgesRow
            }
            .padding(16)
        }
    }
    
    private var metadataBadgesRow: some View {
        HStack(spacing: 8) {
            Text("\(item.matchScore)% Match")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.green)
            
            Text(item.releaseYear)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text(item.certification)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 3))
            
            Text("4K UHD")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }
    
    private var overviewText: some View {
        Text(item.description.isEmpty ? "Stream now in ultra-high definition with multi-audio surround sound." : item.description)
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.8))
            .lineLimit(3)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            Button(action: {
                iOSHapticsManager.shared.triggerImpact(.medium)
                onDismiss()
                onPlay()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Play")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            
            ActionButton(
                icon: dataStore.isInWatchlist(item) ? "checkmark" : "plus",
                label: "My List",
                isActive: dataStore.isInWatchlist(item)
            ) {
                iOSHapticsManager.shared.triggerImpact(.light)
                dataStore.toggleWatchlist(item)
            }
            
            ActionButton(
                icon: vaultManager.isItemDownloaded(item.id) ? "checkmark.circle.fill" : "arrow.down.to.line",
                label: "Download",
                isActive: vaultManager.isItemDownloaded(item.id)
            ) {
                iOSHapticsManager.shared.triggerImpact(.light)
                vaultManager.startDownload(item: item)
            }
            
            ActionButton(icon: "square.and.arrow.up", label: "Share") {
                iOSHapticsManager.shared.triggerImpact(.light)
                presentShareSheet()
            }
            
            ActionButton(icon: "info.circle", label: "Details") {
                iOSHapticsManager.shared.triggerImpact(.light)
                onDismiss()
                onSelect()
            }
        }
        .padding(16)
    }
    
    private var fallbackTitle: some View {
        Text(item.title)
            .font(.system(size: 20, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .lineLimit(1)
    }
    
    private func presentShareSheet() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let shareText = "Watching \(item.title) on Aura!"
        let av = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        rootVC.present(av, animated: true)
    }
}

private struct ActionButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isActive ? .yellow : .white)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 52, height: 48)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
#endif
