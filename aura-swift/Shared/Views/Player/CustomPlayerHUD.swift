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
                
                // PiP & AirPlay Buttons
                HStack(spacing: 16) {
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
                .accentColor(.white)
                
                HStack {
                    Text(formatTime(playerManager.currentTime))
                        .font(.caption.monospaced())
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
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
