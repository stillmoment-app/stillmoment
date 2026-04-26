//
//  RootContainerView.swift
//  Still Moment
//
//  Presentation Layer - Top-level container with post-meditation completion overlay
//

import SwiftUI

/// Snapshot of the completion overlay state, evaluated once per Scene lifecycle.
///
/// Encapsulates the guard-pattern from `RootContainerView.onAppear`:
/// once evaluated, later `@SceneStorage` changes (e.g. from an active player)
/// don't change the result — preventing double-display (shared-080, AK-6).
struct CompletionOverlaySnapshot: Equatable {
    private(set) var isPresent: Bool?

    mutating func evaluate(completedAtRaw: Double) {
        guard self.isPresent == nil else {
            return
        }
        self.isPresent = completedAtRaw > 0
    }

    mutating func dismiss() {
        self.isPresent = false
    }
}

/// Top-level wrapper that shows a completion overlay when the app is re-opened
/// after a guided meditation ended naturally and the OS terminated the app.
///
/// Reads `@SceneStorage` once on first `onAppear` via `CompletionOverlaySnapshot`.
/// Later writes to SceneStorage (from the active player) never trigger the overlay.
struct RootContainerView<Content: View>: View {
    // MARK: Lifecycle

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: Internal

    var body: some View {
        self.content
            .onAppear {
                self.snapshot.evaluate(completedAtRaw: self.completedAtRaw)
            }
            .overlay {
                if self.snapshot.isPresent == true {
                    ZStack {
                        self.theme.backgroundGradient
                            .ignoresSafeArea()
                        MeditationCompletionView {
                            self.completedAtRaw = 0
                            self.meditationIdRaw = ""
                            self.snapshot.dismiss()
                        }
                    }
                }
            }
    }

    // MARK: Private

    @SceneStorage("completion.completedAt")
    private var completedAtRaw: Double = 0
    @SceneStorage("completion.meditationId")
    private var meditationIdRaw: String = ""
    @State private var snapshot = CompletionOverlaySnapshot()
    @Environment(\.themeColors)
    private var theme

    private let content: Content
}
