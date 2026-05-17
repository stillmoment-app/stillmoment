//
//  MeditationCompletionView.swift
//  Still Moment
//
//  Presentation Layer - Reusable completion screen for meditation sessions
//

import SwiftUI

/// Completion screen displayed after a meditation session ends naturally.
///
/// Shows a static glow, a single warm message, and a "Done" button.
/// Used by both the guided meditation player (shared-053) and the timer (shared-052),
/// as well as the pending-termination recovery overlay (shared-080).
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
        GeometryReader { geometry in
            let isCompactHeight = geometry.size.height < 700
            let glowSize: CGFloat = isCompactHeight ? 144 : 180
            let glowToHeadline: CGFloat = isCompactHeight ? 32 : 44
            let headlineToButton: CGFloat = isCompactHeight ? 56 : 92

            VStack(spacing: 0) {
                Spacer()

                CompletionGlow(size: glowSize)
                    .padding(.bottom, glowToHeadline)

                Text("guided_meditations.player.completion.headline", bundle: .main)
                    .textStyle(.screenTitle, color: \.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, headlineToButton)
                    .accessibilityAddTraits(.isHeader)

                Button(action: self.onBack) {
                    Text("completion.button.done", bundle: .main)
                }
                .warmPrimaryButton()
                .accessibilityIdentifier("completion.button.done")
                .accessibilityLabel(self.backAccessibilityLabel)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.15)
                .ignoresSafeArea()
            MeditationCompletionView {}
        }
    }
}
