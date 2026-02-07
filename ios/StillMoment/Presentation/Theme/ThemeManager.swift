//
//  ThemeManager.swift
//  Still Moment
//
//  Presentation Layer - Manages theme selection and persistence.
//
//  Injected as @StateObject in StillMomentApp, accessed via @EnvironmentObject in Views.
//  Uses @AppStorage for persistence (same pattern as selectedTab).
//

import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme")
    var selectedTheme: ColorTheme = .default

    @AppStorage("appearanceMode")
    var appearanceMode: AppearanceMode = .default

    /// Returns the `ColorScheme` override for `preferredColorScheme(_:)`.
    /// `nil` means follow system (no override).
    var preferredColorScheme: ColorScheme? {
        switch self.appearanceMode {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    func resolvedColors(for colorScheme: ColorScheme) -> ThemeColors {
        ThemeColors.resolve(theme: self.selectedTheme, colorScheme: colorScheme)
    }
}
