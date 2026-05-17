//
//  MeditationCompletionView.swift
//  Still Moment
//
//  Presentation Layer - Reusable completion screen for meditation sessions
//

import SwiftUI

/// Completion screen displayed after a meditation session ends naturally.
///
/// Doppel-Lotus-Mandala, ruhiger Dank-Satz, Glas-Pille als Abschluss (shared-097).
/// Used by both the guided meditation player (shared-053) and the timer
/// (shared-052), sowie das Pending-Termination-Recovery-Overlay (shared-080).
/// Hintergrund-Gradient wird vom Aufrufer bereitgestellt — die View selbst
/// ist transparent.
struct MeditationCompletionView: View {
    // MARK: Lifecycle

    init(onBack: @escaping () -> Void, backAccessibilityLabel: String? = nil) {
        self.onBack = onBack
        self.backAccessibilityLabel = backAccessibilityLabel ?? NSLocalizedString(
            "accessibility.backToLibrary",
            comment: ""
        )
    }

    // MARK: Internal

    let onBack: () -> Void
    let backAccessibilityLabel: String

    var body: some View {
        ZStack {
            VStack(spacing: 48) {
                DankeLotusMandala()
                    .frame(width: 160, height: 160)

                Text("guided_meditations.player.completion.headline", bundle: .main)
                    .textStyle(.screenTitle, color: \.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 240)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                Spacer()

                Button(action: self.onBack) {
                    Text("completion.button.done", bundle: .main)
                }
                .warmGlassButton()
                .accessibilityIdentifier("completion.button.done")
                .accessibilityLabel(self.backAccessibilityLabel)
                .padding(.bottom, 56)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Dark") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.06, blue: 0.05),
                Color(red: 0.20, green: 0.12, blue: 0.10),
                Color(red: 0.36, green: 0.23, blue: 0.18)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        MeditationCompletionView {}
    }
}

@available(iOS 17.0, *)
#Preview("Light") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.93, blue: 0.85),
                Color(red: 0.96, green: 0.80, blue: 0.66),
                Color(red: 0.91, green: 0.63, blue: 0.45)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        MeditationCompletionView {}
            .environment(\.themeColors, .light)
    }
}
