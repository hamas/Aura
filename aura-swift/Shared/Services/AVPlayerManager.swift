//
//  AVPlayerManager.swift
//  Aura
//
//  Hardware-accelerated AVPlayer manager with battery optimization & HUD idle timer.
//

import Foundation
import AVFoundation
import Combine
import SwiftUI

@MainActor
public final class AVPlayerManager: ObservableObject {
    @Published public private(set) var player: AVPlayer?
    @Published public private(set) var currentItem: MediaItem?
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: Double = 0
    @Published public var duration: Double = 0
    @Published public var isBuffering: Bool = false
    @Published public var showHUD: Bool = true
    @Published public var isFullScreen: Bool = false
    
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()
    private var hudHideTask: Task<Void, Never>?
    
    public init() {}
    
    public func loadMedia(_ item: MediaItem) {
        self.currentItem = item
        let playerItem = AVPlayerItem(url: item.streamURL)
        
        // Configure low-latency & high dynamic range preferences
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
        player?.play()
        isPlaying = true
        resetHUDTimer()
    }
    
    public func pause() {
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
    
    public func seek(to seconds: Double) {
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
        pause()
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player = nil
        currentItem = nil
        cancellables.removeAll()
        hudHideTask?.cancel()
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
        
        // Observe status & duration
        player.publisher(for: \.currentItem?.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self, status == .readyToPlay else { return }
                if let itemDuration = player.currentItem?.duration.seconds, !itemDuration.isNaN {
                    self.duration = itemDuration
                }
            }
            .store(in: &cancellables)
        
        // Observe buffering state
        player.publisher(for: \.currentItem?.isPlaybackLikelyToKeepUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] likelyToKeepUp in
                self?.isBuffering = !(likelyToKeepUp ?? true)
            }
            .store(in: &cancellables)
    }
}
