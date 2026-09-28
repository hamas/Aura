//
//  SmartSkipButton.swift
//  Aura
//
//  Netflix-style frosted glass button for skipping intros, recaps, and previews.
//

import SwiftUI

public struct SmartSkipButton: View {
    public let interval: MediaInterval
    public let onSkip: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(interval: MediaInterval, onSkip: @escaping () -> Void) {
        self.interval = interval
        self.onSkip = onSkip
    }
    
    public var body: some View {
        Button(action: onSkip) {
            HStack(spacing: 8) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Text(interval.type.label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    Color.black.opacity(isHovered ? 0.85 : 0.65)
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(isHovered ? 0.6 : 0.25), lineWidth: 1.2)
                }
            )
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
