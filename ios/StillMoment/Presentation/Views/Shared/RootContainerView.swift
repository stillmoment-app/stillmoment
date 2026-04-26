//
//  RootContainerView.swift
//  Still Moment
//
//  Presentation Layer - Top-level container with post-meditation completion overlay
//

import SwiftUI

/// Top-level wrapper that shows a completion overlay when the app is re-opened
/// after a guided meditation ended naturally and the OS terminated the app.
///
/// Reads `@SceneStorage` once on first `onAppear` (Snapshot-Pattern) and captures
/// the result in `@State`. Later writes to SceneStorage (from the active player)
/// never trigger the overlay, preventing double-display (shared-080, AK-6).
struct RootContainerView<Content: View>: View {
    // MARK: Lifecycle

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: Internal

    var body: some View {
        self.content
            .onAppear {
                guard self.markerPresence == nil else {
                    return
                }
                let hasValidMarker = self.completedAtRaw > 0
                    && !CompletionMarker.isExpired(completedAt: self.completedAtRaw, now: Date())
                if hasValidMarker {
                    self.markerPresence = .present
                } else {
                    self.completedAtRaw = 0
                    self.meditationIdRaw = ""
                    self.markerPresence = .absent
                }
            }
            .overlay {
                if self.markerPresence == .present {
                    ZStack {
                        self.theme.backgroundGradient
                            .ignoresSafeArea()
                        MeditationCompletionView {
                            self.completedAtRaw = 0
                            self.meditationIdRaw = ""
                            self.markerPresence = .absent
                        }
                    }
                }
            }
    }

    // MARK: Private

    private enum MarkerPresence { case present, absent }

    @SceneStorage("completion.completedAt")
    private var completedAtRaw: Double = 0
    @SceneStorage("completion.meditationId")
    private var meditationIdRaw: String = ""
    @State private var markerPresence: MarkerPresence?
    @Environment(\.themeColors)
    private var theme

    private let content: Content
}
