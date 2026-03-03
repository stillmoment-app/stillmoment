//
//  IntervalGongsEditorView.swift
//  Still Moment
//
//  Presentation Layer - Interval gongs editor for Praxis editor
//

import SwiftUI

/// Editor for interval gong settings within the Praxis editor.
///
/// Provides a toggle, stepper for minutes, mode picker, sound picker,
/// and volume slider. Controls below the toggle only appear when enabled.
struct IntervalGongsEditorView: View {
    // MARK: Lifecycle

    init(viewModel: PraxisEditorViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            Form {
                self.intervalGongsSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("praxis.editor.intervalGongs.title", bundle: .main)
                    .themeFont(.inlineNavigationTitle)
            }
        }
        .onDisappear {
            self.viewModel.stopAllPreviews()
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisEditorViewModel

    private var intervalGongsSection: some View {
        Section {
            Toggle(isOn: self.$viewModel.intervalGongsEnabled) {
                Text("settings.intervalGongs.title", bundle: .main)
                    .themeFont(.settingsLabel)
            }
            .themedToggle()
            .cardRowBackground()
            .accessibilityIdentifier("praxis.editor.toggle.intervalGongs")

            if self.viewModel.intervalGongsEnabled {
                self.intervalStepperRow
                self.intervalModePicker
                self.intervalSoundPicker
                self.intervalVolumeSlider
            }
        }
    }

    private var intervalStepperRow: some View {
        Stepper(value: self.$viewModel.intervalMinutes, in: 1...60) {
            HStack {
                Text("settings.intervalGongs.interval", bundle: .main)
                    .themeFont(.settingsLabel)
                Spacer()
                Text(String(
                    format: NSLocalizedString("settings.intervalGongs.stepper", comment: ""),
                    self.viewModel.intervalMinutes
                ))
                .themeFont(.settingsLabel, color: \.textSecondary)
            }
        }
        .onChange(of: self.viewModel.intervalMinutes) { _ in
            HapticFeedback.impact()
        }
        .accessibilityIdentifier("praxis.editor.stepper.intervalMinutes")
        .accessibilityLabel(NSLocalizedString("accessibility.intervalDuration", comment: ""))
        .accessibilityValue(String(
            format: NSLocalizedString("settings.intervalGongs.stepper", comment: ""),
            self.viewModel.intervalMinutes
        ))
        .accessibilityHint(NSLocalizedString("accessibility.intervalDuration.hint", comment: ""))
        .cardRowBackground()
    }

    private var intervalModePicker: some View {
        Picker(selection: self.$viewModel.intervalMode) {
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
        .onChange(of: self.viewModel.intervalMode) { _ in
            HapticFeedback.selection()
        }
        .accessibilityIdentifier("praxis.editor.picker.intervalMode")
        .accessibilityLabel(NSLocalizedString("accessibility.intervalMode", comment: ""))
        .accessibilityHint(NSLocalizedString("accessibility.intervalMode.hint", comment: ""))
        .cardRowBackground()
    }

    private var intervalSoundPicker: some View {
        Picker(selection: self.$viewModel.intervalSoundId) {
            ForEach(GongSound.allIntervalSounds) { sound in
                Text(sound.name)
                    .tag(sound.id)
            }
        } label: {
            Text("settings.intervalGongs.sound", bundle: .main)
                .themeFont(.settingsLabel)
        }
        .pickerStyle(.menu)
        .onChange(of: self.viewModel.intervalSoundId) { newValue in
            HapticFeedback.selection()
            self.viewModel.playIntervalGongPreview(
                soundId: newValue,
                volume: self.viewModel.intervalGongVolume
            )
        }
        .accessibilityIdentifier("praxis.editor.picker.intervalSound")
        .accessibilityLabel(NSLocalizedString("accessibility.intervalSound", comment: ""))
        .accessibilityHint(NSLocalizedString("accessibility.intervalSound.hint", comment: ""))
        .cardRowBackground()
    }

    private var intervalVolumeSlider: some View {
        VolumeSliderRow(
            volume: self.$viewModel.intervalGongVolume,
            accessibilityTitleKey: "accessibility.intervalGongVolume.title",
            accessibilityIdentifier: "praxis.editor.slider.intervalGongVolume",
            accessibilityHintKey: "accessibility.intervalGongVolume.hint"
        ) {
            self.viewModel.playIntervalGongPreview(
                soundId: self.viewModel.intervalSoundId,
                volume: self.viewModel.intervalGongVolume
            )
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Interval Gongs Editor") {
    NavigationStack {
        IntervalGongsEditorView(viewModel: PraxisEditorViewModel(praxis: .default) { _ in })
    }
}
#endif
