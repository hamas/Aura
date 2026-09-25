//
//  VideoPlayerView.swift
//  Aura
//
//  Hardware-accelerated Native SwiftUI Video Player wrapping AVPlayer.
//

import SwiftUI
import AVKit

public struct VideoPlayerView: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @StateObject private var pipController = PictureInPictureController()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = playerManager.player {
                AVPlayerRepresentable(player: player) { layer in
                    pipController.setup(with: layer)
                }
                .ignoresSafeArea()
                .onTapGesture {
                    playerManager.userInteractedWithHUD()
                }
            }
            
            // Buffering Spinner Indicator
            if playerManager.isBuffering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .scaleEffect(1.8)
            }
            
            // HUD Overlay (Fades out when idling to conserve screen compositor energy during 4K/HDR)
            if playerManager.showHUD {
                CustomPlayerHUD(pipController: pipController) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        playerManager.stopAndReset()
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Native AVPlayer Platform Wrapper
#if os(iOS)
struct AVPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    var onLayerReady: ((AVPlayerLayer) -> Void)?
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView(player: player)
        onLayerReady?(view.playerLayer)
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
    
    final class PlayerUIView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        
        init(player: AVPlayer) {
            super.init(frame: .zero)
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspect
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}
#else
struct AVPlayerRepresentable: NSViewRepresentable {
    let player: AVPlayer
    var onLayerReady: ((AVPlayerLayer) -> Void)?
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .none
        playerView.videoGravity = .resizeAspect
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player != player {
            nsView.player = player
        }
    }
}
#endif

#Preview("Video Player View") {
    VideoPlayerView()
        .environmentObject(AVPlayerManager())
        .frame(width: 800, height: 500)
}
