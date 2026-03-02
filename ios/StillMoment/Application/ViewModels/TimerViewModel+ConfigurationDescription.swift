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
        self.resolveBackgroundSoundName(self.settings.backgroundSoundId)
    }

    /// Label for the introduction pill. `nil` when introduction is disabled or no introduction is selected.
    var introductionPillLabel: String? {
        guard let introId = self.settings.activeIntroductionId else {
            return nil
        }
        return self.resolveIntroductionName(introId)
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

    // MARK: - Private Helpers

    private func resolveIntroductionName(_ introId: String) -> String {
        if let intro = Introduction.availableForCurrentLanguage().first(where: { $0.id == introId }) {
            return intro.name
        }
        if let uuid = UUID(uuidString: introId),
           let customFile = self.customAudioRepository.findFile(byId: uuid) {
            return customFile.name
        }
        return NSLocalizedString("praxis.editor.introduction.none", comment: "")
    }

    private func resolveBackgroundSoundName(_ soundId: String) -> String {
        if soundId == "silent" {
            return NSLocalizedString("praxis.description.silent", comment: "")
        }
        if let sound = self.soundRepository.availableSounds.first(where: { $0.id == soundId }) {
            return sound.name
        }
        if let uuid = UUID(uuidString: soundId),
           let customFile = self.customAudioRepository.findFile(byId: uuid) {
            return customFile.name
        }
        return NSLocalizedString("praxis.description.silent", comment: "")
    }
}
