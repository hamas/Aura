//
//  AddonsView.swift
//  Aura
//
//  Addons, Community Extensions & Media Provider Catalogs with Stremio v3 Engine.
//

import SwiftUI

public struct AddonsView: View {
    @ObservedObject private var addonManager = StremioAddonManager.shared
    @AppStorage("realDebridApiKey") private var realDebridApiKey: String = ""
    @AppStorage("torBoxApiKey") private var torBoxApiKey: String = ""
    @State private var customManifestURL: String = ""
    
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
                        TextField("Paste Stremio manifest.json or stremio:// URL...", text: $customManifestURL)
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
                        
                        Button(action: {
                            Task {
                                let url = customManifestURL
                                let success = await addonManager.installCustomAddon(urlInput: url)
                                if success {
                                    customManifestURL = ""
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                if addonManager.isSearchingAddon {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text("Install")
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(customManifestURL.isEmpty || addonManager.isSearchingAddon)
                    }
                    
                    if !addonManager.lastStatusMessage.isEmpty {
                        Text(addonManager.lastStatusMessage)
                            .font(.caption)
                            .foregroundColor(addonManager.lastStatusMessage.contains("Successfully") ? .green : (addonManager.lastStatusMessage.contains("Failed") ? .red : .yellow))
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
                    let debridActive = !realDebridApiKey.isEmpty || !torBoxApiKey.isEmpty
                    engineStatusBadge(
                        name: "Debrid Engine",
                        status: debridActive ? "Active (\(realDebridApiKey.isEmpty ? "TorBox" : "Real-Debrid"))" : "Not Configured",
                        icon: "bolt.fill",
                        color: debridActive ? .green : .yellow
                    )
                    
                    engineStatusBadge(
                        name: "Stremio v3 Engine",
                        status: "\(addonManager.installedAddons.filter(\.isInstalled).count) Add-ons Online",
                        icon: "puzzlepiece.fill",
                        color: .blue
                    )
                    
                    engineStatusBadge(
                        name: "Torrent Proxy",
                        status: "Local Node Ready",
                        icon: "arrow.down.circle.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal, 24)
                
                // 3. Installed & Community Presets List
                VStack(alignment: .leading, spacing: 14) {
                    Text("COMMUNITY ADD-ONS & CATALOG PROVIDERS")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 12) {
                        ForEach(addonManager.installedAddons) { addon in
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.12))
                                        .frame(width: 48, height: 48)
                                    
                                    Image(systemName: addon.icon ?? "puzzlepiece.extension.fill")
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
                                        addonManager.toggleAddonInstalled(addon)
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
}

#Preview("Addons View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        AddonsView()
    }
}
