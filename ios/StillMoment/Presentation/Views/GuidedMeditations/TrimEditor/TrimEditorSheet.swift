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
/// `onDone` receives the resolved trim points to persist (nil when the selection is
/// practically the whole file). `onCancel` discards the selection.
struct TrimEditorSheet: View {
    // MARK: Lifecycle

    init(
        meditation: GuidedMeditation,
        audioService: AudioServiceProtocol = AudioService(),
        waveformProvider: WaveformProviderProtocol = WaveformProvider(),
        onDone: @escaping (TimeInterval?, TimeInterval?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.fileDuration = meditation.duration
        self.title = meditation.name
        self.teacher = meditation.teacher
        self.onDone = onDone
        self.onCancel = onCancel
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
                if self.viewModel.isZoomed {
                    self.zoomOutChip
                        .transition(.opacity)
                }
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
    private let onDone: (TimeInterval?, TimeInterval?) -> Void
    private let onCancel: () -> Void

    private var state: TrimEditorState {
        self.viewModel.editorState
    }

    private var navRow: some View {
        ZStack {
            Text("trim_editor.title")
                .textStyle(.section, color: \.textPrimary)
            HStack {
                Button(action: self.onCancel) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(self.theme.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Text("trim_editor.a11y.back"))
                Spacer()
                Button {
                    self.onDone(self.state.resultTrimStart, self.state.resultTrimEnd)
                } label: {
                    Text("trim_editor.done")
                        .textStyle(.body, color: \.interactive)
                }
                .accessibilityIdentifier("trimEditor.done")
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

    /// Chip that zooms back to the overview — marks and playhead stay untouched
    /// (unlike the "Ganze Datei verwenden" link, which resets the marks).
    private var zoomOutChip: some View {
        Button {
            self.viewModel.zoomOut()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(self.theme.textSecondary)
                Text("trim_editor.zoomOut")
                    .textStyle(.caption, color: \.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(self.theme.cardBackground))
            .overlay(
                Capsule()
                    .strokeBorder(self.theme.cardBorder, lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("trim_editor.a11y.zoomOut"))
        .accessibilityIdentifier("trimEditor.zoomOut")
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
        waveformProvider: PreviewWaveformProvider(),
        onDone: { _, _ in },
        onCancel: {}
    )
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
        waveformProvider: PreviewWaveformProvider(),
        onDone: { _, _ in },
        onCancel: {}
    )
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
        waveformProvider: PreviewWaveformProvider(shouldFail: true),
        onDone: { _, _ in },
        onCancel: {}
    )
}
