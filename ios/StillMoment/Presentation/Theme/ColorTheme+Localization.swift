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
        case .warmDesert:
            NSLocalizedString("settings.theme.warmDesert", comment: "")
        case .darkWarm:
            NSLocalizedString("settings.theme.darkWarm", comment: "")
        }
    }
}
