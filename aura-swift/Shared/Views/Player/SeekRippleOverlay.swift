//
//  SeekRippleOverlay.swift
//  Aura
//
//  Curved animated chevron seek ripple overlay for keyboard arrow navigation.
//

import SwiftUI

public struct SeekRippleOverlay: View {
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
    
    private var isForward: Bool {
        return !text.contains("-")
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            if !isForward {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 26, weight: .bold))
            }
            
            Text(text)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            if isForward {
                Image(systemName: "goforward.10")
                    .font(.system(size: 26, weight: .bold))
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.8)
        )
        .foregroundColor(.white)
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 4)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
}
