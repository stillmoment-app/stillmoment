//
//  SettingDestination.swift
//  Still Moment
//
//  Presentation Layer - Routing for the five setting detail views (shared-083).
//

import Foundation

/// Destination type for `NavigationStack(path:)`-based routing from the timer
/// config screen to the five setting detail views. Replaces the previous
/// PraxisEditor-Index-Screen.
enum SettingDestination: Hashable {
    case preparation
    case attunement
    case background
    case gong
    case interval
}
