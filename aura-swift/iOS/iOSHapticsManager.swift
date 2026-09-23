//
//  iOSHapticsManager.swift
//  Aura (iOS target override)
//
//  Provides tactile FeedbackGenerator haptic triggers for iOS devices.
//

import Foundation
#if os(iOS)
import UIKit

public final class iOSHapticsManager {
    public static let shared = iOSHapticsManager()
    
    private init() {}
    
    public func triggerImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    public func triggerNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
#endif
