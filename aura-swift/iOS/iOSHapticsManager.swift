//
//  iOSHapticsManager.swift
//  Aura (iOS target override)
//
//  Provides tactile FeedbackGenerator haptic triggers for iOS devices.
//

import Foundation
#if os(iOS)
import UIKit
import CoreHaptics

public final class iOSHapticsManager {
    public static let shared = iOSHapticsManager()
    
    public var isHapticsSupported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    private init() {}
    
    public func triggerImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isHapticsSupported else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    public func triggerNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsSupported else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
#endif
