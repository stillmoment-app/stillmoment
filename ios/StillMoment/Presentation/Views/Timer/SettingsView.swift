//
//  SettingsView.swift
//  Still Moment
//
//  Presentation Layer - Settings View (pure view, no services)
//

import SwiftUI

/// Settings view for configuring meditation session options
///
/// Pure presentation view — receives data and callbacks, holds no services.
/// Audio preview logic lives in TimerViewModel (ios-033).
struct SettingsView: View {
    // MARK: Lifecycle

    init(
        settings: Binding<MeditationSettings>,
        availableSounds: [BackgroundSound],
        onGongChanged: @escaping (String, Float) -> Void,
        onBackgroundChanged: @escaping (String, Float) -> Void,
        onIntervalGongPreview: @escaping (Float) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _settings = settings
        self.availableSounds = availableSounds
        self.onGongChanged = onGongChanged
        self.onBackgroundChanged = onBackgroundChanged
        self.onIntervalGongPreview = onIntervalGongPreview
        self.onDismiss = onDismiss
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
                                    .themeFont(.settingsLabel)
                                Text("settings.preparationTime.description", bundle: .main)
                                    .themeFont(.settingsDescription)
                            }
                        }
                        .accessibilityIdentifier("settings.toggle.preparationTime")
                        .accessibilityLabel("accessibility.preparationTime")
                        .accessibilityHint("accessibility.preparationTime.hint")
                        .listRowBackground(self.theme.backgroundPrimary)

                        if self.settings.preparationTimeEnabled {
                            Picker(selection: self.$settings.preparationTimeSeconds) {
                                Text("settings.preparationTime.5s", bundle: .main).tag(5)
                                Text("settings.preparationTime.10s", bundle: .main).tag(10)
                                Text("settings.preparationTime.15s", bundle: .main).tag(15)
                                Text("settings.preparationTime.20s", bundle: .main).tag(20)
                                Text("settings.preparationTime.30s", bundle: .main).tag(30)
                                Text("settings.preparationTime.45s", bundle: .main).tag(45)
                            } label: {
                                Text("settings.preparationTime.duration", bundle: .main)
                                    .themeFont(.settingsLabel)
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
                            .foregroundColor(self.theme.textSecondary)
                    }

                    Section {
                        Picker(selection: self.$settings.startGongSoundId) {
                            ForEach(GongSound.allSounds) { sound in
                                Text(sound.name.localized)
                                    .tag(sound.id)
                            }
                        } label: {
                            Text("settings.startGong.title", bundle: .main)
                                .themeFont(.settingsLabel)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: self.settings.startGongSoundId) { newValue in
                            self.onGongChanged(newValue, self.settings.gongVolume)
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
                            self.onGongChanged(self.settings.startGongSoundId, self.settings.gongVolume)
                        }

                        Toggle(isOn: self.$settings.intervalGongsEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("settings.intervalGongs.title", bundle: .main)
                                    .themeFont(.settingsLabel)
                                Text("settings.intervalGongs.description", bundle: .main)
                                    .themeFont(.settingsDescription)
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
                                self.onIntervalGongPreview(self.settings.intervalGongVolume)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))

                            Picker(selection: self.$settings.intervalMinutes) {
                                Text("settings.interval.3min", bundle: .main).tag(3)
                                Text("settings.interval.5min", bundle: .main).tag(5)
                                Text("settings.interval.10min", bundle: .main).tag(10)
                            } label: {
                                Text("settings.intervalGongs.interval", bundle: .main)
                                    .themeFont(.settingsLabel)
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
                            .foregroundColor(self.theme.textSecondary)
                    }

                    Section {
                        Picker(selection: self.$settings.backgroundSoundId) {
                            ForEach(self.availableSounds) { sound in
                                Label(sound.name.localized, systemImage: sound.iconName)
                                    .tag(sound.id)
                                    .accessibilityLabel("\(sound.name.localized). \(sound.description.localized)")
                            }
                        } label: {
                            Text("settings.backgroundAudio.sound", bundle: .main)
                                .themeFont(.settingsLabel)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: self.settings.backgroundSoundId) { newValue in
                            self.onBackgroundChanged(newValue, self.settings.backgroundSoundVolume)
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
                                self.onBackgroundChanged(
                                    self.settings.backgroundSoundId,
                                    self.settings.backgroundSoundVolume
                                )
                            }
                        }
                    } header: {
                        Text("settings.backgroundAudio.title", bundle: .main)
                            .foregroundColor(self.theme.textSecondary)
                    }

                    GeneralSettingsSection()
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(NSLocalizedString("settings.title", comment: ""))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("button.done", comment: "")) {
                            self.onDismiss()
                        }
                        .tint(self.theme.interactive)
                        .accessibilityIdentifier("button.done")
                        .accessibilityLabel("accessibility.done")
                        .accessibilityHint("accessibility.done.hint")
                    }
                }
            }
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @Binding private var settings: MeditationSettings

    private let availableSounds: [BackgroundSound]
    private let onGongChanged: (String, Float) -> Void
    private let onBackgroundChanged: (String, Float) -> Void
    private let onIntervalGongPreview: (Float) -> Void
    private let onDismiss: () -> Void
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
    SettingsView(
        settings: .constant(defaultSettings),
        availableSounds: [],
        onGongChanged: { _, _ in },
        onBackgroundChanged: { _, _ in },
        onIntervalGongPreview: { _ in },
        onDismiss: {}
    )
}

@available(iOS 17.0, *)
#Preview("Forest + Intervals") {
    SettingsView(
        settings: .constant(forestSettings),
        availableSounds: [],
        onGongChanged: { _, _ in },
        onBackgroundChanged: { _, _ in },
        onIntervalGongPreview: { _ in },
        onDismiss: {}
    )
}

// Device Size Previews
@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    SettingsView(
        settings: .constant(forestSettings),
        availableSounds: [],
        onGongChanged: { _, _ in },
        onBackgroundChanged: { _, _ in },
        onIntervalGongPreview: { _ in },
        onDismiss: {}
    )
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    SettingsView(
        settings: .constant(forestSettings),
        availableSounds: [],
        onGongChanged: { _, _ in },
        onBackgroundChanged: { _, _ in },
        onIntervalGongPreview: { _ in },
        onDismiss: {}
    )
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    SettingsView(
        settings: .constant(forestSettings),
        availableSounds: [],
        onGongChanged: { _, _ in },
        onBackgroundChanged: { _, _ in },
        onIntervalGongPreview: { _ in },
        onDismiss: {}
    )
}
