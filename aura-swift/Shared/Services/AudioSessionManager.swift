//
//  AudioSessionManager.swift
//  Aura
//
//  Low-battery hardware audio session setup for Apple devices.
//

import Foundation
import AVFoundation

public final class AudioSessionManager {
    public static let shared = AudioSessionManager()
    
    private init() {}
    
    public func configurePlaybackSession() {
        #if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.allowAirPlay, .allowBluetoothHFP]
            )
            try session.setActive(true)
        } catch {
            print("[Aura AudioSession] Failed to set AVAudioSession category: \(error.localizedDescription)")
        }
        #else
        // macOS handles audio routing directly via CoreAudio/AVFoundation system controls
        #endif
    }
}
