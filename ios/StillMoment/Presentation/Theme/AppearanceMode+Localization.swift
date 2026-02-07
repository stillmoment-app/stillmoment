//
//  AppearanceMode+Localization.swift
//  Still Moment
//
//  Presentation Layer - Localized display names for appearance modes.
//

import Foundation

extension AppearanceMode {
    var localizedName: String {
        switch self {
        case .system:
            NSLocalizedString("settings.appearance.system", comment: "")
        case .light:
            NSLocalizedString("settings.appearance.light", comment: "")
        case .dark:
            NSLocalizedString("settings.appearance.dark", comment: "")
        }
    }
}
