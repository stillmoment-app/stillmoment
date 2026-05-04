//
//  TimerViewModel+ConfigurationDescription.swift
//  Still Moment
//
//  Application Layer - Configuration description labels
//

import Foundation

// MARK: - Setting Card Labels (shared-083)

//
// Cards are always visible — Off-State is rendered as a dimmed card. Each card
// therefore needs a non-optional label and a separate `isOff` flag.

extension TimerViewModel {
    /// Card label for preparation time. Shows seconds when enabled, "Aus" otherwise.
    var preparationCardLabel: String {
        guard self.settings.preparationTimeEnabled else {
            return NSLocalizedString("common.off", comment: "")
        }
        return String(
            format: NSLocalizedString("praxis.pill.preparation", comment: ""),
            self.settings.preparationTimeSeconds
        )
    }

    /// Whether the preparation card should render as dimmed (off).
    var preparationCardIsOff: Bool {
        !self.settings.preparationTimeEnabled
    }

    /// Card label for the background sound. Always shows a value — "Stille" is a
    /// deliberate choice and not an off-state.
    var backgroundCardLabel: String {
        if let resolved = self.soundscapeResolver.resolve(id: self.settings.backgroundSoundId) {
            return resolved.displayName
        }
        return NSLocalizedString("praxis.editor.background.silence", comment: "")
    }

    /// Background card is never dimmed — silence is a valid choice.
    var backgroundCardIsOff: Bool {
        false
    }

    /// Card label for the start gong sound.
    var gongCardLabel: String {
        GongSound.findOrDefault(byId: self.settings.startGongSoundId).name
    }

    /// Gong card is never dimmed — a gong is always selected.
    var gongCardIsOff: Bool {
        false
    }

    /// Card label for the interval gong configuration. Shows the cadence when
    /// enabled, "Aus" otherwise.
    var intervalCardLabel: String {
        guard self.settings.intervalGongsEnabled else {
            return NSLocalizedString("common.off", comment: "")
        }
        return String(
            format: NSLocalizedString("settings.intervalGongs.stepper", comment: ""),
            self.settings.intervalMinutes
        )
    }

    /// Whether the interval card should render as dimmed (off).
    var intervalCardIsOff: Bool {
        !self.settings.intervalGongsEnabled
    }
}
