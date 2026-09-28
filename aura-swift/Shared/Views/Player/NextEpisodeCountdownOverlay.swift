//
//  NextEpisodeCountdownOverlay.swift
//  Aura
//
//  Glassmorphic next-episode auto-play countdown card overlay.
//

import SwiftUI

public struct NextEpisodeCountdownOverlay: View {
    public let remainingSeconds: Int
    public let nextEpisodeTitle: String?
    public let onPlayNow: () -> Void
    public let onDismiss: () -> Void
    
    public init(
        remainingSeconds: Int,
        nextEpisodeTitle: String? = nil,
        onPlayNow: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.remainingSeconds = remainingSeconds
        self.nextEpisodeTitle = nextEpisodeTitle
        self.onPlayNow = onPlayNow
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Circular Timer Badge
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 2.5)
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(remainingSeconds) / 10.0)
                        .stroke(Color(red: 184/255, green: 119/255, blue: 255/255), lineWidth: 2.5)
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(remainingSeconds)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 184/255, green: 119/255, blue: 255/255))
                }
                
                Text("UP NEXT")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Text(nextEpisodeTitle ?? "Next Episode")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Button(action: onPlayNow) {
                HStack {
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                    Text("Play Now")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color(red: 184/255, green: 119/255, blue: 255/255))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .frame(width: 270)
        .background(
            ZStack {
                Color.black.opacity(0.85)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 184/255, green: 119/255, blue: 255/255).opacity(0.6), lineWidth: 1.5)
            }
        )
        .cornerRadius(16)
        .shadow(color: Color(red: 184/255, green: 119/255, blue: 255/255).opacity(0.25), radius: 16, x: 0, y: 4)
    }
}
