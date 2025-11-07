//
//  BreathingSettings.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI

struct BreathingSettings: Codable {
    var backgroundColorHex: String = "#8B9D83" // Sage green default
    var circleColorHex: String = "#F5F5DC" // Beige/Sand default
    var inhaleDuration: Double = 6.0
    var exhaleDuration: Double = 6.0
    var enableIntervalBells: Bool = true // Toggle for 5-minute interval bells during meditation

    var backgroundColor: Color {
        Color(hex: backgroundColorHex) ?? .mint
    }

    var circleColor: Color {
        Color(hex: circleColorHex) ?? .white
    }

    mutating func setBackgroundColor(_ color: Color) {
        backgroundColorHex = color.toHex() ?? backgroundColorHex
    }

    mutating func setCircleColor(_ color: Color) {
        circleColorHex = color.toHex() ?? circleColorHex
    }
}

// Color extension for hex conversion
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}
