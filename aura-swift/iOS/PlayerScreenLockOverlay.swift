//
//  PlayerScreenLockOverlay.swift
//  Aura (iOS target)
//
//  Accidental touch barrier shield and two-step haptic unlock overlay.
//

import SwiftUI

#if os(iOS)
public struct PlayerScreenLockOverlay: View {
    @EnvironmentObject private var playerManager: AVPlayerManager
    @State private var isPromptingUnlock: Bool = false
    @State private var unlockDismissTask: Task<Void, Never>? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if playerManager.isScreenLocked {
                // Full Screen Touch Interception Shield
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleLockedTap()
                    }
                
                // Floating Unlock Pill (Bottom Center)
                VStack {
                    Spacer()
                    
                    Button(action: {
                        handleLockedTap()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: isPromptingUnlock ? "lock.open.fill" : "lock.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(isPromptingUnlock ? .yellow : .white)
                            
                            Text(isPromptingUnlock ? "Tap again to unlock" : "Screen Locked")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule()
                                        .stroke(isPromptingUnlock ? Color.yellow.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 8)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isPromptingUnlock ? 1.06 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPromptingUnlock)
                    .padding(.bottom, 48)
                }
                .transition(.opacity)
            }
        }
    }
    
    private func handleLockedTap() {
        if isPromptingUnlock {
            // Step 2: Unlock screen
            iOSHapticsManager.shared.triggerNotification(.success)
            withAnimation(.easeInOut(duration: 0.25)) {
                playerManager.isScreenLocked = false
                isPromptingUnlock = false
                playerManager.userInteractedWithHUD()
            }
            unlockDismissTask?.cancel()
        } else {
            // Step 1: Prompt unlock confirmation
            iOSHapticsManager.shared.triggerImpact(.medium)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPromptingUnlock = true
            }
            
            unlockDismissTask?.cancel()
            unlockDismissTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if !Task.isCancelled {
                    withAnimation {
                        isPromptingUnlock = false
                    }
                }
            }
        }
    }
}
#endif
