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
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isPrimary ? .black : .white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isPrimary {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
