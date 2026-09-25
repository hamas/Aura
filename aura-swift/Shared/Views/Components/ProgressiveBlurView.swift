//
//  ProgressiveBlurView.swift
//  Aura
//
//  Drop-in SwiftUI component for progressive gradient blur header.
//  Content scrolls underneath with increasing blur from bottom to top — like Apple Music, Photos, and App Store.
//

import SwiftUI

public struct ProgressiveBlurView: View {
    public var height: CGFloat
    public var maxBlurRadius: CGFloat
    public var gradientDirection: GradientDirection
    
    public enum GradientDirection {
        case topToBottom
        case bottomToTop
    }
    
    public init(
        height: CGFloat = 100,
        maxBlurRadius: CGFloat = 30,
        gradientDirection: GradientDirection = .bottomToTop
    ) {
        self.height = height
        self.maxBlurRadius = maxBlurRadius
        self.gradientDirection = gradientDirection
    }
    
    public var body: some View {
        ZStack {
            // Layered Stippled Blur Mask Stack (Smooth cubic progressive transition)
            ForEach(0..<8, id: \.self) { index in
                let progress = CGFloat(index + 1) / 8.0
                let blurRadius = maxBlurRadius * pow(progress, 1.4)
                
                let startStop = CGFloat(index) / 8.0
                let endStop = CGFloat(index + 1) / 8.0
                
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .blur(radius: blurRadius)
                    .mask(
                        LinearGradient(
                            colors: gradientDirection == .bottomToTop ?
                                [.clear, .black.opacity(Double(progress))] : [.black.opacity(Double(progress)), .clear],
                            startPoint: gradientDirection == .bottomToTop ?
                                UnitPoint(x: 0.5, y: startStop) : UnitPoint(x: 0.5, y: 1.0 - endStop),
                            endPoint: gradientDirection == .bottomToTop ?
                                UnitPoint(x: 0.5, y: endStop) : UnitPoint(x: 0.5, y: 1.0 - startStop)
                        )
                    )
            }
            
            // Subtle ambient dark tint overlay for seamless contrast
            LinearGradient(
                colors: [
                    Color(red: 13/255, green: 14/255, blue: 18/255).opacity(0.85),
                    Color(red: 13/255, green: 14/255, blue: 18/255).opacity(0.4),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }
}

public struct ProgressiveBlurHeader<Content: View>: View {
    public var height: CGFloat
    public var content: () -> Content
    
    public init(height: CGFloat = 90, @ViewBuilder content: @escaping () -> Content) {
        self.height = height
        self.content = content
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            ProgressiveBlurView(height: height)
                .ignoresSafeArea(.all, edges: .top)
            
            content()
        }
    }
}

#Preview("Progressive Blur Header") {
    ZStack(alignment: .top) {
        Color.black.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<20) { i in
                    Text("Scroll Content Item \(i)")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(12)
                }
            }
            .padding(.top, 100)
            .padding(.horizontal)
        }
        
        ProgressiveBlurHeader(height: 90) {
            HStack {
                Text("Aura")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
        }
    }
}
