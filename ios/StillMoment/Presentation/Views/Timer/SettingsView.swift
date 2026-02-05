//
//  SettingsView.swift
//  Still Moment
//
//  Presentation Layer - Settings View
//

import OSLog
import SwiftUI

/// Wrapper to persist AudioService across SwiftUI view recreations
private final class AudioServiceHolder: ObservableObject {
    let service: AudioServiceProtocol

    init(service: AudioServiceProtocol = AudioService()) {
        self.service = service
    }
}

/// Settings view for configuring meditation session options
struct SettingsView: View {
    // MARK: Lifecycle

    init(
        settings: Binding<MeditationSettings>,
        onDismiss: @escaping () -> Void,
        soundRepository: BackgroundSoundRepositoryProtocol = BackgroundSoundRepository()
    ) {
        _settings = settings
        self.onDismiss = onDismiss
        self.soundRepository = soundRepository
        self.availableSounds = soundRepository.availableSounds
    }

    // MARK: Internal

    var body: some View {
        NavigationView {
            ZStack {
                // Warm gradient background (consistent with Timer tab)
                self.theme.backgroundGradient
                    .ignoresSafeArea()

                Form {
                    Section {
                        Toggle(isOn: self.$settings.preparationTimeEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.preparationTime.title", bundle: .main)
                                    .settingsLabelStyle()
                                Text("settings.preparationTime.description", bundle: .main)
                                    .settingsDescriptionStyle()
                            }
                        }
                        .accessibilityIdentifier("settings.toggle.preparationTime")
                        .accessibilityLabel("accessibility.preparationTime")
                        .accessibilityHint("accessibility.preparationTime.hint")
                        .listRowBackground(self.theme.backgroundPrimary)

                        if self.settings.preparationTimeEnabled {
                            Picker(
                                NSLocalizedString("settings.preparationTime.duration", comment: ""),
                                selection: self.$settings.preparationTimeSeconds
                            ) {
                                Text("settings.preparationTime.5s", bundle: .main).tag(5)
                                Text("settings.preparationTime.10s", bundle: .main).tag(10)
                                Text("settings.preparationTime.15s", bundle: .main).tag(15)
                                Text("settings.preparationTime.20s", bundle: .main).tag(20)
                                Text("settings.preparationTime.30s", bundle: .main).tag(30)
                                Text("settings.preparationTime.45s", bundle: .main).tag(45)
                            }
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("settings.picker.preparationTimeSeconds")
                            .accessibilityLabel("accessibility.preparationTimeDuration")
                            .accessibilityHint("accessibility.preparationTimeDuration.hint")
                            .listRowBackground(self.theme.backgroundPrimary)
                            .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))
                        }
                    } header: {
                        Text("settings.preparationTime.header", bundle: .main)
                    }

                    Section {
                        Picker(
                            NSLocalizedString("settings.startGong.title", comment: ""),
                            selection: self.$settings.startGongSoundId
                        ) {
                            ForEach(GongSound.allSounds) { sound in
                                Text(sound.name.localized)
                                    .tag(sound.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: self.settings.startGongSoundId) { newValue in
                            self.playGongPreview(soundId: newValue)
                        }
                        .accessibilityIdentifier("settings.picker.startGongSound")
                        .accessibilityLabel("accessibility.startGongSound")
                        .accessibilityHint("accessibility.startGongSound.hint")
                        .listRowBackground(self.theme.backgroundPrimary)

                        // Gong volume slider
                        VolumeSliderRow(
                            volume: self.$settings.gongVolume,
                            accessibilityTitleKey: "settings.gongVolume.title",
                            accessibilityIdentifier: "settings.slider.gongVolume",
                            accessibilityHintKey: "accessibility.gongVolume.hint"
                        ) {
                            self.playGongPreview(soundId: self.settings.startGongSoundId)
                        }

                        Toggle(isOn: self.$settings.intervalGongsEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.intervalGongs.title", bundle: .main)
                                    .settingsLabelStyle()
                                Text("settings.intervalGongs.description", bundle: .main)
                                    .settingsDescriptionStyle()
                            }
                        }
                        .accessibilityIdentifier("settings.toggle.intervalGongs")
                        .accessibilityLabel("accessibility.intervalGongs")
                        .accessibilityHint("accessibility.intervalGongs.hint")
                        .listRowBackground(self.theme.backgroundPrimary)

                        if self.settings.intervalGongsEnabled {
                            VolumeSliderRow(
                                volume: self.$settings.intervalGongVolume,
                                accessibilityTitleKey: "accessibility.intervalGongVolume.title",
                                accessibilityIdentifier: "settings.slider.intervalGongVolume",
                                accessibilityHintKey: "accessibility.intervalGongVolume.hint"
                            ) {
                                self.playIntervalGongPreview()
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))

                            Picker(
                                NSLocalizedString("settings.intervalGongs.interval", comment: ""),
                                selection: self.$settings.intervalMinutes
                            ) {
                                Text("settings.interval.3min", bundle: .main).tag(3)
                                Text("settings.interval.5min", bundle: .main).tag(5)
                                Text("settings.interval.10min", bundle: .main).tag(10)
                            }
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("settings.picker.intervalMinutes")
                            .accessibilityLabel("accessibility.intervalDuration")
                            .accessibilityHint("accessibility.intervalDuration.hint")
                            .listRowBackground(self.theme.backgroundPrimary)
                            .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))
                        }
                    } header: {
                        Text("settings.gong.title", bundle: .main)
                    }

                    Section {
                        Picker(
                            NSLocalizedString("settings.backgroundAudio.sound", comment: ""),
                            selection: self.$settings.backgroundSoundId
                        ) {
                            ForEach(self.availableSounds) { sound in
                                Label(sound.name.localized, systemImage: sound.iconName)
                                    .tag(sound.id)
                                    .accessibilityLabel("\(sound.name.localized). \(sound.description.localized)")
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: self.settings.backgroundSoundId) { newValue in
                            self.playBackgroundPreview(soundId: newValue)
                        }
                        .accessibilityIdentifier("settings.picker.backgroundSound")
                        .accessibilityLabel(
                            NSLocalizedString("settings.backgroundAudio.sound", comment: "")
                        )
                        .accessibilityHint(
                            NSLocalizedString(
                                "settings.backgroundAudio.hint",
                                value: "Select background sound for meditation",
                                comment: "Accessibility hint for sound selection"
                            )
                        )
                        .listRowBackground(self.theme.backgroundPrimary)

                        // Volume slider - only shown when a non-silent sound is selected
                        if self.settings.backgroundSoundId != "silent" {
                            VolumeSliderRow(
                                volume: self.$settings.backgroundSoundVolume,
                                accessibilityTitleKey: "settings.backgroundAudio.volume",
                                accessibilityIdentifier: "settings.slider.backgroundVolume",
                                accessibilityHintKey: "accessibility.backgroundVolume.hint"
                            ) {
                                self.playBackgroundPreview(soundId: self.settings.backgroundSoundId)
                            }
                        }
                    } header: {
                        Text("settings.backgroundAudio.title", bundle: .main)
                    }

                    GeneralSettingsSection()
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(NSLocalizedString("settings.title", comment: ""))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("button.done", comment: "")) {
                            self.dismissWithCleanup()
                        }
                        .tint(self.theme.interactive)
                        .accessibilityIdentifier("button.done")
                        .accessibilityLabel("accessibility.done")
                        .accessibilityHint("accessibility.done.hint")
                    }
                }
            }
        }
        .onDisappear {
            // Stop all previews when sheet is dismissed (swipe or Done button)
            self.audioServiceHolder.service.stopGongPreview()
            self.audioServiceHolder.service.stopBackgroundPreview()
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @Binding private var settings: MeditationSettings
    @StateObject private var audioServiceHolder = AudioServiceHolder()

    private let onDismiss: () -> Void
    private let soundRepository: BackgroundSoundRepositoryProtocol
    private let availableSounds: [BackgroundSound]

    /// Plays gong preview and stops previous preview
    private func playGongPreview(soundId: String) {
        do {
            try self.audioServiceHolder.service.playGongPreview(
                soundId: soundId,
                volume: self.settings.gongVolume
            )
        } catch {
            Logger.audio.error("Failed to play gong preview", error: error, metadata: ["soundId": soundId])
        }
    }

    private func playIntervalGongPreview() {
        do {
            try self.audioServiceHolder.service.playIntervalGong(
                volume: self.settings.intervalGongVolume
            )
        } catch {
            Logger.audio.error("Failed to play interval gong preview", error: error)
        }
    }

    /// Plays background sound preview (service handles "silent" internally)
    private func playBackgroundPreview(soundId: String) {
        do {
            try self.audioServiceHolder.service.playBackgroundPreview(
                soundId: soundId,
                volume: self.settings.backgroundSoundVolume
            )
        } catch {
            Logger.audio.error("Failed to play background preview", error: error, metadata: ["soundId": soundId])
        }
    }

    /// Stops all previews and triggers dismiss
    private func dismissWithCleanup() {
        self.audioServiceHolder.service.stopGongPreview()
        self.audioServiceHolder.service.stopBackgroundPreview()
        self.onDismiss()
    }
}

// MARK: - Volume Slider Row

/// Reusable volume slider row component for settings
/// No visual label - speaker icons are self-explanatory per shared-019/shared-020
private struct VolumeSliderRow: View {
    @Environment(\.themeColors)
    private var theme
    @Binding var volume: Float
    let accessibilityTitleKey: String
    let accessibilityIdentifier: String
    let accessibilityHintKey: String
    let onSliderReleased: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "speaker.fill")
                .foregroundColor(self.theme.textSecondary)
                .font(.settingsIcon)
            Slider(
                value: self.$volume,
                in: 0...1,
                step: 0.01
            ) { editing in
                // Only trigger preview when slider is released (not during drag)
                if !editing {
                    self.onSliderReleased()
                }
            }
            .tint(self.theme.interactive)
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(self.theme.textSecondary)
                .font(.settingsIcon)
        }
        .accessibilityIdentifier(self.accessibilityIdentifier)
        .accessibilityLabel(NSLocalizedString(self.accessibilityTitleKey, comment: ""))
        .accessibilityValue(String(format: "%.0f%%", self.volume * 100))
        .accessibilityHint(NSLocalizedString(self.accessibilityHintKey, comment: ""))
        .listRowBackground(self.theme.backgroundPrimary)
    }
}

// MARK: - Previews

private let defaultSettings = MeditationSettings(
    intervalGongsEnabled: false,
    intervalMinutes: 5,
    backgroundSoundId: "silent"
)

private let forestSettings = MeditationSettings(
    intervalGongsEnabled: true,
    intervalMinutes: 5,
    backgroundSoundId: "forest"
)

@available(iOS 17.0, *)
#Preview("Default Settings") {
    SettingsView(settings: .constant(defaultSettings)) {}
}

@available(iOS 17.0, *)
#Preview("Forest + Intervals") {
    SettingsView(settings: .constant(forestSettings)) {}
}

// Device Size Previews
@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    SettingsView(settings: .constant(forestSettings)) {}
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    SettingsView(settings: .constant(forestSettings)) {}
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    SettingsView(settings: .constant(forestSettings)) {}
}
