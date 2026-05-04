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

#if DEBUG
extension TimerViewModel {
    /// Creates a view model with mocked services for SwiftUI previews
    static func preview(state: TimerState = .idle) -> TimerViewModel {
        let viewModel = TimerViewModel()

        switch state {
        case .idle:
            break // timer stays nil
        case .preparation:
            viewModel.timer = .stub(
                remainingSeconds: 600,
                state: .preparation,
                remainingPreparationSeconds: 10
            )
        case .startGong:
            viewModel.timer = .stub(remainingSeconds: 597, state: .startGong)
        case .running:
            viewModel.timer = .stub(remainingSeconds: 300, state: .running)
        case .endGong:
            viewModel.timer = .stub(remainingSeconds: 0, state: .endGong)
        case .completed:
            viewModel.timer = .stub(remainingSeconds: 0, state: .completed)
        }

        return viewModel
    }
}
#endif
