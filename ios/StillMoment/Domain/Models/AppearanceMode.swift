//
//  AppearanceMode.swift
//  Still Moment
//
//  Domain Layer - Appearance mode for light/dark override.
//

import Foundation

enum AppearanceMode: String, CaseIterable, Codable {
    case system
    case light
    case dark

    /// Appearance for installs without a stored selection.
    ///
    /// Dark on purpose (shared-122): the dark presentation carries the calm the app is
    /// about and matches how the app is shown in the store. Users who never picked an
    /// appearance themselves - including existing users updating the app - move to dark;
    /// switching back is a single tap in the settings.
    ///
    /// This is the single source of truth. `ThemeManager.appearanceMode` reads it as its
    /// `@AppStorage` default, which also covers an unparseable stored raw value.
    static let `default`: AppearanceMode = .dark
}
