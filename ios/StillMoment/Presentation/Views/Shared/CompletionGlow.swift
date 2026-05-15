//
//  CompletionGlow.swift
//  Still Moment
//
//  Presentation Layer - Static glow visualization for the completion screen.
//
//  Two concentric circles with radial gradients, no animation.
//  Used by MeditationCompletionView as a quiet visual closer for a finished session.
//

import SwiftUI

/// Static, theme-driven glow used on the meditation completion screen.
///
/// Two concentric `Circle`s with `RadialGradient`s: an outer halo and an inner core.
/// No animation, no lifecycle, no state — the session is over, so the visual must not suggest activity.
/// Accent colour comes from `theme.interactive`; works across all themes (Candlelight, Forest, Moon).
struct CompletionGlow: View {
    // MARK: Lifecycle

    init(size: CGFloat = 180) {
        self.size = size
    }

    // MARK: Internal

    var body: some View {
        let coreSize = self.size * (96.0 / 180.0)

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: self.theme.interactive.opacity(0.22), location: 0.0),
                            .init(color: self.theme.interactive.opacity(0.05), location: 0.55),
                            .init(color: Color.clear, location: 0.78)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: self.size / 2
                    )
                )
                .frame(width: self.size, height: self.size)

            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: self.theme.interactive.opacity(0.90), location: 0.0),
                            .init(color: self.theme.interactive.opacity(0.55), location: 0.38),
                            .init(color: self.theme.interactive.opacity(0.18), location: 0.68),
                            .init(color: Color.clear, location: 0.88)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: coreSize / 2
                    )
                )
                .frame(width: coreSize, height: coreSize)
        }
        .accessibilityHidden(true)
    }

    // MARK: Private

    private let size: CGFloat

    @Environment(\.themeColors)
    private var theme
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Standard (180pt)") {
    ZStack {
        Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()
        CompletionGlow()
    }
}

@available(iOS 17.0, *)
#Preview("Compact (144pt)") {
    ZStack {
        Color(red: 0.12, green: 0.10, blue: 0.10).ignoresSafeArea()
        CompletionGlow(size: 144)
    }
}
