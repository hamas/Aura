//
//  TouchPlayerGesturesModifier.swift
//  Aura (iOS target)
//
//  Touch gesture recognizers for brightness/volume edge drags, double-tap seeking, and pinch-to-zoom aspect ratio.
//

import SwiftUI

#if os(iOS)
import UIKit

public struct TouchPlayerGesturesModifier: ViewModifier {
    @EnvironmentObject private var playerManager: AVPlayerManager
    
    @State private var initialBrightness: CGFloat = 0.5
    @State private var currentBrightness: CGFloat = 0.5
    @State private var isDraggingBrightness: Bool = false
    
    @State private var currentVolume: Double = 0.7
    @State private var isDraggingVolume: Bool = false
    
    @State private var activeSeekFeedback: String? = nil
    @State private var seekCount: Int = 0
    @State private var seekDebounceTask: Task<Void, Never>? = nil
    
    public init() {}
    
    public func body(content: Content) -> some View {
        GeometryReader { geo in
            ZStack {
                content
                
                if !playerManager.isScreenLocked {
                    // Touch Gesture Recognition Area
                    HStack(spacing: 0) {
                        // Left 50% (Brightness Drag & Double Tap Rewind)
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 15)
                                    .onChanged { value in
                                        handleBrightnessDrag(translationY: value.translation.height, totalHeight: geo.size.height)
                                    }
                                    .onEnded { _ in
                                        isDraggingBrightness = false
                                    }
                            )
                            .onTapGesture(count: 2) {
                                handleDoubleTapSeek(isForward: false)
                            }
                            .onTapGesture(count: 1) {
                                playerManager.userInteractedWithHUD()
                            }
                        
                        // Right 50% (Volume Drag & Double Tap Forward)
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 15)
                                    .onChanged { value in
                                        handleVolumeDrag(translationY: value.translation.height, totalHeight: geo.size.height)
                                    }
                                    .onEnded { _ in
                                        isDraggingVolume = false
                                    }
                            )
                            .onTapGesture(count: 2) {
                                handleDoubleTapSeek(isForward: true)
                            }
                            .onTapGesture(count: 1) {
                                playerManager.userInteractedWithHUD()
                            }
                    }
                    .gesture(
                        MagnificationGesture()
                            .onEnded { scale in
                                if scale > 1.15 || scale < 0.85 {
                                    iOSHapticsManager.shared.triggerImpact(.medium)
                                    playerManager.cycleAspectRatioMode()
                                }
                            }
                    )
                }
                
                // Vertical HUD Pill Indicators
                HStack {
                    if isDraggingBrightness {
                        MobileVolumeBrightnessHUD(type: .brightness, value: Double(currentBrightness))
                            .padding(.leading, 32)
                    }
                    
                    Spacer()
                    
                    if isDraggingVolume {
                        MobileVolumeBrightnessHUD(type: .volume, value: currentVolume)
                            .padding(.trailing, 32)
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Gesture Handlers
    private func handleBrightnessDrag(translationY: CGFloat, totalHeight: CGFloat) {
        if !isDraggingBrightness {
            initialBrightness = UIScreen.main.brightness
            currentBrightness = initialBrightness
            isDraggingBrightness = true
        }
        
        let delta = -translationY / (totalHeight * 0.6)
        let newBrightness = max(0.0, min(1.0, initialBrightness + delta))
        currentBrightness = newBrightness
        UIScreen.main.brightness = newBrightness
    }
    
    private func handleVolumeDrag(translationY: CGFloat, totalHeight: CGFloat) {
        if !isDraggingVolume {
            isDraggingVolume = true
        }
        
        let delta = -translationY / (totalHeight * 0.6)
        let newVolume = max(0.0, min(1.0, currentVolume + Double(delta * 0.05)))
        currentVolume = newVolume
        playerManager.player?.volume = Float(newVolume)
    }
    
    private func handleDoubleTapSeek(isForward: Bool) {
        seekCount += 1
        let seconds = Double(seekCount * 10)
        
        iOSHapticsManager.shared.triggerImpact(.medium)
        playerManager.seek(by: isForward ? 10.0 : -10.0)
        playerManager.triggerSeekFeedback(text: isForward ? "+\(Int(seconds))s" : "-\(Int(seconds))s")
        
        seekDebounceTask?.cancel()
        seekDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if !Task.isCancelled {
                seekCount = 0
            }
        }
    }
}

extension View {
    public func enableTouchPlayerGestures() -> some View {
        self.modifier(TouchPlayerGesturesModifier())
    }
}

#else
extension View {
    public func enableTouchPlayerGestures() -> some View {
        self
    }
}
#endif
