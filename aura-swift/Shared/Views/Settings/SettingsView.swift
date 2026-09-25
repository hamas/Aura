//
//  SettingsView.swift
//  Aura
//
//  Apple HIG Native Settings View (Playback Engine, Debrid, Aesthetics).
//

import SwiftUI

public struct SettingsView: View {
    @AppStorage("hardwareAcceleration") private var hardwareAcceleration: Bool = true
    @AppStorage("debridAccountEnabled") private var debridAccountEnabled: Bool = true
    @AppStorage("subtitleLanguage") private var subtitleLanguage: String = "English"
    @AppStorage("autoPlayNextEpisode") private var autoPlayNextEpisode: Bool = true
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    Text("Configure video playback, audio session, cloud sync, and HIG appearance.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    // Playback Engine Settings Group
                    SettingsSectionCard(title: "PLAYBACK & DECODE ENGINE", iconName: "play.tv.fill") {
                        Toggle("Hardware Accelerated Decoding (Metal / VideoToolbox)", isOn: $hardwareAcceleration)
                        Divider().background(Color.white.opacity(0.08))
                        Toggle("Auto-Play Next Episode", isOn: $autoPlayNextEpisode)
                    }
                    
                    // Cloud & Accounts Group
                    SettingsSectionCard(title: "DEBRID & METADATA ACCOUNTS", iconName: "cloud.fill") {
                        Toggle("Real-Debrid / Premiumize High-Speed Cache Sync", isOn: $debridAccountEnabled)
                    }
                    
                    // Subtitles & Audio Group
                    SettingsSectionCard(title: "SUBTITLES & AUDIO ENHANCER", iconName: "captions.bubble.fill") {
                        HStack {
                            Text("Preferred Subtitle Language")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $subtitleLanguage) {
                                Text("English").tag("English")
                                Text("Spanish").tag("Spanish")
                                Text("French").tag("French")
                                Text("German").tag("German")
                                Text("Japanese").tag("Japanese")
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
    }
}

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let iconName: String
    let content: Content
    
    init(title: String, iconName: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.iconName = iconName
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundColor(.white.opacity(0.85))
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                content
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
}

#Preview("Settings View") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        SettingsView()
    }
}
