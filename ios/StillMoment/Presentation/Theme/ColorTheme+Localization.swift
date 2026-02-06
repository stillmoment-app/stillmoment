//
//  ColorTheme+Localization.swift
//  Still Moment
//
//  Presentation Layer - Localized display names for color themes.
//

import Foundation

extension ColorTheme {
    var localizedName: String {
        switch self {
        case .candlelight:
            NSLocalizedString("settings.theme.candlelight", comment: "")
        case .forest:
            NSLocalizedString("settings.theme.forest", comment: "")
        case .moon:
            NSLocalizedString("settings.theme.moon", comment: "")
        }
    }
}
