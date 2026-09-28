//
//  MediaInterval.swift
//  Aura
//
//  Interval metadata for smart skip of intros, recaps, and credits.
//

import Foundation

public enum MediaIntervalType: String, Codable, Hashable {
    case intro = "intro"
    case recap = "recap"
    case credits = "credits"
    case preview = "preview"
    
    public var label: String {
        switch self {
        case .intro: return "Skip Intro"
        case .recap: return "Skip Recap"
        case .credits: return "Next Episode"
        case .preview: return "Skip Preview"
        }
    }
}

public struct MediaInterval: Identifiable, Hashable, Codable {
    public let id: String
    public let type: MediaIntervalType
    public let startSeconds: Double
    public let endSeconds: Double
    
    public init(id: String = UUID().uuidString, type: MediaIntervalType, startSeconds: Double, endSeconds: Double) {
        self.id = id
        self.type = type
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
    }
    
    public func contains(position: Double) -> Bool {
        return position >= startSeconds && position <= endSeconds
    }
}
