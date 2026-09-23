//
//  GlassCard.swift
//  Aura
//
//  Apple HIG Liquid Glass Material & Continuous Squircle Components.
//

import SwiftUI

public struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double
    var strokeColor: Color
    
    public init(cornerRadius: CGFloat = 18, opacity: Double = 0.65, strokeColor: Color = Color.white.opacity(0.18)) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.strokeColor = strokeColor
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                strokeColor,
                                strokeColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

extension View {
    public func liquidGlass(
        cornerRadius: CGFloat = 18,
        opacity: Double = 0.65,
        strokeColor: Color = Color.white.opacity(0.18)
    ) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, opacity: opacity, strokeColor: strokeColor))
    }
}

public struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content
    
    public init(cornerRadius: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .liquidGlass(cornerRadius: cornerRadius)
    }
}
