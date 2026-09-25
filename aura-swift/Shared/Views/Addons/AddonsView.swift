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
    public let manifestURL: String
    public var isInstalled: Bool
}

public struct AddonsView: View {
    @State private var customManifestURL: String = ""
    @State private var installMessage: String = ""
    @State private var addons: [AddonItem] = [
        AddonItem(name: "Torrentio Provider", version: "v0.0.14", description: "Scrapes movie & series torrent streams from public indexes with Debrid cache support.", iconName: "bolt.horizontal.fill", manifestURL: "https://torrentio.strem.fun/manifest.json", isInstalled: true),
        AddonItem(name: "Stremio Cinemeta Catalog", version: "v3.0.4", description: "Official movie and series metadata provider with IMDb/TMDB ratings & clearart logos.", iconName: "film.stack.fill", manifestURL: "https://v3-cinemeta.strem.io/manifest.json", isInstalled: true),
        AddonItem(name: "OpenSubtitles v3", version: "v1.8.2", description: "Multi-language automated subtitle downloader and sync offset engine.", iconName: "captions.bubble.fill", manifestURL: "https://opensubtitles.strem.fun/manifest.json", isInstalled: true),
        AddonItem(name: "CyberFlix Catalog", version: "v1.4.1", description: "Extended Netflix, Disney+, Apple TV+, and HBO Max discovery catalogs.", iconName: "tv.fill", manifestURL: "https://cyberflix.strem.fun/manifest.json", isInstalled: true),
        AddonItem(name: "AnimeKitsu Provider", version: "v1.2.0", description: "Anime catalog scraper and episode release tracker.", iconName: "sparkles.tv.fill", manifestURL: "https://kitsu.strem.fun/manifest.json", isInstalled: false)
    ]
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Title Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add-ons & Provider Hub")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    
                    Text("Manage Stremio v3 manifest extensions, community stream scrapers, and metadata resolvers.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // 1. Install Custom Manifest URL Input Bar
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "link.badge.plus")
                            .font(.title3)
                            .foregroundColor(Color(red: 255/255, green: 45/255, blue: 85/255))
                        Text("Install Custom Add-on URL")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Paste Stremio manifest.json HTTPS URL...", text: $customManifestURL)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Button("Install") {
                            installCustomAddon()
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .buttonStyle(PlainButtonStyle())
                        .disabled(customManifestURL.isEmpty)
                    }
                    
                    if !installMessage.isEmpty {
                        Text(installMessage)
                            .font(.caption)
                            .foregroundColor(installMessage.contains("Success") ? .green : .yellow)
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                // 2. Engine Hub Status Banner
                HStack(spacing: 16) {
                    engineStatusBadge(name: "Debrid Unrestricting", status: "Active", icon: "bolt.fill", color: .green)
                    engineStatusBadge(name: "Stremio v3 Parser", status: "Online", icon: "puzzlepiece.fill", color: .blue)
                    engineStatusBadge(name: "Torrent Proxy", status: "Ready", icon: "arrow.down.circle.fill", color: .purple)
                }
                .padding(.horizontal, 24)
                
                // 3. Installed & Community Presets List
                VStack(alignment: .leading, spacing: 14) {
                    Text("COMMUNITY ADD-ONS & CATALOG PROVIDERS")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 12) {
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
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        addon.isInstalled.toggle()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: addon.isInstalled ? "checkmark.circle.fill" : "plus.circle.fill")
                                        Text(addon.isInstalled ? "Configured" : "Install")
                                    }
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Group {
                                            if addon.isInstalled {
                                                Color.white.opacity(0.12)
                                            } else {
                                                Color(red: 255/255, green: 45/255, blue: 85/255)
                                            }
                                        }
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
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
            .padding(.bottom, 40)
        }
    }
    
    private func engineStatusBadge(name: String, status: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                Text(status)
                    .font(.caption2)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private func installCustomAddon() {
        guard !customManifestURL.isEmpty else { return }
        let newAddon = AddonItem(
            name: "Custom Manifest",
            version: "v1.0.0",
            description: customManifestURL,
            iconName: "puzzlepiece.extension.fill",
            manifestURL: customManifestURL,
            isInstalled: true
        )
        addons.insert(newAddon, at: 0)
        installMessage = "Successfully installed manifest!"
        customManifestURL = ""
    }
}

#Preview("Addons View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        AddonsView()
    }
}
