//
//  PraxisEditorViewModel.swift
//  Still Moment
//
//  Application Layer - ViewModel for editing the current Praxis configuration
//

import Foundation
import OSLog

/// ViewModel for the Praxis editor screen.
///
/// Manages editing fields for the single current Praxis configuration,
/// audio preview playback, and save operations with repository persistence.
@MainActor
final class PraxisEditorViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        praxis: Praxis,
        repository: PraxisRepository = UserDefaultsPraxisRepository(),
        audioService: AudioServiceProtocol = AudioService(),
        soundRepository: BackgroundSoundRepositoryProtocol = BackgroundSoundRepository(),
        customAudioRepository: CustomAudioRepositoryProtocol = CustomAudioRepository(),
        onSaved: @escaping (Praxis) -> Void
    ) {
        self.praxisId = praxis.id
        self.repository = repository
        self.audioService = audioService
        self.soundRepository = soundRepository
        self.customAudioRepository = customAudioRepository
        self.onSaved = onSaved

        // Initialize published fields from Praxis
        self.durationMinutes = praxis.durationMinutes
        self.preparationTimeEnabled = praxis.preparationTimeEnabled
        self.preparationTimeSeconds = praxis.preparationTimeSeconds
        self.startGongSoundId = praxis.startGongSoundId
        self.gongVolume = praxis.gongVolume
        self.attunementId = praxis.attunementId
        self.attunementEnabled = praxis.attunementEnabled
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

    @Published var durationMinutes: Int
    @Published var preparationTimeEnabled: Bool
    @Published var preparationTimeSeconds: Int
    @Published var startGongSoundId: String
    @Published var gongVolume: Float
    @Published var attunementId: String?
    @Published var attunementEnabled: Bool
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

    // MARK: - Computed

    /// Attunements available for the current device language
    var availableAttunements: [Attunement] {
        Attunement.availableForCurrentLanguage()
    }

    /// All available background sounds from the repository
    var availableBackgroundSounds: [BackgroundSound] {
        self.soundRepository.availableSounds
    }

    // MARK: - Actions

    /// Creates a new Praxis with current state, saves it, and calls onSaved
    func save() {
        let savedPraxis = Praxis(
            id: self.praxisId,
            durationMinutes: self.durationMinutes,
            preparationTimeEnabled: self.preparationTimeEnabled,
            preparationTimeSeconds: self.preparationTimeSeconds,
            startGongSoundId: self.startGongSoundId,
            gongVolume: self.gongVolume,
            attunementId: self.attunementId,
            attunementEnabled: self.attunementEnabled,
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
        Logger.viewModel.info("Saved praxis configuration")
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

    /// Plays a preview of an attunement or custom attunement
    func playAttunementPreview(attunementId: String) {
        do {
            try self.audioService.playAttunementPreview(attunementId: attunementId)
        } catch {
            Logger.audio.error(
                "Failed to play attunement preview",
                error: error,
                metadata: ["attunementId": attunementId]
            )
        }
    }

    /// Stops all active audio previews
    func stopAllPreviews() {
        self.audioService.stopGongPreview()
        self.audioService.stopBackgroundPreview()
        self.audioService.stopAttunementPreview()
    }

    /// Enables or disables the attunement toggle.
    /// When enabling with no attunement selected, auto-selects the first available.
    func setAttunementEnabled(_ enabled: Bool) {
        self.attunementEnabled = enabled
        if enabled, self.attunementId == nil {
            self.attunementId = self.availableAttunements.first?.id
        }
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
                self.attunementId = imported.id.uuidString
                self.attunementEnabled = true
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

    /// How many times the given custom audio file is used in the current configuration.
    func usageCount(for file: CustomAudioFile) -> Int {
        let praxis = self.repository.load()
        switch file.type {
        case .soundscape:
            return praxis.backgroundSoundId == file.id.uuidString ? 1 : 0
        case .attunement:
            return praxis.attunementId == file.id.uuidString ? 1 : 0
        }
    }

    /// Renames a custom audio file. Trims whitespace; ignores empty names.
    func renameCustomAudio(_ file: CustomAudioFile, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        do {
            try self.customAudioRepository.update(file.withName(trimmed))
            self.loadCustomAudio()
            Logger.viewModel.info("Renamed custom audio", metadata: ["name": trimmed])
        } catch {
            self.customAudioError = error.localizedDescription
            Logger.viewModel.error("Failed to rename custom audio", error: error)
        }
    }

    /// Deletes a custom audio file, resetting the current configuration if it references the file.
    func deleteCustomAudio(_ file: CustomAudioFile) {
        self.resetConfigurationIfAffected(by: file)
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

    /// Resets the current editor selection and saved configuration if it references the given file.
    private func resetConfigurationIfAffected(by file: CustomAudioFile) {
        let fileIdString = file.id.uuidString
        let praxis = self.repository.load()
        switch file.type {
        case .soundscape:
            if praxis.backgroundSoundId == fileIdString {
                self.repository.save(praxis.withBackgroundSoundId("silent"))
            }
            if self.backgroundSoundId == fileIdString {
                self.backgroundSoundId = "silent"
            }
        case .attunement:
            if praxis.attunementId == fileIdString {
                self.repository.save(praxis.withAttunementId(nil).withAttunementEnabled(false))
            }
            if self.attunementId == fileIdString {
                self.attunementId = nil
                self.attunementEnabled = false
            }
        }
    }
}
