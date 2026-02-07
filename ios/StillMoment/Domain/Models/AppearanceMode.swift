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

    static let `default`: AppearanceMode = .system
}
