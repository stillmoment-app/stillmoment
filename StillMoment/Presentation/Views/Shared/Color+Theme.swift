//
//  Color+Theme.swift
//  Still Moment
//
//  Presentation Layer - Theme Color Definitions
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors - Warm Earth Tones

    /// Light warm background - cream tone
    static let warmCream = Color(hex: "#FFF8F0")

    /// Medium warm background - sand tone
    static let warmSand = Color(hex: "#F5E6D3")

    /// Darker warm background - pale apricot
    static let paleApricot = Color(hex: "#FFD4B8")

    /// Main accent color - terracotta (buttons, progress ring)
    static let terracotta = Color(hex: "#D4876F")

    /// Hover/Active states - clay
    static let clay = Color(hex: "#C97D60")

    /// Soft highlights - dusty rose
    static let dustyRose = Color(hex: "#E8B4A0")

    // MARK: - Text Colors

    /// Primary text color - warm black
    static let warmBlack = Color(hex: "#3D3228")

    /// Secondary text color - warm gray
    static let warmGray = Color(hex: "#8B7D6B")

    // MARK: - Semantic Colors

    /// Error/warning color - warm red tone that fits earth palette
    static let warmError = Color(hex: "#C74B3B")

    // MARK: - UI Elements

    /// Timer ring background
    static let ringBackground = Color(hex: "#E8DDD0")

    /// Timer ring progress
    static let ringProgress = Color(hex: "#D4876F")

    // MARK: - Gradients

    /// Main background gradient for views
    static var warmGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.warmCream, // top
                Color.warmSand, // middle
                Color.paleApricot // bottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Hex Color Support

extension Color {
    /// Initialize a Color from a hex string (e.g., "#FFF8F0")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 6: // RGB
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
