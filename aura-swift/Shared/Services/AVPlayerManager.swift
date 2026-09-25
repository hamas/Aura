//
//  AVPlayerManager.swift
//  Aura
//
//  Hardware-accelerated AVPlayer manager with hybrid stream resolver & telemetry diagnostics.
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

@MainActor
public final class AVPlayerManager: ObservableObject {
    @Published public private(set) var player: AVPlayer?
    @Published public private(set) var currentItem: MediaItem?
    @Published public private(set) var streamState: StreamState = .idle
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: Double = 0
    @Published public var duration: Double = 0
    @Published public var isBuffering: Bool = false
    @Published public var showHUD: Bool = true
    @Published public var isFullScreen: Bool = false
    
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()
    private var hudHideTask: Task<Void, Never>?
    private var streamResolveTask: Task<Void, Never>?
    
    public init() {}
    
    public func loadMedia(_ item: MediaItem, magnetURL: String? = nil) {
        let defaultOption = item.streamOptions.first
        loadStream(item: item, option: defaultOption ?? StreamOption(
            id: "\(item.id)-default",
            quality: "1080p HD",
            resolution: "1920x1080",
            codec: "H.264",
            audio: "AAC 2.0",
            size: "4.5 GB",
            seeders: 95,
            leechers: 8,
            provider: "⚡️ Real-Debrid CDN",
            streamURL: item.streamURL,
            magnetURL: magnetURL
        ))
    }
    
    public func loadStream(item: MediaItem, option: StreamOption) {
        print("🎬 [TRIGGER] User selected stream option '\(option.quality)' for '\(item.title)'")
        print("🎬 [TRIGGER] Target Stream URL: \(option.streamURL), Provider: \(option.provider)")
        
        stopAndReset()
        self.currentItem = item
        self.streamState = .resolving(provider: option.provider)
        
        setupPlayerWithURL(option.streamURL)
        
        if let magnet = option.magnetURL, !magnet.isEmpty {
            streamResolveTask = Task {
                let resolvedURL = await StreamResolverService.shared.resolve(
                    mediaItem: item,
                    magnetURLOrHash: magnet,
                    onStateChange: { [weak self] state in
                        Task { @MainActor in
                            self?.streamState = state
                        }
                    }
                )
                
                if !Task.isCancelled && resolvedURL != option.streamURL {
                    print("⚡️ [RESOLVER] Switching player to resolved stream: \(resolvedURL)")
                    self.setupPlayerWithURL(resolvedURL)
                }
            }
        } else {
            self.streamState = .playing(url: option.streamURL, isDebrid: true)
        }
    }
    
    private func setupPlayerWithURL(_ url: URL) {
        print("▶️ [PLAYER] Initializing AVPlayerItem with URL: \(url)")
        let playerItem = AVPlayerItem(url: url)
        playerItem.preferredForwardBufferDuration = 10.0
        
        if let existingPlayer = player {
            existingPlayer.replaceCurrentItem(with: playerItem)
        } else {
            let newPlayer = AVPlayer(playerItem: playerItem)
            newPlayer.automaticallyWaitsToMinimizeStalling = true
            self.player = newPlayer
        }
        
        setupObservers()
        play()
        resetHUDTimer()
    }
    
    public func play() {
        print("▶️ [PLAYER] Play command executed.")
        player?.play()
        isPlaying = true
        resetHUDTimer()
    }
    
    public func pause() {
        print("▶️ [PLAYER] Pause command executed.")
        player?.pause()
        isPlaying = false
        showHUD = true
        hudHideTask?.cancel()
    }
    
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    public func toggleMute() {
        if let player = player {
            player.isMuted.toggle()
        }
    }
    
    public func seek(by delta: Double) {
        let newTime = max(0, currentTime + delta)
        seek(to: newTime)
    }
    
    public func seek(to seconds: Double) {
        print("▶️ [PLAYER] Seeking to \(seconds)s...")
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                self?.resetHUDTimer()
            }
        }
    }
    
    public func userInteractedWithHUD() {
        showHUD = true
        resetHUDTimer()
    }
    
    public func resetHUDTimer() {
        hudHideTask?.cancel()
        guard isPlaying else { return }
        
        hudHideTask = Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000) // 3.5s inactivity
            if !Task.isCancelled {
                withAnimation(.easeOut(duration: 0.35)) {
                    self.showHUD = false
                }
            }
        }
    }
    
    public func stopAndReset() {
        print("▶️ [PLAYER] Stopping player and releasing media resources.")
        pause()
        streamResolveTask?.cancel()
        streamResolveTask = nil
        
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player = nil
        currentItem = nil
        streamState = .idle
        cancellables.removeAll()
        hudHideTask?.cancel()
        
        LocalTorrentProxyEngine.shared.stopActiveStream()
    }
    
    private func setupObservers() {
        guard let player = player else { return }
        
        // Periodic time observer for UI scrubber
        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds
            }
        }
        
        // Observe status & failure diagnostics
        player.publisher(for: \.currentItem?.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self, let status = status else { return }
                print("▶️ [PLAYER] AVPlayerItem status: \(status.rawValue)")
                
                switch status {
                case .readyToPlay:
                    print("✅ [PLAYER] AVPlayerItem is readyToPlay!")
                    if let itemDuration = player.currentItem?.duration.seconds, !itemDuration.isNaN {
                        self.duration = itemDuration
                    }
                case .failed:
                    let errorDesc = player.currentItem?.error?.localizedDescription ?? "Media decoding error"
                    print("❌ [PLAYER] AVPlayerItem FAILED: \(errorDesc)")
                    self.streamState = .failed(error: errorDesc)
                    self.isBuffering = false
                    self.isPlaying = false
                case .unknown:
                    print("ℹ️ [PLAYER] AVPlayerItem status unknown")
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe buffering state
        player.publisher(for: \.currentItem?.isPlaybackLikelyToKeepUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] likelyToKeepUp in
                let isBuf = !(likelyToKeepUp ?? true)
                self?.isBuffering = isBuf
                print("▶️ [PLAYER] Playback likely to keep up: \(likelyToKeepUp ?? false)")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                    print("❌ [PLAYER] Notification error: \(error.localizedDescription)")
                    self?.streamState = .failed(error: error.localizedDescription)
                }
            }
            .store(in: &cancellables)
    }
}
