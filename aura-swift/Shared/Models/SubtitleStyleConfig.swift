//
//  SubtitleStyleConfig.swift
//  Aura
//
//  Netflix-grade subtitle styling and synchronization settings.
//

import SwiftUI

public enum SubtitlePreset: String, CaseIterable, Identifiable, Codable {
    case netflixYellow = "Netflix Yellow"
    case netflixWhite = "Netflix White"
    case cleanOutline = "Clean Outline"
    case semiTransparent = "Semi-Transparent Box"
    
    public var id: String { rawValue }
    
    public var textColorHex: String {
        switch self {
        case .netflixYellow: return "#FFE500"
        case .netflixWhite, .cleanOutline, .semiTransparent: return "#FFFFFF"
        }
    }
    
    public var boxOpacity: Double {
        switch self {
        case .semiTransparent: return 0.65
        case .netflixYellow, .netflixWhite, .cleanOutline: return 0.0
        }
    }
}

public struct SubtitleStyleConfig: Codable, Hashable {
    public var preset: SubtitlePreset
    public var fontSize: CGFloat
    public var textColorHex: String
    public var backgroundOpacity: Double
    public var hasShadow: Bool
    public var fontScale: Double
    public var offsetSeconds: Double
    
    public init(
        preset: SubtitlePreset = .netflixYellow,
        fontSize: CGFloat = 20.0,
        textColorHex: String = "#FFE500",
        backgroundOpacity: Double = 0.0,
        hasShadow: Bool = true,
        fontScale: Double = 1.0,
        offsetSeconds: Double = 0.0
    ) {
        self.preset = preset
        self.fontSize = fontSize
        self.textColorHex = textColorHex
        self.backgroundOpacity = backgroundOpacity
        self.hasShadow = hasShadow
        self.fontScale = fontScale
        self.offsetSeconds = offsetSeconds
    }
    
    public var textColor: Color {
        Color(hex: textColorHex) ?? Color(red: 255/255, green: 229/255, blue: 0)
    }
    
    public static let `default` = SubtitleStyleConfig()
}

// MARK: - Color Hex Initializer
extension Color {
    public init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
