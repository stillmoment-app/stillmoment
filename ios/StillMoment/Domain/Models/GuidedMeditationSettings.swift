//
//  GuidedMeditationSettings.swift
//  Still Moment
//
//  Settings for guided meditation playback
//

import Foundation

/// Settings for guided meditation playback (immutable Value Object)
struct GuidedMeditationSettings: Codable, Equatable {
    // MARK: - Valid Values

    /// Valid non-nil preparation time values in seconds
    static let validPreparationTimeValues: [Int] = [5, 10, 15, 20, 30, 45]

    /// Initial preparation time when user first enables the feature
    static let initialPreparationTimeSeconds = 15

    /// Valid preparation time options including disabled (nil = disabled)
    static var validPreparationTimes: [Int?] {
        [nil] + validPreparationTimeValues
    }

    // MARK: - Properties

    /// Preparation time in seconds before MP3 starts (nil = disabled)
    let preparationTimeSeconds: Int?

    // MARK: - Initialization

    init(preparationTimeSeconds: Int? = nil) {
        self.preparationTimeSeconds = Self.validatePreparationTime(preparationTimeSeconds)
    }

    // MARK: - Validation

    /// Validates preparation time - returns nil for nil, or closest valid value for non-nil
    static func validatePreparationTime(_ seconds: Int?) -> Int? {
        guard let seconds else {
            return nil
        }

        return self.validPreparationTimeValues.min { abs($0 - seconds) < abs($1 - seconds) }
    }

    // MARK: - Factory Methods

    /// Creates settings with updated preparation time
    func withPreparationTime(_ seconds: Int?) -> GuidedMeditationSettings {
        GuidedMeditationSettings(preparationTimeSeconds: seconds)
    }

    // MARK: - Default

    static let `default` = GuidedMeditationSettings(preparationTimeSeconds: nil)
}
