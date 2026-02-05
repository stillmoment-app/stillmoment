//
//  ColorTheme.swift
//  Still Moment
//
//  Domain Layer - Color theme model for user personalization.
//

import Foundation

enum ColorTheme: String, CaseIterable, Codable {
    case warmDesert
    case darkWarm

    static let `default`: ColorTheme = .warmDesert
}
