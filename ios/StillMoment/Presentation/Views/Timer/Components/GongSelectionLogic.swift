//
//  GongSelectionLogic.swift
//  Still Moment
//
//  Presentation Layer — pure layout decisions for the gong selection screen (shared-115).
//

import Foundation

/// Pure, testable layout decisions for the gong selection screen.
///
/// Kept free of SwiftUI/UIKit so the rules can be unit-tested without rendering.
enum GongSelectionLogic {
    /// The volume card is shown for audible gongs and hidden for the vibration
    /// option (which has no volume and shows a helper text instead).
    static func isVolumeCardVisible(soundId: String) -> Bool {
        soundId != GongSound.vibrationId
    }

    /// The meditation editor's sound list (shared-116) is shown only when at least
    /// one gong is enabled — otherwise there is no sound to pick.
    static func isSoundListVisible(startGongEnabled: Bool, endGongEnabled: Bool) -> Bool {
        startGongEnabled || endGongEnabled
    }
}
