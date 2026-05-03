//
//  ConstellationLoader.swift
//  Still Moment
//
//  Presentation Layer - Animated loader used by the download progress modal.
//
//  A pulsing core orbited by 5 dots on two orbital paths. The animation pauses
//  when the app is not active (scenePhase != .active) and resumes from the
//  exact same position via an elapsed-time accumulator — no visible jump.
//

import SwiftUI

struct ConstellationLoader: View {
    let color: Color

    @Environment(\.scenePhase)
    private var scenePhase

    @State private var startDate: Date = .init()
    @State private var pausedElapsed: TimeInterval = 0

    var body: some View {
        TimelineView(.animation(paused: self.scenePhase != .active)) { context in
            let elapsed = self.elapsed(at: context.date)
            ZStack {
                BreathingCore(elapsed: elapsed, color: self.color)
                ForEach(Self.orbits.indices, id: \.self) { index in
                    OrbitalDot(
                        orbit: Self.orbits[index],
                        elapsed: elapsed,
                        color: self.color
                    )
                }
            }
            .frame(width: Self.containerSize, height: Self.containerSize)
        }
        .onChange(of: self.scenePhase) { newPhase in
            if newPhase == .active {
                self.startDate = Date()
            } else {
                self.pausedElapsed += Date().timeIntervalSince(self.startDate)
            }
        }
        .accessibilityHidden(true)
    }

    private func elapsed(at date: Date) -> TimeInterval {
        guard self.scenePhase == .active else {
            return self.pausedElapsed
        }
        return self.pausedElapsed + date.timeIntervalSince(self.startDate)
    }

    private static let containerSize: CGFloat = 110
    private static let orbits: [Orbit] = [
        Orbit(radius: 30, duration: 6.5, phase: 0.0, size: 5.0),
        Orbit(radius: 30, duration: 6.5, phase: 1.3, size: 4.0),
        Orbit(radius: 42, duration: 9.0, phase: 0.4, size: 3.5),
        Orbit(radius: 42, duration: 9.0, phase: 3.0, size: 3.0),
        Orbit(radius: 42, duration: 9.0, phase: 5.6, size: 3.5)
    ]
}

private struct Orbit {
    let radius: CGFloat
    let duration: TimeInterval
    let phase: TimeInterval
    let size: CGFloat
}

private struct BreathingCore: View {
    let elapsed: TimeInterval
    let color: Color

    var body: some View {
        let raw = (sin(2 * .pi * self.elapsed / Self.cycleSeconds - .pi / 2) + 1) / 2
        let scale = Self.scaleMin + (Self.scaleMax - Self.scaleMin) * raw
        let alpha = Self.alphaMin + (Self.alphaMax - Self.alphaMin) * raw

        Circle()
            .fill(self.color.opacity(alpha))
            .frame(width: Self.diameter, height: Self.diameter)
            .scaleEffect(scale)
            .shadow(
                color: self.color.opacity(alpha * Self.glowAlphaFactor),
                radius: Self.glowRadius
            )
    }

    private static let diameter: CGFloat = 8
    private static let cycleSeconds: TimeInterval = 4.2
    private static let scaleMin: Double = 0.9
    private static let scaleMax: Double = 1.15
    private static let alphaMin: Double = 0.7
    private static let alphaMax: Double = 1.0
    private static let glowAlphaFactor: Double = 0.6
    private static let glowRadius: CGFloat = 9
}

private struct OrbitalDot: View {
    let orbit: Orbit
    let elapsed: TimeInterval
    let color: Color

    var body: some View {
        let angle = 2 * .pi * (self.elapsed + self.orbit.phase) / self.orbit.duration
        let dx = cos(angle) * self.orbit.radius
        let dy = sin(angle) * self.orbit.radius

        Circle()
            .fill(self.color.opacity(Self.dotAlpha))
            .frame(width: self.orbit.size, height: self.orbit.size)
            .shadow(
                color: self.color.opacity(Self.dotGlowAlpha),
                radius: Self.dotGlowRadius
            )
            .offset(x: dx, y: dy)
    }

    private static let dotAlpha: Double = 0.7
    private static let dotGlowAlpha: Double = 0.42
    private static let dotGlowRadius: CGFloat = 3
}

#if DEBUG
#Preview("Constellation Loader (Copper)") {
    ConstellationLoader(color: Color(red: 0.85, green: 0.55, blue: 0.35))
        .frame(width: 110, height: 110)
        .padding(40)
        .background(Color.black)
}
#endif
