//
//  CustomPlayerHUD.swift
//  Aura
//
//  Custom hardware-accelerated Video Player HUD with auto-hide timer.
//

import SwiftUI
import AVKit

public struct CustomPlayerHUD: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @ObservedObject public var pipController: PictureInPictureController
    public var onClose: () -> Void
    
    public init(pipController: PictureInPictureController, onClose: @escaping () -> Void) {
        self.pipController = pipController
        self.onClose = onClose
    }
    
    public var body: some View {
        VStack {
            // Top Bar
            HStack {
                Button(action: {
                    playerManager.stopAndReset()
                    onClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(playerManager.currentItem?.title ?? "")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Text(playerManager.currentItem?.subtitle ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(playerManager.streamState.description)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255))
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // Actions: Lock, Aspect Ratio, PiP, AirPlay
                HStack(spacing: 16) {
                    #if os(iOS)
                    // Screen Lock Toggle Button (iOS)
                    Button(action: {
                        iOSHapticsManager.shared.triggerImpact(.medium)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            playerManager.isScreenLocked = true
                        }
                    }) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Aspect Ratio Cycle Button
                    Button(action: {
                        iOSHapticsManager.shared.triggerImpact(.light)
                        playerManager.cycleAspectRatioMode()
                    }) {
                        Image(systemName: "aspectratio")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    #endif
                    
                    if pipController.isPiPSupported {
                        Button(action: {
                            pipController.togglePiP()
                        }) {
                            Image(systemName: "pip.enter")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    #if os(iOS)
                    AVAirPlayButtonWrapper()
                        .frame(width: 30, height: 30)
                    #elseif os(macOS)
                    AVAirPlayButtonMacWrapper()
                        .frame(width: 30, height: 30)
                    #endif
                }
            }
            .padding(20)
            .liquidGlass(cornerRadius: 16, opacity: 0.75)
            .padding(.top, 16)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Error Card State Overlay if Playback Failed
            if case .failed(let errorMsg) = playerManager.streamState {
                VStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.yellow)
                    
                    Text("Playback Error")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                    
                    Text(errorMsg)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button("Retry Playback") {
                        if let item = playerManager.currentItem {
                            playerManager.loadMedia(item)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
            } else {
                // Center Playback Controls
                HStack(spacing: 40) {
                    Button(action: {
                        playerManager.userInteractedWithHUD()
                        playerManager.seek(to: max(0, playerManager.currentTime - 10))
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.largeTitle.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        playerManager.userInteractedWithHUD()
                        playerManager.togglePlayPause()
                    }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.20), lineWidth: 1.5)
                                )
                            
                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        playerManager.userInteractedWithHUD()
                        playerManager.seek(to: min(playerManager.duration, playerManager.currentTime + 10))
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.largeTitle.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
            
            // Middle: Seek Ripple Feedback Overlay or Playback State
            if let rippleText = playerManager.seekRippleText {
                SeekRippleOverlay(text: rippleText)
            }
            
            Spacer()
            
            // Overlays Layer: Smart Skip & Next Episode Binge Countdown
            HStack {
                // Smart Skip Button (Intro / Recap)
                if let interval = playerManager.activeInterval {
                    SmartSkipButton(interval: interval) {
                        playerManager.skipCurrentInterval()
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                Spacer()
                
                // Next Episode Glassmorphic Countdown
                if playerManager.showNextEpisodeCountdown {
                    NextEpisodeCountdownOverlay(
                        remainingSeconds: playerManager.remainingCountdownSeconds,
                        nextEpisodeTitle: "Next Episode",
                        onPlayNow: { playerManager.triggerNextEpisode() },
                        onDismiss: { playerManager.dismissNextEpisodeCountdown() }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 8)
            
            // Bottom Scrubber Bar & Quick Action Controls
            VStack(spacing: 12) {
                // Slider timeline scrubber
                Slider(
                    value: Binding(
                        get: { playerManager.currentTime },
                        set: { newValue in
                            playerManager.userInteractedWithHUD()
                            playerManager.seek(to: newValue)
                        }
                    ),
                    in: 0...max(1, playerManager.duration)
                )
                .accentColor(Color(red: 184/255, green: 119/255, blue: 255/255))
                
                HStack(spacing: 16) {
                    Text(formatTime(playerManager.currentTime))
                        .font(.caption.monospaced())
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                    
                    Text("/")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text(formatTime(playerManager.duration))
                        .font(.caption.monospaced())
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Episodes Drawer Toggle
                    Button(action: {
                        playerManager.userInteractedWithHUD()
                        playerManager.showEpisodeDrawer.toggle()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .font(.system(size: 13, weight: .bold))
                            Text("Episodes")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Subtitles & Audio Appearance
                    Button(action: {
                        playerManager.userInteractedWithHUD()
                        playerManager.showSubtitleModal.toggle()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "captions.bubble.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Subtitles")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Dialogue Boost Vocal EQ Toggle
                    Button(action: {
                        playerManager.userInteractedWithHUD()
                        playerManager.toggleDialogueBoost()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: playerManager.dialogueBoostEnabled ? "waveform.and.mic" : "mic.slash")
                                .font(.system(size: 13, weight: .bold))
                            Text("Vocal Boost")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            playerManager.dialogueBoostEnabled
                                ? Color(red: 184/255, green: 119/255, blue: 255/255)
                                : Color.white.opacity(0.12)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Remaining Time
                    Text("-\(formatTime(max(0, playerManager.duration - playerManager.currentTime)))")
                        .font(.caption.monospaced())
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
            }
            .padding(18)
            .liquidGlass(cornerRadius: 16, opacity: 0.75)
            .padding(.bottom, 24)
            .padding(.horizontal, 20)
        }
        .overlay(
            Group {
                if playerManager.showEpisodeDrawer {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture { playerManager.showEpisodeDrawer = false }
                        
                        InPlayerEpisodeSheet {
                            playerManager.showEpisodeDrawer = false
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                if playerManager.showSubtitleModal {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture { playerManager.showSubtitleModal = false }
                        
                        SubtitleCustomizerModal(config: $playerManager.subtitleConfig) {
                            playerManager.showSubtitleModal = false
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            playerManager.userInteractedWithHUD()
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let total = Int(seconds)
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
}

#if os(iOS)
struct AVAirPlayButtonWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = .white
        picker.tintColor = .white
        return picker
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
#elseif os(macOS)
struct AVAirPlayButtonMacWrapper: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.isRoutePickerButtonBordered = false
        return picker
    }
    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}
#endif

#Preview("Player HUD") {
    ZStack {
        Color.black.ignoresSafeArea()
        CustomPlayerHUD(pipController: PictureInPictureController()) {}
            .environmentObject(AVPlayerManager())
    }
    .frame(width: 800, height: 500)
}
