//
//  ShareConfirmationView.swift
//  Still Moment
//
//  Share Extension - Calm confirmation (or message) after sharing, in the app's
//  dark palette and typography (ios-059). Fills the system share sheet.
//

import SwiftUI

/// Fills the share sheet with the dark app background and, once the outcome is known,
/// shows the sender line, title, message and a single "Done" button.
///
/// Always dark, independent of system and app setting (ios-059): the appearance setting
/// is not readable from the extension.
struct ShareConfirmationView: View {
    /// `nil` while the shared content is still being processed — only the background shows.
    let outcome: ShareOutcome?
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Self.theme.backgroundPrimary
                .ignoresSafeArea()

            if let outcome {
                ShareMessageView(outcome: outcome, onDone: self.onDone)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: Self.fadeInDuration), value: self.outcome)
        .environment(\.themeColors, Self.theme)
        .preferredColorScheme(.dark)
    }

    // MARK: - Constants

    private static let theme: ThemeColors = .dark
    private static let fadeInDuration: Double = 0.35
}

// MARK: - Message

/// Sender line, divider, title, message and "Done" — centered; scrolls when the text is
/// too large for the sheet (Dynamic Type), so "Done" stays reachable.
private struct ShareMessageView: View {
    let outcome: ShareOutcome
    let onDone: () -> Void

    @Environment(\.themeColors)
    private var theme

    var body: some View {
        ViewThatFits(in: .vertical) {
            self.content

            ScrollView {
                self.content
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            self.senderLine
                .padding(.bottom, Self.senderLineBottomSpacing)

            Rectangle()
                .fill(self.theme.divider)
                .frame(height: Self.dividerHeight)
                .padding(.bottom, Self.dividerBottomSpacing)
                .accessibilityHidden(true)

            Text(NSLocalizedString(self.titleKey, comment: ""))
                .textStyle(.section, color: \.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, Self.titleBottomSpacing)

            Text(NSLocalizedString(self.messageKey, comment: ""))
                .textStyle(.body, color: \.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(Self.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, Self.bodyBottomSpacing)

            self.doneButton
        }
        .frame(maxWidth: Self.contentMaxWidth)
        .padding(.horizontal, Self.screenPadding)
        .padding(.vertical, Self.verticalPadding)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Sender Line

    private var senderLine: some View {
        HStack(spacing: Self.senderIconSpacing) {
            Image("SenderIcon")
                .resizable()
                .frame(width: Self.senderIconSize, height: Self.senderIconSize)
                .clipShape(RoundedRectangle(cornerRadius: Self.senderIconRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Self.senderIconRadius, style: .continuous)
                        .strokeBorder(self.theme.divider, lineWidth: Self.senderIconHairline)
                )
                .accessibilityHidden(true)

            Text(NSLocalizedString("share.sender", comment: ""))
                .textStyle(.eyebrow, color: \.textSecondary)
        }
    }

    // MARK: - Done Button (ghost pill, same look as DownloadOverlayView)

    private var doneButton: some View {
        Button(action: self.onDone) {
            Text(NSLocalizedString("share.button.done", comment: ""))
                .textStyle(.body, color: \.interactive)
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
        .accessibilityLabel(NSLocalizedString("share.button.done", comment: ""))
    }

    // MARK: - Texts

    private var titleKey: String {
        switch self.outcome {
        case .confirmation: "share.confirmation.title"
        case .unsupportedFormat: "share.unsupportedFormat.title"
        case .noLink: "share.noLink.title"
        case .unreadable: "share.error.title"
        }
    }

    private var messageKey: String {
        switch self.outcome {
        case .confirmation: "share.confirmation.message"
        case .unsupportedFormat: "share.unsupportedFormat.message"
        case .noLink: "share.noLink.message"
        case .unreadable: "share.error.message"
        }
    }

    // MARK: - Layout Constants

    private static let contentMaxWidth: CGFloat = 320
    private static let screenPadding: CGFloat = 36
    private static let verticalPadding: CGFloat = 24
    private static let senderIconSize: CGFloat = 28
    private static let senderIconRadius: CGFloat = 6.3
    private static let senderIconHairline: CGFloat = 0.5
    private static let senderIconSpacing: CGFloat = 10
    private static let senderLineBottomSpacing: CGFloat = 18
    private static let dividerHeight: CGFloat = 1
    private static let dividerBottomSpacing: CGFloat = 22
    private static let titleBottomSpacing: CGFloat = 6
    private static let bodyBottomSpacing: CGFloat = 22
    private static let bodyLineSpacing: CGFloat = 3.6
    private static let pillHorizontalPadding: CGFloat = 22
    private static let pillVerticalPadding: CGFloat = 10
    private static let ghostFillAlpha: Double = 0.04
    private static let ghostBorderAlpha: Double = 0.08
}

#if DEBUG
#Preview("Bestaetigung") {
    ShareConfirmationView(outcome: .confirmation) {}
}

#Preview("Format nicht unterstuetzt (AX3)") {
    ShareConfirmationView(outcome: .unsupportedFormat) {}
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Kein Link") {
    ShareConfirmationView(outcome: .noLink) {}
}

#Preview("Noch kein Ergebnis") {
    ShareConfirmationView(outcome: nil) {}
}
#endif
