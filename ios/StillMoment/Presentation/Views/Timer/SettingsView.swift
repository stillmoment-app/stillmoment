//
//  SettingsView.swift
//  Still Moment
//
//  Presentation Layer - Settings View (pure view, no services)
//

import SwiftUI
import UIKit

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
        onIntervalGongPreview: @escaping (String, Float) -> Void,
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
                    self.preparationTimeSection
                    self.gongSection
                    self.intervalGongsSection
                    self.backgroundAudioSection

                    GeneralSettingsSection()
                }
                .scrollContentBackground(.hidden)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("settings.title", bundle: .main)
                            .themeFont(.inlineNavigationTitle)
                    }
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
    private let onIntervalGongPreview: (String, Float) -> Void
    private let onDismiss: () -> Void

    // MARK: - Preparation Time Section

    private var preparationTimeSection: some View {
        Section {
            Toggle(isOn: self.$settings.preparationTimeEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.preparationTime.title", bundle: .main)
                        .themeFont(.settingsLabel)
                    Text("settings.preparationTime.description", bundle: .main)
                        .themeFont(.settingsDescription)
                }
            }
            .themedToggle()
            .accessibilityIdentifier("settings.toggle.preparationTime")
            .accessibilityLabel("accessibility.preparationTime")
            .accessibilityHint("accessibility.preparationTime.hint")
            .cardRowBackground()

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
                .onChange(of: self.settings.preparationTimeSeconds) { _ in
                    UISelectionFeedbackGenerator().selectionChanged()
                }
                .cardRowBackground()
                .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))
            }
        } header: {
            Text("settings.preparationTime.header", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    // MARK: - Gong Section (start/end gong only)

    private var gongSection: some View {
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
                UISelectionFeedbackGenerator().selectionChanged()
                self.onGongChanged(newValue, self.settings.gongVolume)
            }
            .accessibilityIdentifier("settings.picker.startGongSound")
            .accessibilityLabel("accessibility.startGongSound")
            .accessibilityHint("accessibility.startGongSound.hint")
            .cardRowBackground()

            // Gong volume slider
            VolumeSliderRow(
                volume: self.$settings.gongVolume,
                accessibilityTitleKey: "settings.gongVolume.title",
                accessibilityIdentifier: "settings.slider.gongVolume",
                accessibilityHintKey: "accessibility.gongVolume.hint"
            ) {
                self.onGongChanged(self.settings.startGongSoundId, self.settings.gongVolume)
            }
        } header: {
            Text("settings.gong.title", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    // MARK: - Interval Gongs Section

    private var intervalGongsSection: some View {
        Section {
            Toggle(isOn: self.$settings.intervalGongsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.intervalGongs.title", bundle: .main)
                        .themeFont(.settingsLabel)
                    Text(self.intervalGongsDescription)
                        .themeFont(.settingsDescription)
                }
            }
            .themedToggle()
            .accessibilityIdentifier("settings.toggle.intervalGongs")
            .accessibilityLabel("accessibility.intervalGongs")
            .accessibilityHint("accessibility.intervalGongs.hint")
            .cardRowBackground()

            if self.settings.intervalGongsEnabled {
                self.intervalStepperRow
                self.intervalModePicker
                self.intervalSoundPicker
                self.intervalVolumeSlider
            }
        } header: {
            Text("settings.intervalGongs.header", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    /// Dynamic description for interval gongs toggle
    private var intervalGongsDescription: String {
        guard self.settings.intervalGongsEnabled else {
            return NSLocalizedString("settings.intervalGongs.description", comment: "")
        }

        let soundName = GongSound.findOrDefault(byId: self.settings.intervalSoundId).name.localized
        let minutes = self.settings.intervalMinutes

        let key = switch self.settings.intervalMode {
        case .repeating:
            "settings.intervalGongs.description.repeating"
        case .afterStart:
            "settings.intervalGongs.description.afterStart"
        case .beforeEnd:
            "settings.intervalGongs.description.beforeEnd"
        }
        return String(format: NSLocalizedString(key, comment: ""), minutes, soundName)
    }

    /// Stepper row for interval minutes (1-60)
    private var intervalStepperRow: some View {
        Stepper(value: self.$settings.intervalMinutes, in: 1...60) {
            HStack {
                Text("settings.intervalGongs.interval", bundle: .main)
                    .themeFont(.settingsLabel)
                Spacer()
                Text(String(
                    format: NSLocalizedString("settings.intervalGongs.stepper", comment: ""),
                    self.settings.intervalMinutes
                ))
                .themeFont(.settingsLabel, color: \.textSecondary)
            }
        }
        .onChange(of: self.settings.intervalMinutes) { _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .accessibilityIdentifier("settings.stepper.intervalMinutes")
        .accessibilityLabel(NSLocalizedString("accessibility.intervalDuration", comment: ""))
        .accessibilityValue(String(
            format: NSLocalizedString("settings.intervalGongs.stepper", comment: ""),
            self.settings.intervalMinutes
        ))
        .accessibilityHint(NSLocalizedString("accessibility.intervalDuration.hint", comment: ""))
        .cardRowBackground()
        .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))
    }

    /// Mode picker for interval gongs (repeating, after start, before end)
    private var intervalModePicker: some View {
        Picker(selection: self.$settings.intervalMode) {
            Text("settings.intervalMode.repeating", bundle: .main)
                .tag(IntervalMode.repeating)
            Text("settings.intervalMode.afterStart", bundle: .main)
                .tag(IntervalMode.afterStart)
            Text("settings.intervalMode.beforeEnd", bundle: .main)
                .tag(IntervalMode.beforeEnd)
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
        .onChange(of: self.settings.intervalMode) { _ in
            UISelectionFeedbackGenerator().selectionChanged()
        }
        .accessibilityIdentifier("settings.picker.intervalMode")
        .accessibilityLabel(NSLocalizedString("accessibility.intervalMode", comment: ""))
        .accessibilityHint(NSLocalizedString("accessibility.intervalMode.hint", comment: ""))
        .cardRowBackground()
        .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))
    }

    /// Sound picker for interval gongs (5 options)
    private var intervalSoundPicker: some View {
        Picker(selection: self.$settings.intervalSoundId) {
            ForEach(GongSound.allIntervalSounds) { sound in
                Text(sound.name.localized)
                    .tag(sound.id)
            }
        } label: {
            Text("settings.intervalGongs.sound", bundle: .main)
                .themeFont(.settingsLabel)
        }
        .pickerStyle(.menu)
        .onChange(of: self.settings.intervalSoundId) { newValue in
            UISelectionFeedbackGenerator().selectionChanged()
            self.onIntervalGongPreview(newValue, self.settings.intervalGongVolume)
        }
        .accessibilityIdentifier("settings.picker.intervalSound")
        .accessibilityLabel(NSLocalizedString("accessibility.intervalSound", comment: ""))
        .accessibilityHint(NSLocalizedString("accessibility.intervalSound.hint", comment: ""))
        .cardRowBackground()
        .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))
    }

    /// Volume slider for interval gongs
    private var intervalVolumeSlider: some View {
        VolumeSliderRow(
            volume: self.$settings.intervalGongVolume,
            accessibilityTitleKey: "accessibility.intervalGongVolume.title",
            accessibilityIdentifier: "settings.slider.intervalGongVolume",
            accessibilityHintKey: "accessibility.intervalGongVolume.hint"
        ) {
            self.onIntervalGongPreview(self.settings.intervalSoundId, self.settings.intervalGongVolume)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))
    }

    // MARK: - Background Audio Section

    private var backgroundAudioSection: some View {
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
                UISelectionFeedbackGenerator().selectionChanged()
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
            .cardRowBackground()

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
            ThemedSlider(
                value: Binding(
                    get: { Double(self.volume) },
                    set: { self.volume = Float($0) }
                ),
                range: 0...1,
                step: 0.01
            ) { editing in
                if !editing {
                    self.onSliderReleased()
                }
            }
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(self.theme.textSecondary)
                .font(.settingsIcon)
        }
        .accessibilityIdentifier(self.accessibilityIdentifier)
        .accessibilityLabel(NSLocalizedString(self.accessibilityTitleKey, comment: ""))
        .accessibilityValue(String(format: "%.0f%%", self.volume * 100))
        .accessibilityHint(NSLocalizedString(self.accessibilityHintKey, comment: ""))
        .cardRowBackground()
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
        onIntervalGongPreview: { _, _ in },
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
        onIntervalGongPreview: { _, _ in },
        onDismiss: {}
    )
}
