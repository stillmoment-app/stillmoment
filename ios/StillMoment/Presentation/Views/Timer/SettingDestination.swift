//
//  SettingDestination.swift
//  Still Moment
//
//  Presentation Layer - Routing for the four setting detail views (shared-083).
//

import Foundation

/// Destination type for `NavigationStack(path:)`-based routing from the timer
/// config screen to the four setting detail views.
enum SettingDestination: Hashable {
    case preparation
    case background
    case gong
    case interval
}
