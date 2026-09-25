//
//  AddonsView.swift
//  Aura
//
//  Addons, Community Extensions & Media Provider Catalogs.
//

import SwiftUI

public struct AddonItem: Identifiable {
    public let id = UUID()
    public let name: String
    public let version: String
    public let description: String
    public let iconName: String
    public var isInstalled: Bool
}

public struct AddonsView: View {
    @State private var addons: [AddonItem] = [
        AddonItem(name: "Stremio Cinemeta Catalog", version: "v3.0.4", description: "Official movie and series metadata provider with IMDb/TMDB ratings.", iconName: "film.stack.fill", isInstalled: true),
        AddonItem(name: "Aura Debrid Engine", version: "v2.1.0", description: "High-speed multi-threaded Debrid stream resolver for 4K HDR cache.", iconName: "bolt.horizontal.fill", isInstalled: true),
        AddonItem(name: "OpenSubtitles v3", version: "v1.8.2", description: "Multi-language automated subtitle downloader and sync offset engine.", iconName: "captions.bubble.fill", isInstalled: true),
        AddonItem(name: "AnimeKitsu Provider", version: "v1.2.0", description: "Anime catalog scraper and episode release tracker.", iconName: "sparkles.tv.fill", isInstalled: false)
    ]
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Addons & Providers")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    
                    Text("Manage community extensions, metadata resolvers, and streaming backends.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                VStack(spacing: 14) {
                    ForEach($addons) { $addon in
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: addon.iconName)
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(addon.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(addon.version)
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(addon.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                addon.isInstalled.toggle()
                            }) {
                                Text(addon.isInstalled ? "Configured" : "Install")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(
                                        Group {
                                            if addon.isInstalled {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .fill(Color.white.opacity(0.12))
                                            } else {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .fill(Color.white.opacity(0.25))
                                            }
                                        }
                                    )
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(16)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview("Addons View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        AddonsView()
    }
}
