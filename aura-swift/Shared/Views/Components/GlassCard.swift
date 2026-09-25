//
//  GlassCard.swift
//  Aura
//
//  Apple HIG Neutral Material & Continuous Squircle Components.
//

import SwiftUI

public struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double
    var strokeColor: Color
    var material: Material
    
    @State private var isHovered: Bool = false
    
    public init(
        cornerRadius: CGFloat = 12,
        opacity: Double = 0.75,
        strokeColor: Color = Color.white.opacity(0.08),
        material: Material = .ultraThinMaterial
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.strokeColor = strokeColor
        self.material = material
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                Rectangle()
                    .fill(material)
                    .opacity(opacity)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isHovered ? Color.white.opacity(0.20) : strokeColor,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.30 : 0.15),
                radius: isHovered ? 14 : 8,
                x: 0,
                y: isHovered ? 6 : 4
            )
            .scaleEffect(isHovered ? 1.008 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
            #if os(macOS)
            .onHover { hovering in
                isHovered = hovering
            }
            #endif
    }
}

extension View {
    public func liquidGlass(
        cornerRadius: CGFloat = 12,
        opacity: Double = 0.75,
        strokeColor: Color = Color.white.opacity(0.08),
        material: Material = .ultraThinMaterial
    ) -> some View {
        self.modifier(
            LiquidGlassModifier(
                cornerRadius: cornerRadius,
                opacity: opacity,
                strokeColor: strokeColor,
                material: material
            )
        )
    }
}

public struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let material: Material
    let content: Content
    
    public init(
        cornerRadius: CGFloat = 12,
        material: Material = .ultraThinMaterial,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.material = material
        self.content = content()
    }
    
    public var body: some View {
        content
            .liquidGlass(cornerRadius: cornerRadius, material: material)
    }
}

#Preview("Glass Card") {
    ZStack {
        Color(red: 13/255, green: 14/255, blue: 18/255)
            .ignoresSafeArea()
        
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Native Apple HIG Surface")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Clean translucent material with 1px neutral border stroke and continuous curves.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
        }
        .padding(40)
    }
    .frame(width: 400, height: 300)
}
