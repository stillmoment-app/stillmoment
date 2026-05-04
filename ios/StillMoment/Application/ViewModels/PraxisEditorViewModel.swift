//
//  PraxisEditorViewModel.swift
//  Still Moment
//
//  Application Layer - ViewModel for editing the current Praxis configuration
//

import Combine
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
        self.intervalGongsEnabled = praxis.intervalGongsEnabled
        self.intervalMinutes = praxis.intervalMinutes
        self.intervalMode = praxis.intervalMode
        self.intervalSoundId = praxis.intervalSoundId
        self.intervalGongVolume = praxis.intervalGongVolume
        self.backgroundSoundId = praxis.backgroundSoundId
        self.backgroundSoundVolume = praxis.backgroundSoundVolume

        self.loadCustomAudio()
        self.setupAutoSave()
    }

    // MARK: Internal

    // MARK: - Published State

    @Published var durationMinutes: Int
    @Published var preparationTimeEnabled: Bool
    @Published var preparationTimeSeconds: Int
    @Published var startGongSoundId: String
    @Published var gongVolume: Float
    @Published var intervalGongsEnabled: Bool
    @Published var intervalMinutes: Int
    @Published var intervalMode: IntervalMode
    @Published var intervalSoundId: String
    @Published var intervalGongVolume: Float
    @Published var backgroundSoundId: String
    @Published var backgroundSoundVolume: Float
    @Published var customSoundscapes: [CustomAudioFile] = []
    @Published var customAudioError: String?
    @Published var isImportingAudio = false

    // MARK: - Computed

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

    /// Stops all active audio previews
    func stopAllPreviews() {
        self.audioService.stopGongPreview()
        self.audioService.stopBackgroundPreview()
    }

    // MARK: - Preparation Time Selection (shared-083)

    /// Selects a preparation time. `nil` means "Off". Live-save persists immediately.
    func selectPreparationTime(seconds: Int?) {
        if let seconds {
            self.preparationTimeSeconds = seconds
            self.preparationTimeEnabled = true
        } else {
            self.preparationTimeEnabled = false
        }
    }

    /// Whether the given preparation-time option is currently selected.
    /// `nil` represents the "Off" option.
    func isPreparationTimeSelected(seconds: Int?) -> Bool {
        if let seconds {
            return self.preparationTimeEnabled && self.preparationTimeSeconds == seconds
        }
        return !self.preparationTimeEnabled
    }

    // MARK: - Custom Audio

    /// Loads custom soundscapes from the repository
    func loadCustomAudio() {
        self.customSoundscapes = self.customAudioRepository.loadAll(type: .soundscape)
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
    /// `var` (not `let`): the owning TimerViewModel rewires this after its own
    /// init has finished so it can pass `[weak self]` without violating Swift's
    /// "self captured before all members initialised" rule.
    var onSaved: (Praxis) -> Void
    private var autoSaveCancellables: Set<AnyCancellable> = []

    /// Wires up automatic persistence: any change to a configuration field triggers
    /// `save()` immediately. The Detail-Views can therefore bind directly to the
    /// `@Published` fields without an explicit save step (shared-083).
    ///
    /// `dropFirst()` skips the initial value emitted on subscription, so init
    /// itself does not write anything to the repository.
    private func setupAutoSave() {
        let publishers: [AnyPublisher<Void, Never>] = [
            self.$durationMinutes.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$preparationTimeEnabled.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$preparationTimeSeconds.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$startGongSoundId.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$gongVolume.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$intervalGongsEnabled.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$intervalMinutes.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$intervalMode.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$intervalSoundId.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$intervalGongVolume.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$backgroundSoundId.dropFirst().map { _ in }.eraseToAnyPublisher(),
            self.$backgroundSoundVolume.dropFirst().map { _ in }.eraseToAnyPublisher()
        ]
        // `@Published` fires in willSet — the property still holds the old value
        // when the sink runs synchronously. `receive(on: RunLoop.main)` defers the
        // sink to the next run-loop tick, after didSet has applied the new value.
        Publishers.MergeMany(publishers)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.save() }
            .store(in: &self.autoSaveCancellables)
    }

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
        }
    }
}
