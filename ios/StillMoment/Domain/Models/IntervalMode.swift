//
//  IntervalMode.swift
//  Still Moment
//
//  Domain Model - Interval Gong Mode
//

import Foundation

/// Mode for interval gong playback during meditation
///
/// Replaces the previous fixed-interval-only approach with three distinct modes:
/// - `repeating`: Gongs at regular intervals from start (5:00, 10:00, 15:00, ...)
/// - `afterStart`: Single gong X minutes after start
/// - `beforeEnd`: Single gong X minutes before end
enum IntervalMode: String, Codable, Equatable, CaseIterable {
    /// Gongs repeat at regular intervals from the start
    /// Example: 20 min meditation, 5 min interval -> gongs at 5:00, 10:00, 15:00
    case repeating

    /// Single gong X minutes after the meditation starts
    /// Example: 20 min meditation, 5 min interval -> 1 gong at 5:00
    case afterStart

    /// Single gong X minutes before the meditation ends
    /// Example: 20 min meditation, 5 min interval -> 1 gong at 15:00
    case beforeEnd
}
