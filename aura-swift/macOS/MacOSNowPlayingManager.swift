//
//  MacOSNowPlayingManager.swift
//  Aura (macOS target)
//
//  Native macOS MPRemoteCommandCenter and Now Playing Info Center integration.
//

import Foundation
import MediaPlayer

#if os(macOS)
@MainActor
public final class MacOSNowPlayingManager {
    public static let shared = MacOSNowPlayingManager()
    
    private init() {}
    
    public func configureRemoteCommands(playerManager: AVPlayerManager) {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play Command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            Task { @MainActor in
                playerManager.play()
            }
            return .success
        }
        
        // Pause Command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            Task { @MainActor in
                playerManager.pause()
            }
            return .success
        }
        
        // Toggle Play/Pause
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { _ in
            Task { @MainActor in
                playerManager.togglePlayPause()
            }
            return .success
        }
        
        // Skip Forward / Backward
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [10]
        commandCenter.skipForwardCommand.addTarget { _ in
            Task { @MainActor in
                playerManager.seekWithFeedback(delta: 10)
            }
            return .success
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.addTarget { _ in
            Task { @MainActor in
                playerManager.seekWithFeedback(delta: -10)
            }
            return .success
        }
        
        // Next Track (Episode)
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { _ in
            Task { @MainActor in
                playerManager.triggerNextEpisode()
            }
            return .success
        }
    }
    
    public func updateNowPlayingInfo(item: MediaItem, currentTime: Double, duration: Double, isPlaying: Bool) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = item.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = item.subtitle
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
#endif
