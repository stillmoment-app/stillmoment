//
//  Double+Opacity.swift
//  Still Moment
//
//  Presentation Layer - Opacity Design Tokens
//

import SwiftUI

// MARK: - Opacity Design Tokens

extension Double {
    /// Opacity for overlay backgrounds (loading states, modals)
    static let opacityOverlay: Double = 0.2

    /// Opacity for shadow effects
    static let opacityShadow: Double = 0.3

    /// Opacity for secondary/disabled UI elements
    static let opacitySecondary: Double = 0.5

    /// Opacity for tertiary/hint UI elements
    static let opacityTertiary: Double = 0.7
}
