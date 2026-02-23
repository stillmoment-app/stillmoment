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
        customAudioRepository: CustomAudioRepositoryProtocol = CustomAudioRepository(),
        onSaved: @escaping (Praxis) -> Void,
        onDeleted: @escaping () -> Void
    ) {
        self.praxisId = praxis.id
        self.repository = repository
        self.audioService = audioService
        self.soundRepository = soundRepository
        self.customAudioRepository = customAudioRepository
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

        self.loadCustomAudio()
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
    @Published var customSoundscapes: [CustomAudioFile] = []
    @Published var customAttunements: [CustomAudioFile] = []
    @Published var customAudioError: String?
    @Published var isImportingAudio = false
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

    // MARK: - Custom Audio

    /// Loads custom soundscapes and attunements from the repository
    func loadCustomAudio() {
        self.customSoundscapes = self.customAudioRepository.loadAll(type: .soundscape)
        self.customAttunements = self.customAudioRepository.loadAll(type: .attunement)
    }

    /// Imports a custom audio file of the given type.
    /// On success the list is refreshed and the new file is selected.
    func importCustomAudio(from url: URL, type: CustomAudioType) {
        do {
            let imported = try self.customAudioRepository.importFile(from: url, type: type)
            self.loadCustomAudio()
            // Auto-select the newly imported file
            switch type {
            case .soundscape:
                self.backgroundSoundId = imported.id.uuidString
            case .attunement:
                self.introductionId = imported.id.uuidString
            }
            Logger.viewModel.info(
                "Imported custom audio",
                metadata: ["name": imported.name, "type": type.rawValue]
            )
        } catch {
            self.customAudioError = error.localizedDescription
            Logger.viewModel.error("Failed to import custom audio", error: error)
        }
    }

    /// How many Praxis presets currently use the given custom audio file.
    func usageCount(for file: CustomAudioFile) -> Int {
        let allPraxes = self.repository.loadAll()
        return allPraxes.filter { praxis in
            switch file.type {
            case .soundscape:
                praxis.backgroundSoundId == file.id.uuidString
            case .attunement:
                praxis.introductionId == file.id.uuidString
            }
        }.count
    }

    /// Deletes a custom audio file, updating all affected Praxis presets to fallback values.
    func deleteCustomAudio(_ file: CustomAudioFile) {
        self.resetAffectedPraxes(for: file)
        // Reset current editor selection if it references the deleted file
        switch file.type {
        case .soundscape:
            if self.backgroundSoundId == file.id.uuidString {
                self.backgroundSoundId = "silent"
            }
        case .attunement:
            if self.introductionId == file.id.uuidString {
                self.introductionId = nil
            }
        }
        // Delete the file
        do {
            try self.customAudioRepository.delete(id: file.id)
            self.loadCustomAudio()
            Logger.viewModel.info("Deleted custom audio", metadata: ["name": file.name])
        } catch {
            self.customAudioError = error.localizedDescription
            Logger.viewModel.error("Failed to delete custom audio", error: error)
        }
    }

    // MARK: Private

    private let praxisId: UUID
    private let repository: PraxisRepository
    private let audioService: AudioServiceProtocol
    private let soundRepository: BackgroundSoundRepositoryProtocol
    private let customAudioRepository: CustomAudioRepositoryProtocol
    private let onSaved: (Praxis) -> Void
    private let onDeleted: () -> Void

    /// Updates all Praxis presets that reference the given custom audio file to fallback values.
    private func resetAffectedPraxes(for file: CustomAudioFile) {
        let fileIdString = file.id.uuidString
        let allPraxes = self.repository.loadAll()
        for praxis in allPraxes {
            switch file.type {
            case .soundscape:
                if praxis.backgroundSoundId == fileIdString {
                    self.repository.save(praxis.withBackgroundSoundId("silent"))
                }
            case .attunement:
                if praxis.introductionId == fileIdString {
                    self.repository.save(praxis.withIntroductionId(nil))
                }
            }
        }
    }
}
