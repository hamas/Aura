//
//  iOSSmartDownloadSettingsModal.swift
//  Aura (iOS target)
//
//  Netflix Smart Downloads configuration & storage gauge manager.
//

import SwiftUI

#if os(iOS)
public struct iOSSmartDownloadSettingsModal: View {
    @ObservedObject private var vaultManager = OfflineVaultManager.shared
    @AppStorage("aura_smart_downloads_enabled") private var smartDownloadsEnabled: Bool = true
    @AppStorage("aura_wifi_only_downloads") private var wifiOnlyEnabled: Bool = true
    @AppStorage("aura_download_quality") private var downloadQuality: String = "1080p HD"
    
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Storage Breakdown Gauge Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("DEVICE STORAGE BREAKDOWN")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                            
                            // Multi-segment Bar
                            GeometryReader { geo in
                                HStack(spacing: 3) {
                                    // Aura Downloads (15%)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.purple)
                                        .frame(width: geo.size.width * 0.18)
                                    
                                    // System & Apps (52%)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: geo.size.width * 0.52)
                                    
                                    // Free Space (30%)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.green)
                                        .frame(width: geo.size.width * 0.30)
                                }
                            }
                            .frame(height: 12)
                            
                            // Legend
                            HStack(spacing: 16) {
                                StorageLegendItem(color: .purple, label: "Aura (4.2 GB)")
                                StorageLegendItem(color: .white.opacity(0.4), label: "Other Apps (64 GB)")
                                StorageLegendItem(color: .green, label: "Free (42 GB)")
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(white: 0.10))
                        )
                        
                        // Smart Downloads Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SMART DOWNLOAD AUTOMATION")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Toggle(isOn: $smartDownloadsEnabled) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Download Next Episode")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Automatically downloads the next episode when the current one is finished and deletes the watched file.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .tint(.purple)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Toggle(isOn: $wifiOnlyEnabled) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Download on Wi-Fi Only")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Prevents using cellular mobile data for large video downloads.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .tint(.purple)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(white: 0.10))
                        )
                        
                        // Quality Preference Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("DOWNLOAD VIDEO QUALITY")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Picker("Video Quality", selection: $downloadQuality) {
                                Text("Standard (720p)").tag("720p")
                                Text("High Definition (1080p)").tag("1080p HD")
                                Text("Ultra HD 4K (When available)").tag("4K UHD")
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(white: 0.10))
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Smart Downloads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        iOSHapticsManager.shared.triggerImpact(.light)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
    }
}

private struct StorageLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
#endif
