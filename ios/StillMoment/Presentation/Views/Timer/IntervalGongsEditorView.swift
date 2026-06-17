//
//  IntervalGongsEditorView.swift
//  Still Moment
//
//  Presentation Layer - Interval gongs editor for Praxis editor (redesigned, shared-118).
//

import SwiftUI
import UIKit

/// Editor for interval gong settings within the Praxis editor.
///
/// Card-based layout aligned with `GongSelectionView` (shared-115/118): a top
/// toggle card switches interval gongs on. When enabled, an eyebrow-labelled
/// "INTERVALL" card carries the minutes stepper and the segmented mode picker, a
/// "KLANG" card lists every interval sound as a `GongSoundRow` (preview button,
/// name, character-carrying mini waveform, checkmark for the tinted selection),
/// and a "LAUTSTÄRKE" card holds the manual volume slider — except for the
/// vibration option, which hides the volume card and shows a helper text instead.
///
/// Tapping a sound row selects + previews; tapping the preview button only previews.
struct IntervalGongsEditorView: View {
    // MARK: Lifecycle

    init(viewModel: PraxisSettingsViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    self.headerCard
                    if self.viewModel.intervalGongsEnabled {
                        self.intervalSection
                        self.modeSection
                        self.soundSection
                        if self.isVibrationSelected {
                            self.vibrationHelper
                        }
                        if GongSelectionLogic.isVolumeCardVisible(soundId: self.viewModel.intervalSoundId) {
                            self.volumeSection
                        }
                    } else {
                        self.disabledHelper
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
        }
        .screenTitleBar("praxis.editor.intervalGongs.title")
        .onDisappear {
            self.previewTask?.cancel()
            self.viewModel.stopAllPreviews()
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisSettingsViewModel

    /// ID of the row whose preview is currently sounding (drives the ring).
    @State private var previewingSoundId: String?
    @State private var previewTask: Task<Void, Never>?

    private var isVibrationSelected: Bool {
        self.viewModel.intervalSoundId == GongSound.vibrationId
    }

    private var supportsVibration: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    private var availableIntervalSounds: [GongSound] {
        self.supportsVibration
            ? GongSound.allIntervalSounds
            : GongSound.allIntervalSounds.filter { $0.id != GongSound.vibrationId }
    }

    // MARK: Header card

    private var headerSubtitleKey: String {
        self.viewModel.intervalGongsEnabled
            ? "praxis.intervalGongs.master.subtitle.on"
            : "praxis.intervalGongs.master.subtitle.off"
    }

    private var headerCard: some View {
        Toggle(isOn: self.$viewModel.intervalGongsEnabled) {
            HStack(spacing: 14) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(self.theme.interactive)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("settings.intervalGongs.title", bundle: .main)
                        .textStyle(.body, color: \.textPrimary)
                    Text(LocalizedStringKey(self.headerSubtitleKey), bundle: .main)
                        .textStyle(.caption, color: \.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .themedToggle()
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .modifier(GongCardBackground())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("praxis.editor.toggle.intervalGongs")
    }

    // MARK: Disabled helper

    private var disabledHelper: some View {
        Text("praxis.intervalGongs.disabled.helper")
            .textStyle(.body, color: \.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 14)
    }

    // MARK: Interval (stepper)

    private var intervalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("praxis.intervalGongs.section.interval")
                .textStyle(.eyebrow, color: \.textSecondary)
                .padding(.horizontal, 6)
            self.intervalStepperRow
                .modifier(GongCardBackground())
        }
        .padding(.top, 18)
    }

    private var intervalStepperRow: some View {
        Stepper(value: self.$viewModel.intervalMinutes, in: 1...60) {
            HStack {
                Text("settings.intervalGongs.interval", bundle: .main)
                    .textStyle(.body, color: \.textPrimary)
                Spacer()
                Text(String(
                    format: NSLocalizedString("settings.intervalGongs.stepper", comment: ""),
                    self.viewModel.intervalMinutes
                ))
                .textStyle(.body, color: \.textSecondary)
            }
        }
        .onChange(of: self.viewModel.intervalMinutes) { _ in
            HapticFeedback.impact()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .accessibilityIdentifier("praxis.editor.stepper.intervalMinutes")
        .accessibilityLabel(NSLocalizedString("accessibility.intervalDuration", comment: ""))
        .accessibilityValue(String(
            format: NSLocalizedString("settings.intervalGongs.stepper", comment: ""),
            self.viewModel.intervalMinutes
        ))
        .accessibilityHint(NSLocalizedString("accessibility.intervalDuration.hint", comment: ""))
    }

    // MARK: Mode (segmented + dynamic help)

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("praxis.intervalGongs.section.mode")
                .textStyle(.eyebrow, color: \.textSecondary)
                .padding(.horizontal, 6)
            self.intervalModeRow
                .modifier(GongCardBackground())
            self.modeHelpText
        }
        .padding(.top, 18)
    }

    private var intervalModeRow: some View {
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
        .id(self.theme)
        .onChange(of: self.viewModel.intervalMode) { _ in
            HapticFeedback.selection()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .accessibilityIdentifier("praxis.editor.picker.intervalMode")
        .accessibilityLabel(NSLocalizedString("accessibility.intervalMode", comment: ""))
        .accessibilityHint(NSLocalizedString("accessibility.intervalMode.hint", comment: ""))
    }

    /// Dynamic, plural-correct help text under the mode picker. The interval
    /// minute count selects the plural form (one/other) via the stringsdict.
    private var modeHelpText: some View {
        Text(String.localizedStringWithFormat(
            NSLocalizedString(self.viewModel.intervalMode.modeHelpKey, comment: "Mode help text"),
            self.viewModel.intervalMinutes
        ))
        .textStyle(.body, color: \.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.top, 2)
        .accessibilityIdentifier("praxis.editor.text.modeHelp")
    }

    // MARK: Sound selection

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("praxis.gong.section.sound")
                .textStyle(.eyebrow, color: \.textSecondary)
                .padding(.horizontal, 6)
            self.soundCard
        }
        .padding(.top, 18)
    }

    private var soundCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(self.availableIntervalSounds.enumerated()), id: \.element.id) { index, sound in
                if index > 0 {
                    Divider()
                        .overlay(self.theme.divider)
                }
                GongSoundRow(
                    sound: sound,
                    isSelected: self.viewModel.intervalSoundId == sound.id,
                    isPreviewing: self.previewingSoundId == sound.id,
                    onSelect: {
                        self.viewModel.intervalSoundId = sound.id
                        self.preview(soundId: sound.id)
                    },
                    onPreview: {
                        self.preview(soundId: sound.id)
                    },
                    identifierPrefix: "praxis.intervalGong"
                )
            }
        }
        .modifier(GongCardBackground())
    }

    // MARK: Volume / vibration

    private var vibrationHelper: some View {
        Text("praxis.gong.vibration.helper")
            .textStyle(.body, color: \.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("praxis.gong.section.volume")
                .textStyle(.eyebrow, color: \.textSecondary)
                .padding(.horizontal, 6)
            GongVolumeCard(volume: self.$viewModel.intervalGongVolume) {
                self.preview(soundId: self.viewModel.intervalSoundId)
            }
        }
        .padding(.top, 18)
    }

    /// Plays an interval-gong preview and drives the ring for ~1.5s.
    private func preview(soundId: String) {
        self.viewModel.playIntervalGongPreview(
            soundId: soundId,
            volume: self.viewModel.intervalGongVolume
        )
        self.previewingSoundId = soundId
        self.previewTask?.cancel()
        self.previewTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled, self.previewingSoundId == soundId
            else { return }
            self.previewingSoundId = nil
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Interval Gongs Editor") {
    NavigationStack {
        IntervalGongsEditorView(viewModel: PraxisSettingsViewModel(praxis: .default) { _ in })
    }
}
#endif
