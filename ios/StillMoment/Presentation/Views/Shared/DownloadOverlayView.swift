//
//  DownloadOverlayView.swift
//  Still Moment
//
//  Presentation Layer - Modal overlay shown while a URL share/import download
//  is in flight. Backdrop + card with constellation animation, title, body and
//  a ghost-style cancel pill.
//

import SwiftUI

struct DownloadOverlayView: View {
    let onCancel: () -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        ZStack {
            self.backdrop
            self.card
        }
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        Color.black.opacity(Self.backdropOpacity)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            // Swallow taps so they don't reach views behind the overlay;
            // tapping outside the card does not dismiss the modal.
            .onTapGesture {}
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 0) {
            ConstellationLoader(color: self.theme.interactive)
                .padding(.bottom, Self.animationBottomSpacing)

            Text(NSLocalizedString("share.download.loading", comment: ""))
                .themeFont(.dialogTitle)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, Self.titleBottomSpacing)

            Text(NSLocalizedString("share.download.body", comment: ""))
                .themeFont(.dialogBody)
                .multilineTextAlignment(.center)
                .lineSpacing(Self.bodyLineSpacing)
                .padding(.bottom, Self.bodyBottomSpacing)

            self.cancelPill
        }
        .padding(.horizontal, Self.cardHorizontalPadding)
        .padding(.top, Self.cardTopPadding)
        .padding(.bottom, Self.cardBottomPadding)
        .frame(maxWidth: Self.cardMaxWidth)
        .background(
            RoundedRectangle(cornerRadius: Self.cardRadius)
                .fill(self.theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Self.cardRadius)
                        .strokeBorder(self.theme.cardBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, Self.screenPadding)
        .contentShape(Rectangle())
        // Block taps from leaking through the card to the backdrop.
        .onTapGesture {}
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Cancel Pill

    private var cancelPill: some View {
        Button(action: self.onCancel) {
            Text(NSLocalizedString("share.download.cancel", comment: ""))
                .themeFont(.dialogBody, color: \.interactive)
                .padding(.horizontal, Self.pillHorizontalPadding)
                .padding(.vertical, Self.pillVerticalPadding)
                .background(
                    Capsule()
                        .fill(self.theme.textPrimary.opacity(Self.ghostFillAlpha))
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    self.theme.textPrimary.opacity(Self.ghostBorderAlpha),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .accessibilityLabel(
            NSLocalizedString("share.download.cancel.accessibility", comment: "")
        )
    }

    // MARK: - Layout Constants

    private static let backdropOpacity: Double = 0.55
    private static let cardMaxWidth: CGFloat = 320
    private static let screenPadding: CGFloat = 36
    private static let cardRadius: CGFloat = 28
    private static let cardHorizontalPadding: CGFloat = 28
    private static let cardTopPadding: CGFloat = 32
    private static let cardBottomPadding: CGFloat = 24
    private static let animationBottomSpacing: CGFloat = 22
    private static let titleBottomSpacing: CGFloat = 6
    private static let bodyBottomSpacing: CGFloat = 22
    private static let bodyLineSpacing: CGFloat = 3.6
    private static let pillHorizontalPadding: CGFloat = 22
    private static let pillVerticalPadding: CGFloat = 10
    private static let ghostFillAlpha: Double = 0.04
    private static let ghostBorderAlpha: Double = 0.08
}

#if DEBUG
#Preview("Download Overlay (Light)") {
    ZStack {
        Color.gray
        DownloadOverlayView {}
    }
    .environment(\.themeColors, .candlelightLight)
    .preferredColorScheme(.light)
}

#Preview("Download Overlay (Dark)") {
    ZStack {
        Color.gray
        DownloadOverlayView {}
    }
    .environment(\.themeColors, .candlelightDark)
    .preferredColorScheme(.dark)
}
#endif
