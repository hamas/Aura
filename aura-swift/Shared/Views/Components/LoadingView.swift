//
//  LoadingView.swift
//  Aura
//
//  Reusable loading indicator view component.
//

import SwiftUI

public struct LoadingView: View {
    let title: String?
    let minHeight: CGFloat
    
    public init(title: String? = nil, minHeight: CGFloat = 300) {
        self.title = title
        self.minHeight = minHeight
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .accentColor(.white)
            
            if let title = title {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
    }
}
