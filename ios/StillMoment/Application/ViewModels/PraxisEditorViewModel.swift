//
//  PraxisEditorViewModel.swift
//  Still Moment
//
//  Application Layer - ViewModel for editing a Praxis
//

import Foundation
import OSLog

/// ViewModel for the Praxis editor screen.
///
/// Manages editing fields for a single Praxis, audio preview playback,
/// and save/delete operations with repository persistence.
@MainActor
final class PraxisEditorViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        praxis: Praxis,
        repository: PraxisRepository = UserDefaultsPraxisRepository(),
        audioService: AudioServiceProtocol = AudioService(),
        soundRepository: BackgroundSoundRepositoryProtocol = BackgroundSoundRepository(),
        onSaved: @escaping (Praxis) -> Void,
        onDeleted: @escaping () -> Void
    ) {
        self.praxisId = praxis.id
        self.repository = repository
        self.audioService = audioService
        self.soundRepository = soundRepository
        self.onSaved = onSaved
        self.onDeleted = onDeleted

        // Initialize published fields from Praxis
        self.name = praxis.name
        self.durationMinutes = praxis.durationMinutes
        self.preparationTimeEnabled = praxis.preparationTimeEnabled
        self.preparationTimeSeconds = praxis.preparationTimeSeconds
        self.startGongSoundId = praxis.startGongSoundId
        self.gongVolume = praxis.gongVolume
        self.introductionId = praxis.introductionId
        self.intervalGongsEnabled = praxis.intervalGongsEnabled
        self.intervalMinutes = praxis.intervalMinutes
        self.intervalMode = praxis.intervalMode
        self.intervalSoundId = praxis.intervalSoundId
        self.intervalGongVolume = praxis.intervalGongVolume
        self.backgroundSoundId = praxis.backgroundSoundId
        self.backgroundSoundVolume = praxis.backgroundSoundVolume
    }

    // MARK: Internal

    // MARK: - Published State

    @Published var name: String
    @Published var durationMinutes: Int
    @Published var preparationTimeEnabled: Bool
    @Published var preparationTimeSeconds: Int
    @Published var startGongSoundId: String
    @Published var gongVolume: Float
    @Published var introductionId: String?
    @Published var intervalGongsEnabled: Bool
    @Published var intervalMinutes: Int
    @Published var intervalMode: IntervalMode
    @Published var intervalSoundId: String
    @Published var intervalGongVolume: Float
    @Published var backgroundSoundId: String
    @Published var backgroundSoundVolume: Float
    @Published var showDeleteConfirmation = false
    @Published var errorMessage: String?

    // MARK: - Computed

    /// Whether the current name is valid for saving
    var canSave: Bool {
        !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Introductions available for the current device language
    var availableIntroductions: [Introduction] {
        Introduction.availableForCurrentLanguage()
    }

    /// All available background sounds from the repository
    var availableBackgroundSounds: [BackgroundSound] {
        self.soundRepository.availableSounds
    }

    // MARK: - Actions

    /// Creates a new Praxis with current state, saves it, and calls onSaved
    func save() {
        let trimmedName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedPraxis = Praxis(
            id: self.praxisId,
            name: trimmedName,
            durationMinutes: self.durationMinutes,
            preparationTimeEnabled: self.preparationTimeEnabled,
            preparationTimeSeconds: self.preparationTimeSeconds,
            startGongSoundId: self.startGongSoundId,
            gongVolume: self.gongVolume,
            introductionId: self.introductionId,
            intervalGongsEnabled: self.intervalGongsEnabled,
            intervalMinutes: self.intervalMinutes,
            intervalMode: self.intervalMode,
            intervalSoundId: self.intervalSoundId,
            intervalGongVolume: self.intervalGongVolume,
            backgroundSoundId: self.backgroundSoundId,
            backgroundSoundVolume: self.backgroundSoundVolume
        )
        self.repository.save(savedPraxis)
        self.onSaved(savedPraxis)
        Logger.viewModel.info("Saved praxis", metadata: ["name": trimmedName])
    }

    /// Shows the delete confirmation dialog
    func requestDelete() {
        self.showDeleteConfirmation = true
    }

    /// Confirms deletion: removes from repository and calls onDeleted
    func confirmDelete() {
        do {
            try self.repository.delete(id: self.praxisId)
            self.onDeleted()
            Logger.viewModel.info("Deleted praxis", metadata: ["id": self.praxisId.uuidString])
        } catch PraxisRepositoryError.cannotDeleteLastPraxis {
            self.errorMessage = NSLocalizedString("praxis.delete.error.lastPraxis", comment: "")
            Logger.viewModel.error("Cannot delete last praxis")
        } catch {
            self.errorMessage = error.localizedDescription
            Logger.viewModel.error("Failed to delete praxis", error: error)
        }
    }

    // MARK: - Audio Preview

    /// Plays a gong sound preview
    func playGongPreview(soundId: String, volume: Float) {
        do {
            try self.audioService.playGongPreview(soundId: soundId, volume: volume)
        } catch {
            Logger.audio.error("Failed to play gong preview", error: error, metadata: ["soundId": soundId])
        }
    }

    /// Plays an interval gong preview
    func playIntervalGongPreview(soundId: String, volume: Float) {
        do {
            try self.audioService.playGongPreview(soundId: soundId, volume: volume)
        } catch {
            Logger.audio.error("Failed to play interval gong preview", error: error)
        }
    }

    /// Plays a background sound preview
    func playBackgroundPreview(soundId: String, volume: Float) {
        do {
            try self.audioService.playBackgroundPreview(soundId: soundId, volume: volume)
        } catch {
            Logger.audio.error("Failed to play background preview", error: error, metadata: ["soundId": soundId])
        }
    }

    /// Stops all active audio previews
    func stopAllPreviews() {
        self.audioService.stopGongPreview()
        self.audioService.stopBackgroundPreview()
    }

    // MARK: Private

    private let praxisId: UUID
    private let repository: PraxisRepository
    private let audioService: AudioServiceProtocol
    private let soundRepository: BackgroundSoundRepositoryProtocol
    private let onSaved: (Praxis) -> Void
    private let onDeleted: () -> Void
}
