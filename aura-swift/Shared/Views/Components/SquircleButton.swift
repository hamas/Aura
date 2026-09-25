//
//  SquircleButton.swift
//  Aura
//
//  Custom Apple HIG Squircle Action Button with micro-animations & haptics.
//

import SwiftUI

public struct SquircleButton: View {
    let title: String
    let iconName: String?
    let isPrimary: Bool
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    @State private var isHovered: Bool = false
    
    public init(
        title: String,
        iconName: String? = nil,
        isPrimary: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.isPrimary = isPrimary
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            #if os(iOS)
            iOSHapticsManager.shared.triggerImpact(.light)
            #endif
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.bold))
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(isPrimary ? .black : .white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isPrimary {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isHovered ? Color.white.opacity(0.92) : Color.white)
                            .shadow(color: Color.white.opacity(isHovered ? 0.25 : 0.0), radius: 10, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isHovered ? .regularMaterial : .thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                isHovered ? Color.white.opacity(0.4) : Color.white.opacity(0.2),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            )
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.03 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
    }
}

#Preview("Squircle Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 16) {
            SquircleButton(title: "Play Now", iconName: "play.fill", isPrimary: true) {}
            SquircleButton(title: "Watch Trailer", iconName: "film", isPrimary: false) {}
        }
        .padding()
    }
}


