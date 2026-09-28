//
//  SubtitleCustomizerModal.swift
//  Aura
//
//  Netflix-style subtitle appearance and audio sync offset customizer.
//

import SwiftUI

public struct SubtitleCustomizerModal: View {
    @Binding public var config: SubtitleStyleConfig
    public var onClose: () -> Void
    
    public init(config: Binding<SubtitleStyleConfig>, onClose: @escaping () -> Void) {
        self._config = config
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                Text("Subtitle Appearance & Sync")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Live Preview Card
            VStack(spacing: 8) {
                Text("LIVE PREVIEW")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.12))
                        .frame(height: 70)
                    
                    Text("The universe is full of magical things.")
                        .font(.system(size: config.fontSize * CGFloat(config.fontScale), weight: .bold))
                        .foregroundColor(config.textColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(config.backgroundOpacity))
                        .cornerRadius(4)
                        .shadow(color: config.hasShadow ? Color.black.opacity(0.9) : Color.clear, radius: 3, x: 1, y: 1)
                }
            }
            .padding(.bottom, 4)
            
            // Presets Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("PRESETS")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(SubtitlePreset.allCases) { preset in
                        Button(action: {
                            config.preset = preset
                            config.textColorHex = preset.textColorHex
                            config.backgroundOpacity = preset.boxOpacity
                        }) {
                            Text(preset.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    config.preset == preset
                                        ? Color(red: 184/255, green: 119/255, blue: 255/255)
                                        : Color.white.opacity(0.1)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Font Scale Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("FONT SIZE")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(config.fontScale * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color(red: 184/255, green: 119/255, blue: 255/255))
                }
                
                Slider(value: $config.fontScale, in: 0.7...1.6, step: 0.05)
                    .accentColor(Color(red: 184/255, green: 119/255, blue: 255/255))
            }
            
            // Subtitle Delay Offset Nudge
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("SUBTITLE SYNC OFFSET")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%+.1fs", config.offsetSeconds))
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color(red: 184/255, green: 119/255, blue: 255/255))
                }
                
                HStack(spacing: 8) {
                    Button(action: { config.offsetSeconds -= 0.5 }) {
                        Text("-0.5s")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { config.offsetSeconds -= 0.1 }) {
                        Text("-0.1s")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { config.offsetSeconds = 0.0 }) {
                        Text("Reset (0.0s)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { config.offsetSeconds += 0.1 }) {
                        Text("+0.1s")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { config.offsetSeconds += 0.5 }) {
                        Text("+0.5s")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .frame(width: 440)
        .background(
            Color.black.opacity(0.92)
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 24, x: 0, y: 8)
    }
}
