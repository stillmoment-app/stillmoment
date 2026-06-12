//
//  WaveformWindowView.swift
//  Still Moment
//
//  Presentation Layer — the scrolling "Tonkopf" window of the waveform player (shared-109).
//

import SwiftUI

/// The core of the waveform player: a ±30 s window of the meditation's waveform that scrolls
/// past a fixed, glowing "now"-line in the screen center. Past audio (left of center) is
/// drawn in copper (`interactive`), upcoming audio (right) is a pale `textPrimary`. Grabbing
/// the band scrubs — the gesture is handled here, the scrub state lives in the view model.
///
/// Scrolling is driven by a `TimelineView(.animation)` that interpolates between the audio
/// player's 0.5 s position ticks, so the band glides smoothly without a separate frame
/// counter — the real audio position stays the source of truth. The timeline pauses while
/// paused, dragging, backgrounded, or when Reduce Motion is on (then it steps per tick).
struct WaveformWindowView: View {
    // MARK: Internal

    @ObservedObject var viewModel: GuidedMeditationPlayerViewModel

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            TimelineView(.animation(paused: self.isAnimationPaused)) { context in
                let now = self.visualNow(at: context.date)
                ZStack {
                    self.waveCanvas(now: now, width: width)
                    self.nowLine
                    self.marker(width: width)
                }
            }
            .contentShape(Rectangle())
            .gesture(self.scrubGesture(width: width))
        }
        .frame(height: Self.windowHeight)
        .onChange(of: self.viewModel.displayTime) { newValue in
            // Re-anchor the interpolation on every real position tick so the smooth scroll
            // never drifts more than one tick away from the audio's true position.
            self.anchorTime = newValue
            self.anchorDate = Date()
        }
        .onChange(of: self.scenePhase) { _ in
            self.anchorTime = self.viewModel.displayTime
            self.anchorDate = Date()
        }
        .accessibilityHidden(true)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    /// Anchor for interpolating the smooth scroll between discrete position ticks.
    @State private var anchorTime: TimeInterval = 0
    @State private var anchorDate: Date = .init()
    @State private var pulsing = false

    // Window mechanics (handoff defaults).
    private static let windowSec: TimeInterval = 60 // ±30 s visible
    private static let windowHeight: CGFloat = 188
    private static let barStep: CGFloat = 3.2
    private static let barWidth: CGFloat = 2.0
    private static let maxHalfFactor: CGFloat = 0.40
    private static let minHalfHeight: CGFloat = 0.8
    private static let edgeFadeWidth: CGFloat = 56

    private var isAnimationPaused: Bool {
        !self.viewModel.isPlaying
            || self.viewModel.isDragging
            || self.reduceMotion
            || self.scenePhase != .active
    }

    /// The time the window is centered on. While playing we interpolate forward from the
    /// last real tick; otherwise the view model's `displayTime` (drag position or paused
    /// position) is the truth.
    private func visualNow(at date: Date) -> TimeInterval {
        guard self.viewModel.isPlaying, !self.viewModel.isDragging, !self.reduceMotion else {
            return self.viewModel.displayTime
        }
        let interpolated = self.anchorTime + date.timeIntervalSince(self.anchorDate)
        return min(interpolated, self.viewModel.scrubBounds.upperBound)
    }

    // MARK: Canvas

    @ViewBuilder
    private func waveCanvas(now: TimeInterval, width: CGFloat) -> some View {
        if self.viewModel.waveformLoadFailed || self.viewModel.waveform == nil {
            // Fallback: a plain baseline keeps the player usable when decoding failed (AK-8).
            self.fallbackBaseline
        } else {
            Canvas { context, size in
                self.drawBars(in: context, size: size, now: now)
            }
        }
    }

    private var fallbackBaseline: some View {
        Rectangle()
            .fill(self.theme.textPrimary.opacity(0.16))
            .frame(height: 2)
    }

    private func drawBars(in context: GraphicsContext, size: CGSize, now: TimeInterval) {
        guard let samples = viewModel.waveform?.samples, !samples.isEmpty else {
            return
        }
        let duration = self.viewModel.duration > 0 ? self.viewModel.duration : self.viewModel.meditation.duration
        guard duration > 0 else {
            return
        }
        let bounds = self.viewModel.scrubBounds
        let center = size.width / 2
        let density = PlayheadWindowGeometry.pxPerSec(windowSec: Self.windowSec, width: size.width)
        guard density > 0 else {
            return
        }
        let cy = size.height / 2
        let maxHalf = size.height * Self.maxHalfFactor
        let sampleCount = samples.count

        var positionX: CGFloat = 0
        while positionX <= size.width {
            let sec = now + TimeInterval((positionX - center) / density)
            // Outside the playable (trimmed) range → no bar.
            if sec >= bounds.lowerBound, sec <= bounds.upperBound {
                let index = min(max(Int(sec / duration * TimeInterval(sampleCount)), 0), sampleCount - 1)
                let amp = CGFloat(samples[index])
                let half = max(Self.minHalfHeight, amp * maxHalf)
                let isPast = sec <= now
                let baseAlpha: CGFloat = isPast ? (0.55 + 0.45 * amp) : 0.16
                let alpha = baseAlpha * self.edgeFade(at: positionX, width: size.width)
                let color = isPast ? self.theme.interactive : self.theme.textPrimary
                let rect = CGRect(
                    x: positionX - Self.barWidth / 2,
                    y: cy - half,
                    width: Self.barWidth,
                    height: half * 2
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: Self.barWidth / 2),
                    with: .color(color.opacity(alpha))
                )
            }
            positionX += Self.barStep
        }
    }

    /// Linear alpha ramp toward 0 within `edgeFadeWidth` of either edge — the wave dissolves
    /// instead of cutting off hard.
    private func edgeFade(at positionX: CGFloat, width: CGFloat) -> CGFloat {
        let leftFade = min(positionX / Self.edgeFadeWidth, 1)
        let rightFade = min((width - positionX) / Self.edgeFadeWidth, 1)
        return max(0, min(leftFade, rightFade))
    }

    // MARK: Now-line + marker (Sage, never copper — see plan decision 1)

    private var nowLine: some View {
        Rectangle()
            .fill(self.theme.playheadAccentHi)
            .frame(width: 2)
            .shadow(color: self.theme.playheadAccent.opacity(0.8), radius: 12)
    }

    private func marker(width: CGFloat) -> some View {
        ZStack {
            // Triangle at the top of the line.
            Triangle()
                .fill(self.theme.playheadAccentHi)
                .frame(width: 10, height: 6)
                .frame(maxHeight: .infinity, alignment: .top)
                .offset(y: -2)

            // Pulsing dot at the bottom — only while actively playing.
            Circle()
                .fill(self.theme.playheadAccentHi)
                .frame(width: 7, height: 7)
                .scaleEffect(self.pulsing ? 1.6 : 1.0)
                .opacity(self.pulsing ? 0.0 : 1.0)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .offset(y: 3)
                .onChange(of: self.shouldPulse) { _ in self.updatePulse() }
                .onAppear { self.updatePulse() }
        }
    }

    private var shouldPulse: Bool {
        self.viewModel.isPlaying && !self.viewModel.isDragging && !self.reduceMotion
    }

    private func updatePulse() {
        guard self.shouldPulse else {
            self.pulsing = false
            return
        }
        self.pulsing = false
        withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
            self.pulsing = true
        }
    }

    // MARK: Scrub gesture

    private func scrubGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !self.viewModel.isDragging {
                    self.viewModel.beginScrub()
                }
                let newNow = PlayheadWindowGeometry.draggedNow(
                    startNow: self.viewModel.dragStartTime,
                    translation: value.translation.width,
                    windowSec: Self.windowSec,
                    width: width,
                    bounds: self.viewModel.scrubBounds
                )
                self.viewModel.scrub(to: newNow)
            }
            .onEnded { _ in
                self.viewModel.endScrub()
            }
    }
}

// MARK: - Triangle

/// Small downward-pointing triangle marking the tip of the now-line.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
