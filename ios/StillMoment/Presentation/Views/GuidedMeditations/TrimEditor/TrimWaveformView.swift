//
//  TrimWaveformView.swift
//  Still Moment
//
//  Presentation Layer — Canvas renderer for the trim editor waveform (shared-107).
//

import SwiftUI

/// Draws the waveform of the trim editor, downsampled to 220 display bars.
///
/// The cached waveform carries `MeditationWaveform.sampleCount` peaks (high resolution
/// for the zoom, shared-108); this overview reduces them peak-preservingly to
/// `displayBarCount` bars. Bars inside `[start, end]` use the accent (`interactive`)
/// colour, bars outside are dimmed. A range-highlight box marks the selection and a playhead line is drawn while
/// audio plays/previews. When the waveform failed to decode, a single flat baseline is
/// drawn instead (slider look) — the editor stays fully functional (handoff "Fallback").
struct TrimWaveformView: View {
    // MARK: Internal

    let waveform: MeditationWaveform?
    let isLoading: Bool
    let loadFailed: Bool
    let duration: TimeInterval
    let start: TimeInterval
    let end: TimeInterval
    let playheadTime: TimeInterval?
    /// Rendered height; the editor uses the default, the mini card variant passes 44.
    var height: CGFloat = TrimWaveformView.height

    static let height: CGFloat = 108

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                self.rangeHighlight(width: proxy.size.width)
                self.canvas
                self.playhead(width: proxy.size.width)
            }
        }
        .frame(height: self.height)
        .accessibilityHidden(true)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private static let displayBarCount = 220
    private static let barCornerRadius: CGFloat = 2
    private static let barGap: CGFloat = 1
    private static let minBarHeight: CGFloat = 2

    @ViewBuilder private var canvas: some View {
        if self.loadFailed {
            self.fallbackLine
        } else {
            Canvas { context, size in
                self.drawBars(in: context, size: size)
            }
            .opacity(self.isLoading ? 0.35 : 1)
            .overlay(alignment: .center) {
                if self.isLoading {
                    ProgressView()
                        .tint(self.theme.interactive)
                }
            }
        }
    }

    /// Flat baseline shown when decoding failed.
    private var fallbackLine: some View {
        Rectangle()
            .fill(self.theme.controlTrack)
            .frame(height: 2)
    }

    private func drawBars(in context: GraphicsContext, size: CGSize) {
        let samples = self.waveform?.downsampled(to: Self.displayBarCount).samples ?? []
        guard !samples.isEmpty else {
            return
        }
        let count = samples.count
        let totalGap = Self.barGap * CGFloat(count - 1)
        let barWidth = max((size.width - totalGap) / CGFloat(count), 0.5)
        let inAccent = self.theme.interactive
        let dimmed = self.theme.textSecondary.opacity(0.30)

        for (index, sample) in samples.enumerated() {
            let positionX = CGFloat(index) * (barWidth + Self.barGap)
            let barHeight = max(CGFloat(sample) * size.height, Self.minBarHeight)
            let positionY = (size.height - barHeight) / 2
            let rect = CGRect(x: positionX, y: positionY, width: barWidth, height: barHeight)
            let path = Path(roundedRect: rect, cornerRadius: Self.barCornerRadius)
            let barTime = self.duration * (Double(index) / Double(count))
            let isInRange = barTime >= self.start && barTime <= self.end
            context.fill(path, with: .color(isInRange ? inAccent : dimmed))
        }
    }

    @ViewBuilder
    private func rangeHighlight(width: CGFloat) -> some View {
        if self.duration > 0 {
            let startX = TrimGeometry.x(for: self.start, duration: self.duration, width: width)
            let endX = TrimGeometry.x(for: self.end, duration: self.duration, width: width)
            RoundedRectangle(cornerRadius: 4)
                .fill(self.theme.interactive.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(self.theme.interactive.opacity(0.35), lineWidth: 1)
                )
                .frame(width: max(endX - startX, 0))
                .offset(x: startX)
                .padding(.vertical, -4)
        }
    }

    @ViewBuilder
    private func playhead(width: CGFloat) -> some View {
        if let playheadTime, self.duration > 0 {
            let positionX = TrimGeometry.x(for: playheadTime, duration: self.duration, width: width)
            // Sage, not copper — the playhead must never be confusable with the marks.
            Rectangle()
                .fill(self.theme.playheadAccentHi)
                .frame(width: 2)
                .shadow(color: self.theme.playheadAccent.opacity(0.7), radius: 4)
                .offset(x: positionX - 1)
        }
    }
}
