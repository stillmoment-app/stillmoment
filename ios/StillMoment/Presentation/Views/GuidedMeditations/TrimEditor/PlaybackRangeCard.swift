//
//  PlaybackRangeCard.swift
//  Still Moment
//
//  Presentation Layer — "Wiedergabe-Bereich" form card in the edit sheet (shared-107).
//

import SwiftUI

/// Tappable card in the meditation edit sheet that summarizes the current playback range
/// and opens the full-screen waveform trim editor.
///
/// Two states follow the design handoff "View 1":
/// - **Untrimmed:** "Ganze Datei · {fileDuration}" + a "Bereich wählen" affordance.
/// - **Trimmed:** a static mini waveform with the selected range highlighted, the time
///   range, the audible duration, and a separate "Zuschnitt entfernen" text link.
///
/// The whole card opens the editor (`onOpenEditor`); the remove link is its own tap target
/// and resets the trim without opening the editor (`onRemoveTrim`).
struct PlaybackRangeCard: View {
    // MARK: Internal

    let fileDuration: TimeInterval
    /// Pending start offset in seconds (nil = no trim); reflects the edit sheet's uncommitted state.
    let trimStart: TimeInterval?
    /// Pending end offset in seconds (nil = no trim).
    let trimEnd: TimeInterval?
    /// Optional precomputed waveform for the mini display; nil renders the trimmed row without bars.
    let waveform: MeditationWaveform?
    let onOpenEditor: () -> Void
    let onRemoveTrim: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.card
            if self.isTrimmed {
                self.removeLink
            }
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    /// A range is "trimmed" once at least one explicit point is set.
    private var isTrimmed: Bool {
        self.trimStart != nil || self.trimEnd != nil
    }

    private var effectiveStart: TimeInterval {
        self.trimStart ?? 0
    }

    private var effectiveEnd: TimeInterval {
        self.trimEnd ?? self.fileDuration
    }

    private var audibleDuration: TimeInterval {
        max(self.effectiveEnd - self.effectiveStart, 0)
    }

    private var card: some View {
        Button(action: self.onOpenEditor) {
            VStack(alignment: .leading, spacing: 12) {
                self.header
                if self.isTrimmed {
                    self.trimmedContent
                } else {
                    self.untrimmedContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(self.theme.cardBackground.opacity(.opacitySecondary))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(self.theme.cardBorder, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("playback_range.label"))
        .accessibilityValue(Text(self.accessibilityValue))
        .accessibilityHint(Text("playback_range.a11y.openHint"))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("editSheet.card.playbackRange")
    }

    private var header: some View {
        HStack {
            Text("playback_range.label")
                .textStyle(.eyebrow, color: \.textSecondary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(self.theme.textSecondary)
                .opacity(.opacitySecondary)
        }
    }

    private var untrimmedContent: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(
                String(
                    format: NSLocalizedString("playback_range.wholeFile", comment: ""),
                    EditSheetState.formatTime(self.fileDuration)
                )
            )
            .textStyle(.body, monospacedDigits: true, color: \.textPrimary)
            Spacer(minLength: 12)
            HStack(spacing: 6) {
                Text("playback_range.choose")
                    .textStyle(.caption, color: \.interactive)
                Image(systemName: "scissors")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(self.theme.interactive)
            }
        }
    }

    private var trimmedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            TrimWaveformView(
                waveform: self.waveform,
                isLoading: false,
                loadFailed: self.waveform == nil,
                duration: self.fileDuration,
                start: self.effectiveStart,
                end: self.effectiveEnd,
                playheadTime: nil,
                height: Self.miniWaveformHeight
            )

            HStack(alignment: .firstTextBaseline) {
                Text(
                    String(
                        format: NSLocalizedString("playback_range.range", comment: ""),
                        EditSheetState.formatTime(self.effectiveStart),
                        EditSheetState.formatTime(self.effectiveEnd)
                    )
                )
                .textStyle(.title, monospacedDigits: true, color: \.interactive)
                Spacer(minLength: 12)
                Text(
                    String(
                        format: NSLocalizedString("playback_range.audible", comment: ""),
                        EditSheetState.formatTime(self.audibleDuration)
                    )
                )
                .textStyle(.caption, monospacedDigits: true, color: \.textSecondary)
            }
        }
    }

    private var removeLink: some View {
        Button(action: self.onRemoveTrim) {
            Text("playback_range.remove")
                .textStyle(.caption, color: \.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("playback_range.remove"))
        .accessibilityHint(Text("playback_range.a11y.removeHint"))
        .accessibilityIdentifier("editSheet.button.removeTrim")
    }

    private var accessibilityValue: String {
        guard self.isTrimmed else {
            return String(
                format: NSLocalizedString("playback_range.wholeFile", comment: ""),
                EditSheetState.formatTime(self.fileDuration)
            )
        }
        return String(
            format: NSLocalizedString("playback_range.range", comment: ""),
            EditSheetState.formatTime(self.effectiveStart),
            EditSheetState.formatTime(self.effectiveEnd)
        )
    }

    private static let miniWaveformHeight: CGFloat = 44
}

// MARK: - Previews

#if DEBUG
private let cardPreviewWaveform = MeditationWaveform(
    samples: (0..<MeditationWaveform.sampleCount).map { index in
        let fraction = Double(index) / Double(MeditationWaveform.sampleCount)
        let speech = abs(sin(fraction * 40)) * 0.8 + 0.15
        let isSilence = fraction > 0.18 && fraction < 0.82
        return Float(isSilence ? 0.06 : speech)
    }
)

#Preview("Untrimmed") {
    ThemeRootView {
        Form {
            Section {
                PlaybackRangeCard(
                    fileDuration: 1145,
                    trimStart: nil,
                    trimEnd: nil,
                    waveform: cardPreviewWaveform,
                    onOpenEditor: {},
                    onRemoveTrim: {}
                )
            } footer: {
                Text("playback_range.help")
            }
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview("Trimmed") {
    ThemeRootView {
        Form {
            Section {
                PlaybackRangeCard(
                    fileDuration: 1145,
                    trimStart: 84,
                    trimEnd: 1110,
                    waveform: cardPreviewWaveform,
                    onOpenEditor: {},
                    onRemoveTrim: {}
                )
            } footer: {
                Text("playback_range.help")
            }
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview("Trimmed — No Waveform") {
    ThemeRootView {
        Form {
            Section {
                PlaybackRangeCard(
                    fileDuration: 1145,
                    trimStart: 84,
                    trimEnd: 1110,
                    waveform: nil,
                    onOpenEditor: {},
                    onRemoveTrim: {}
                )
            } footer: {
                Text("playback_range.help")
            }
        }
        .scrollContentBackground(.hidden)
    }
}
#endif
