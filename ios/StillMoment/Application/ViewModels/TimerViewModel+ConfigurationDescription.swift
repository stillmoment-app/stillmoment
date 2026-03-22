//
//  TimerViewModel+ConfigurationDescription.swift
//  Still Moment
//
//  Application Layer - Configuration description labels
//

import Foundation

// MARK: - Configuration Description

extension TimerViewModel {
    /// Label for the preparation pill. `nil` when preparation is disabled.
    var preparationPillLabel: String? {
        guard self.settings.preparationTimeEnabled else {
            return nil
        }
        return String(
            format: NSLocalizedString("praxis.pill.preparation", comment: ""),
            self.settings.preparationTimeSeconds
        )
    }

    /// Label for the start gong pill.
    var gongPillLabel: String {
        GongSound.findOrDefault(byId: self.settings.startGongSoundId).name
    }

    /// Label for the background sound pill.
    var backgroundPillLabel: String {
        if let resolved = self.soundscapeResolver.resolve(id: self.settings.backgroundSoundId) {
            return resolved.displayName
        }
        return NSLocalizedString("praxis.description.silent", comment: "")
    }

    /// Label for the attunement pill. `nil` when attunement is disabled or no attunement is selected.
    var attunementPillLabel: String? {
        guard let attunementId = self.settings.activeAttunementId else {
            return nil
        }
        if let resolved = self.attunementResolver.resolve(id: attunementId) {
            return resolved.displayName
        }
        return NSLocalizedString("praxis.editor.attunement.none", comment: "")
    }

    /// Label for the interval gong pill. `nil` when interval gongs are disabled.
    var intervalPillLabel: String? {
        guard self.settings.intervalGongsEnabled else {
            return nil
        }
        return String(
            format: NSLocalizedString("settings.intervalGongs.stepper", comment: ""),
            self.settings.intervalMinutes
        )
    }
}
