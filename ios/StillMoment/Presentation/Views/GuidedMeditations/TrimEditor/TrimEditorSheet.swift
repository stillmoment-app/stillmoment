//
//  TrimEditorSheet.swift
//  Still Moment
//
//  Presentation Layer — full-screen waveform trim editor (shared-107).
//

import SwiftUI

/// Full-screen editor for setting the playback range of a guided meditation via a
/// waveform with two draggable handles. Layout follows the design handoff "View 2":
/// nav row, title + readout, waveform + axis, readout cards, transport, whole-file link.
///
/// The only exit is "Zurück" (shared-112): `onBack` carries the current selection into the
/// outer editor's buffer (nil when the selection is practically the whole file). There is no
/// separate commit or discard — saving and discarding happen exclusively in the outer editor.
struct TrimEditorSheet: View {
    // MARK: Lifecycle

    init(
        meditation: GuidedMeditation,
        audioService: AudioServiceProtocol = AudioService(),
        waveformProvider: WaveformProviderProtocol = WaveformProvider(),
        onBack: @escaping (TimeInterval?, TimeInterval?) -> Void
    ) {
        self.fileDuration = meditation.duration
        self.title = meditation.name
        self.teacher = meditation.teacher
        self.onBack = onBack
        self._viewModel = StateObject(wrappedValue: TrimEditorViewModel(
            meditation: meditation,
            audioService: audioService,
            waveformProvider: waveformProvider
        ))
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                self.navRow
                TrimEditorHeader(
                    title: self.title,
                    teacher: self.teacher,
                    fileDuration: self.fileDuration,
                    activePoint: self.state.activePoint,
                    activeValue: self.state.activeValue,
                    start: self.state.start,
                    end: self.state.end
                )
                TrimWaveformSection(viewModel: self.viewModel)
                TrimReadoutCards(
                    start: self.state.start,
                    end: self.state.end,
                    activePoint: self.state.activePoint
                ) { self.viewModel.focusPoint($0) }
                TrimTransportRow(
                    isPlaying: self.viewModel.isPlaying,
                    onNudge: { self.viewModel.nudgeActivePoint(by: $0) },
                    onTogglePlayback: { self.viewModel.togglePlayback() }
                )
                self.zoneHintText
                Spacer(minLength: 0)
                self.wholeFileLink
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .animation(.easeOut(duration: 0.18), value: self.viewModel.isZoomed)
        }
        .onAppear { self.viewModel.loadWaveform() }
        .onDisappear { self.viewModel.viewDisappeared() }
        .accessibilityIdentifier("trimEditor.sheet")
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    @StateObject private var viewModel: TrimEditorViewModel

    private let fileDuration: TimeInterval
    private let title: String
    private let teacher: String
    private let onBack: (TimeInterval?, TimeInterval?) -> Void

    private var state: TrimEditorState {
        self.viewModel.editorState
    }

    /// Single "Zurück" control (shared-112): it carries the current selection into the outer
    /// editor's buffer rather than discarding it. No "Fertig"/"Verwerfen" — the outer editor
    /// owns the save/discard decision.
    private var navRow: some View {
        ZStack {
            Text("trim_editor.title")
                .textStyle(.section, color: \.textPrimary)
            HStack {
                Button {
                    self.onBack(self.state.resultTrimStart, self.state.resultTrimEnd)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(self.theme.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Text("trim_editor.a11y.back"))
                .accessibilityIdentifier("trimEditor.back")
                Spacer()
            }
        }
    }

    /// Explains the track in user language — overview teaches the zoom, the zoomed
    /// view points at fine dragging and the ±1s nudge.
    private var zoneHintText: some View {
        Text(self.hintKey)
            .textStyle(.caption, color: \.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var hintKey: LocalizedStringKey {
        self.viewModel.isZoomed ? "trim_editor.hint.zoomed" : "trim_editor.hint.overview"
    }

    private var wholeFileLink: some View {
        Button {
            self.viewModel.useWholeFile()
        } label: {
            Text("trim_editor.wholeFile")
                .textStyle(.caption, color: \.textSecondary)
        }
        .accessibilityIdentifier("trimEditor.wholeFile")
    }
}

// MARK: - Previews

#Preview("Trim Editor — Untrimmed") {
    TrimEditorSheet(
        meditation: GuidedMeditation(
            localFilePath: "demo.mp3",
            fileName: "demo.mp3",
            duration: 1145,
            teacher: "Tara Goldstein",
            name: "Evening Wind Down"
        ),
        audioService: MockPreviewAudioService(),
        waveformProvider: PreviewWaveformProvider()
    ) { _, _ in }
}

#Preview("Trim Editor — Trimmed") {
    var meditation = GuidedMeditation(
        localFilePath: "demo.mp3",
        fileName: "demo.mp3",
        duration: 1145,
        teacher: "Tara Goldstein",
        name: "Evening Wind Down"
    )
    meditation.trimStart = 84
    meditation.trimEnd = 1110
    return TrimEditorSheet(
        meditation: meditation,
        audioService: MockPreviewAudioService(),
        waveformProvider: PreviewWaveformProvider()
    ) { _, _ in }
}

#Preview("Trim Editor — Decode Failed") {
    TrimEditorSheet(
        meditation: GuidedMeditation(
            localFilePath: "demo.mp3",
            fileName: "demo.mp3",
            duration: 1145,
            teacher: "Tara Goldstein",
            name: "Evening Wind Down"
        ),
        audioService: MockPreviewAudioService(),
        waveformProvider: PreviewWaveformProvider(shouldFail: true)
    ) { _, _ in }
}
