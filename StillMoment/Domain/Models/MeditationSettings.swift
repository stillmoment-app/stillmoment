//
//  MeditationSettings.swift
//  Still Moment
//
//  Domain - Meditation Settings Model
//

import Foundation

/// Background audio mode during meditation
enum BackgroundAudioMode: String, Codable, CaseIterable {
    /// Very quiet audio (almost silent) - keeps app active
    case silent = "Silent"

    /// Audible white noise
    case whiteNoise = "White Noise"
}

/// Settings for meditation sessions
struct MeditationSettings: Codable, Equatable {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        intervalGongsEnabled: Bool = false,
        intervalMinutes: Int = 5,
        backgroundAudioMode: BackgroundAudioMode = .silent
    ) {
        self.intervalGongsEnabled = intervalGongsEnabled
        self.intervalMinutes = Self.validateInterval(intervalMinutes)
        self.backgroundAudioMode = backgroundAudioMode
    }

    // MARK: Internal

    // MARK: - Persistence Keys

    enum Keys {
        static let intervalGongsEnabled = "intervalGongsEnabled"
        static let intervalMinutes = "intervalMinutes"
        static let backgroundAudioMode = "backgroundAudioMode"
    }

    /// Whether interval gongs are enabled during meditation
    var intervalGongsEnabled: Bool

    /// Interval in minutes between gongs (3, 5, or 10)
    var intervalMinutes: Int

    /// Background audio mode during meditation
    var backgroundAudioMode: BackgroundAudioMode

    // MARK: - Validation

    /// Validates and clamps interval to valid values (3, 5, or 10)
    static func validateInterval(_ minutes: Int) -> Int {
        switch minutes {
        case ...3:
            3
        case 4...7:
            5
        default:
            10
        }
    }
}

// MARK: - Default Settings

extension MeditationSettings {
    /// Default settings with interval gongs disabled and silent background audio
    static let `default` = MeditationSettings(
        intervalGongsEnabled: false,
        intervalMinutes: 5,
        backgroundAudioMode: .silent
    )
}
