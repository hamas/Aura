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
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(playerManager.currentItem?.title ?? "")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(playerManager.currentItem?.subtitle ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // PiP & AirPlay Buttons
                HStack(spacing: 16) {
                    if pipController.isPiPSupported {
                        Button(action: {
                            pipController.togglePiP()
                        }) {
                            Image(systemName: "pip.enter")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    #if os(iOS)
                    AVAirPlayButtonWrapper()
                        .frame(width: 30, height: 30)
                    #endif
                }
            }
            .padding(20)
            .liquidGlass(cornerRadius: 20, opacity: 0.7)
            .padding(.top, 16)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Center Playback Controls
            HStack(spacing: 40) {
                Button(action: {
                    playerManager.userInteractedWithHUD()
                    playerManager.seek(to: max(0, playerManager.currentTime - 10))
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 32, weight: .semibold))
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
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                            )
                        
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    playerManager.userInteractedWithHUD()
                    playerManager.seek(to: min(playerManager.duration, playerManager.currentTime + 10))
                }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            // Bottom Scrubber Bar
            VStack(spacing: 8) {
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
                .accentColor(.purple)
                
                HStack {
                    Text(formatTime(playerManager.currentTime))
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("-\(formatTime(max(0, playerManager.duration - playerManager.currentTime)))")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
            }
            .padding(18)
            .liquidGlass(cornerRadius: 20, opacity: 0.75)
            .padding(.bottom, 24)
            .padding(.horizontal, 20)
        }
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
        picker.activeTintColor = .systemPurple
        picker.tintColor = .white
        return picker
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
#endif
