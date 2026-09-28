//
//  MobileVolumeBrightnessHUD.swift
//  Aura (iOS target)
//
//  Vertical glassmorphic volume and brightness HUD pill indicator.
//

#if os(iOS)
import SwiftUI

public enum MobileGestureHUDType {
    case brightness
    case volume
}

public struct MobileVolumeBrightnessHUD: View {
    public let type: MobileGestureHUDType
    public let value: Double // 0.0 to 1.0
    
    public init(type: MobileGestureHUDType, value: Double) {
        self.type = type
        self.value = max(0.0, min(1.0, value))
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // Vertical Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    // Background Track
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.2))
                    
                    // Fill Level
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(fillColor)
                        .frame(height: geo.size.height * CGFloat(value))
                }
            }
            .frame(width: 8, height: 120)
            
            Text("\(Int(value * 100))%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
        )
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
    
    private var iconName: String {
        switch type {
        case .brightness:
            if value > 0.7 { return "sun.max.fill" }
            if value > 0.3 { return "sun.min.fill" }
            return "sun.min"
        case .volume:
            if value > 0.6 { return "speaker.wave.3.fill" }
            if value > 0.2 { return "speaker.wave.1.fill" }
            if value > 0 { return "speaker.fill" }
            return "speaker.slash.fill"
        }
    }
    
    private var fillColor: LinearGradient {
        switch type {
        case .brightness:
            return LinearGradient(
                colors: [Color.yellow, Color.orange],
                startPoint: .bottom,
                endPoint: .top
            )
        case .volume:
            return LinearGradient(
                colors: [Color.blue, Color.cyan],
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }
}
#endif
