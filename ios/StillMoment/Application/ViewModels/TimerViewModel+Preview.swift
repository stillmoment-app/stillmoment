//
//  TimerViewModel+Preview.swift
//  Still Moment
//
//  Application Layer - Audio Preview & SwiftUI Preview Support
//

import OSLog

// MARK: - Audio Preview (for Settings UI)

extension TimerViewModel {
    /// All available background sounds from the repository
    var availableBackgroundSounds: [BackgroundSound] {
        self.soundRepository.availableSounds
    }

    /// Introductions available for the current device language
    var availableIntroductions: [Introduction] {
        Introduction.availableForCurrentLanguage()
    }

    /// Plays a gong sound preview when user changes gong selection in settings
    func playGongPreview(soundId: String, volume: Float) {
        do {
            try self.audioService.playGongPreview(soundId: soundId, volume: volume)
        } catch {
            Logger.audio.error("Failed to play gong preview", error: error, metadata: ["soundId": soundId])
        }
    }

    /// Plays an interval gong preview when user changes interval sound or adjusts volume in settings
    func playIntervalGongPreview(soundId: String, volume: Float) {
        do {
            try self.audioService.playGongPreview(soundId: soundId, volume: volume)
        } catch {
            Logger.audio.error("Failed to play interval gong preview", error: error)
        }
    }

    /// Plays a background sound preview when user changes background sound in settings
    func playBackgroundPreview(soundId: String, volume: Float) {
        do {
            try self.audioService.playBackgroundPreview(soundId: soundId, volume: volume)
        } catch {
            Logger.audio.error("Failed to play background preview", error: error, metadata: ["soundId": soundId])
        }
    }

    /// Stops all active audio previews (called on settings dismiss)
    func stopAllPreviews() {
        self.audioService.stopGongPreview()
        self.audioService.stopBackgroundPreview()
    }
}

// MARK: - SwiftUI Preview Support

extension TimerViewModel {
    /// Creates a view model with mocked services for SwiftUI previews
    static func preview(state: TimerState = .idle) -> TimerViewModel {
        let viewModel = TimerViewModel()

        var newState = viewModel.displayState
        newState.timerState = state

        switch state {
        case .idle:
            newState.remainingSeconds = 0
            newState.totalSeconds = 600
        case .preparation:
            newState.remainingSeconds = 600
            newState.totalSeconds = 600
            newState.remainingPreparationSeconds = 10
        case .startGong:
            newState.remainingSeconds = 597
            newState.totalSeconds = 600
            newState.progress = 0.005
        case .introduction:
            newState.remainingSeconds = 505
            newState.totalSeconds = 600
            newState.progress = 0.158
        case .running:
            newState.remainingSeconds = 300
            newState.totalSeconds = 600
            newState.progress = 0.5
        case .completed:
            newState.remainingSeconds = 0
            newState.totalSeconds = 600
            newState.progress = 1.0
        }

        viewModel.displayState = newState
        return viewModel
    }
}
