//
//  WaveformMiniOverview.swift
//  Still Moment
//
//  Presentation Layer — full-track mini overview of the waveform player (shared-109).
//

import SwiftUI

/// A compressed overview of the whole (trimmed) track below the scrolling window. Shows the
/// overall position the ±30 s window can't: the played portion in copper, the rest pale.
/// Tapping or dragging it is an absolute seek (position p → `effectiveStart + p · duration`).
struct WaveformMiniOverview: View {
    // MARK: Internal

    @ObservedObject var viewModel: GuidedMeditationPlayerViewModel

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                self.track
                self.marker(width: width)
            }
            .frame(height: Self.height)
            .contentShape(Rectangle())
            .gesture(self.seekGesture(width: width))
        }
        .frame(height: Self.height)
        .accessibilityHidden(true)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    private static let height: CGFloat = 30
    private static let displayBarCount = 160
    private static let barGap: CGFloat = 1
    private static let minBarHeight: CGFloat = 2

    /// Played fraction of the trimmed track (0…1) — also the marker position.
    private var progress: Double {
        let total = self.viewModel.meditation.effectiveDuration
        guard total > 0 else {
            return 0
        }
        let elapsed = self.viewModel.displayTime - self.viewModel.meditation.effectiveStart
        return min(max(elapsed / total, 0), 1)
    }

    @ViewBuilder private var track: some View {
        if self.viewModel.waveformLoadFailed || self.viewModel.waveform == nil {
            self.fallbackTrack
        } else {
            Canvas { context, size in
                self.drawBars(in: context, size: size)
            }
        }
    }

    /// Plain progress bar when no amplitudes are available (AK-8).
    private var fallbackTrack: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(self.theme.textPrimary.opacity(0.14))
                    .frame(height: 3)
                Capsule()
                    .fill(self.theme.interactive.opacity(0.85))
                    .frame(width: proxy.size.width * self.progress, height: 3)
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }

    private func drawBars(in context: GraphicsContext, size: CGSize) {
        let duration = self.viewModel.duration > 0 ? self.viewModel.duration : self.viewModel.meditation.duration
        guard duration > 0 else {
            return
        }
        // Slice the trimmed range out of the full-resolution waveform, then reduce to the
        // overview bar count. Reduce by AVERAGE, not peak: each overview bar spans ~10 s of
        // a long track, and a peak (max) would fill every bar — speech pauses would vanish.
        // Averaging keeps the energy envelope, so longer pauses show up as valleys, matching
        // the gaps the fine-grained window above shows.
        let trimmed = self.viewModel.waveform?
            .windowed(
                fromFraction: self.viewModel.meditation.effectiveStart / duration,
                toFraction: self.viewModel.meditation.effectiveEnd / duration
            )
            .samples ?? []
        let samples = self.averagedSamples(trimmed, to: Self.displayBarCount)
        guard !samples.isEmpty else {
            return
        }
        let count = samples.count
        let totalGap = Self.barGap * CGFloat(count - 1)
        let barWidth = max((size.width - totalGap) / CGFloat(count), 0.5)
        let playedX = size.width * CGFloat(self.progress)
        let played = self.theme.interactive.opacity(0.85)
        let remaining = self.theme.textPrimary.opacity(0.14)

        for (index, sample) in samples.enumerated() {
            let positionX = CGFloat(index) * (barWidth + Self.barGap)
            let barHeight = max(CGFloat(sample) * size.height, Self.minBarHeight)
            let positionY = (size.height - barHeight) / 2
            let rect = CGRect(x: positionX, y: positionY, width: barWidth, height: barHeight)
            let color = positionX <= playedX ? played : remaining
            context.fill(Path(rect), with: .color(color))
        }
    }

    /// Reduces samples to `count` bars by AVERAGE (energy envelope), preserving pauses.
    private func averagedSamples(_ samples: [Float], to count: Int) -> [Float] {
        guard count > 0, samples.count > count else {
            return samples
        }
        var result = [Float](repeating: 0, count: count)
        for bucket in 0..<count {
            let start = bucket * samples.count / count
            let end = max(start + 1, (bucket + 1) * samples.count / count)
            let slice = samples[start..<min(end, samples.count)]
            result[bucket] = slice.reduce(0, +) / Float(slice.count)
        }
        return result
    }

    private func marker(width: CGFloat) -> some View {
        Rectangle()
            .fill(self.theme.playGradientBot)
            .frame(width: 2)
            .shadow(color: self.theme.playGradientTop.opacity(0.8), radius: 4)
            .offset(x: width * CGFloat(self.progress) - 1)
    }

    private func seekGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard width > 0 else {
                    return
                }
                let fraction = Double(value.location.x / width)
                self.viewModel.seek(toFraction: fraction)
            }
    }
}
