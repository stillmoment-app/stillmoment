//
//  TimerViewModel+Affirmations.swift
//  Still Moment
//
//  Application Layer - Affirmation texts for meditation phases
//

import Foundation

extension TimerViewModel {
    /// Get current running affirmation
    var currentRunningAffirmation: String {
        self.runningAffirmations[self.currentAffirmationIndex % self.runningAffirmations.count]
    }

    /// Get current preparation affirmation
    var currentPreparationAffirmation: String {
        self.preparationAffirmations[self.currentAffirmationIndex % self.preparationAffirmations.count]
    }

    // MARK: Private

    private var runningAffirmations: [String] {
        [
            NSLocalizedString("affirmation.running.1", comment: ""),
            NSLocalizedString("affirmation.running.2", comment: ""),
            NSLocalizedString("affirmation.running.3", comment: ""),
            NSLocalizedString("affirmation.running.4", comment: ""),
            NSLocalizedString("affirmation.running.5", comment: "")
        ]
    }

    private var preparationAffirmations: [String] {
        [
            NSLocalizedString("affirmation.preparation.1", comment: ""),
            NSLocalizedString("affirmation.preparation.2", comment: ""),
            NSLocalizedString("affirmation.preparation.3", comment: ""),
            NSLocalizedString("affirmation.preparation.4", comment: "")
        ]
    }
}
