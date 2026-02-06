//
//  ColorTheme.swift
//  Still Moment
//
//  Domain Layer - Color theme model for user personalization.
//

import Foundation

enum ColorTheme: String, CaseIterable, Codable {
    case candlelight
    case forest
    case moon

    static let `default`: ColorTheme = .candlelight
}
