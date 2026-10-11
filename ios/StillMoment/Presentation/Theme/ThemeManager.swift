//
//  ThemeManager.swift
//  Still Moment
//
//  Presentation Layer - Manages appearance mode (Light/Dark/System) and resolves colors.
//
//  Injected as @StateObject in StillMomentApp, accessed via @EnvironmentObject in Views.
//  Uses @AppStorage for persistence (same pattern as selectedTab), in the store the app
//  chose at launch (ios-056).
//

import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    // MARK: Lifecycle

    /// - Parameter store: Settings that hold the user's appearance choice
    init(store: UserDefaults) {
        self._appearanceMode = AppStorage(wrappedValue: .default, "appearanceMode", store: store)
    }

    // MARK: Internal

    @AppStorage var appearanceMode: AppearanceMode

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
        ThemeColors.resolve(colorScheme: colorScheme)
    }
}
