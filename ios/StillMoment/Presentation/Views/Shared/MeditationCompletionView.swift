//
//  MeditationCompletionView.swift
//  Still Moment
//
//  Presentation Layer - Reusable completion screen for meditation sessions
//

import SwiftUI

/// Completion screen displayed after a meditation session ends naturally.
///
/// Shows a heart icon, thank-you message, and a back button.
/// Used by both the guided meditation player (shared-053) and timer (shared-052).
struct MeditationCompletionView: View {
    // MARK: Lifecycle

    init(onBack: @escaping () -> Void) {
        self.onBack = onBack
    }

    // MARK: Internal

    var body: some View {
        GeometryReader { geometry in
            let isCompactHeight = geometry.size.height < 700
            let iconContainerSize: CGFloat = isCompactHeight ? 72 : 80
            let iconSize: CGFloat = isCompactHeight ? 32 : 40

            VStack(spacing: 0) {
                Spacer()

                // Heart icon in circular container
                ZStack {
                    Circle()
                        .fill(self.theme.interactive.opacity(0.1))
                        .frame(width: iconContainerSize, height: iconContainerSize)

                    Image(systemName: "heart.fill")
                        .font(.system(size: iconSize))
                        .foregroundColor(self.theme.interactive.opacity(0.8))
                }
                .padding(.bottom, isCompactHeight ? 24 : 32)
                .accessibilityHidden(true)

                // Headline
                Text("guided_meditations.player.completion.headline", bundle: .main)
                    .themeFont(.screenTitle, size: isCompactHeight ? 32 : nil)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, isCompactHeight ? 12 : 16)
                    .accessibilityAddTraits(.isHeader)

                // Subtitle
                Text("guided_meditations.player.completion.subtitle", bundle: .main)
                    .themeFont(.bodySecondary, size: isCompactHeight ? 14 : nil)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, isCompactHeight ? 48 : 64)

                // Back button
                Button(action: self.onBack) {
                    Text("button.back", bundle: .main)
                }
                .warmPrimaryButton()
                .accessibilityIdentifier("completion.button.back")
                .accessibilityLabel(NSLocalizedString("accessibility.backToLibrary", comment: ""))

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }

    // MARK: Private

    private let onBack: () -> Void

    @Environment(\.themeColors)
    private var theme
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
