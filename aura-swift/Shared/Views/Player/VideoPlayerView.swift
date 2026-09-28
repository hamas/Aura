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
                AVPlayerRepresentable(
                    player: player,
                    aspectMode: playerManager.videoAspectRatioMode
                ) { layer in
                    pipController.setup(with: layer)
                }
                .ignoresSafeArea()
                .onTapGesture {
                    if !playerManager.isScreenLocked {
                        playerManager.userInteractedWithHUD()
                    }
                }
            }
            
            // Buffering Spinner Indicator
            if playerManager.isBuffering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .scaleEffect(1.8)
            }
            
            // HUD Overlay (Fades out when idling or when screen is locked)
            if playerManager.showHUD && !playerManager.isScreenLocked {
                CustomPlayerHUD(pipController: pipController) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        playerManager.stopAndReset()
                    }
                }
                .transition(.opacity)
            }
            
            #if os(iOS)
            // Screen Lock Overlay
            PlayerScreenLockOverlay()
            #endif
        }
        .enableTouchPlayerGestures()
    }
}

// MARK: - Native AVPlayer Platform Wrapper
#if os(iOS)
struct AVPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    let aspectMode: AVPlayerManager.VideoAspectMode
    var onLayerReady: ((AVPlayerLayer) -> Void)?
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView(player: player)
        onLayerReady?(view.playerLayer)
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = gravityForMode(aspectMode)
    }
    
    private func gravityForMode(_ mode: AVPlayerManager.VideoAspectMode) -> AVLayerVideoGravity {
        switch mode {
        case .fit: return .resizeAspect
        case .fill: return .resizeAspectFill
        case .stretch: return .resize
        }
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
    let aspectMode: AVPlayerManager.VideoAspectMode
    var onLayerReady: ((AVPlayerLayer) -> Void)?
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .none
        playerView.videoGravity = gravityForMode(aspectMode)
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player != player {
            nsView.player = player
        }
        nsView.videoGravity = gravityForMode(aspectMode)
    }
    
    private func gravityForMode(_ mode: AVPlayerManager.VideoAspectMode) -> AVLayerVideoGravity {
        switch mode {
        case .fit: return .resizeAspect
        case .fill: return .resizeAspectFill
        case .stretch: return .resize
        }
    }
}
#endif

#Preview("Video Player View") {
    VideoPlayerView()
        .environmentObject(AVPlayerManager())
        .frame(width: 800, height: 500)
}
