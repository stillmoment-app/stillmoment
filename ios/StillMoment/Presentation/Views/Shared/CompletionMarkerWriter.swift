//
//  CompletionMarkerWriter.swift
//  Still Moment
//
//  Presentation Layer - Owns the persisted completion marker (shared-080)
//

import SwiftUI

/// Writes the persisted "a guided meditation ended naturally" marker and owns
/// its transitions (shared-080).
///
/// The marker lives in `@SceneStorage`, so it survives an OS-initiated
/// termination while the phone was locked. Both views that show a completion
/// screen — in-place in the player and as the top-level overlay — go through
/// this type, so no exit path can forget to clear it. A marker left behind
/// makes the completion screen reappear on the next launch (AK-2).
struct CompletionMarkerWriter {
    @Binding var completedAt: Double
    @Binding var meditationId: String

    /// Whether a natural end is currently remembered and unacknowledged.
    var isSet: Bool {
        self.completedAt > 0
    }

    /// A guided meditation ended naturally — remember it across termination.
    func record(_ event: CompletionEvent) {
        self.completedAt = event.completedAt.timeIntervalSince1970
        self.meditationId = event.meditationId.uuidString
    }

    /// Forget the marker — a new session starts, or the user acknowledged it.
    func clear() {
        self.completedAt = 0
        self.meditationId = ""
    }

    /// The user leaves a completion screen: forget the marker, then navigate.
    func dismissCompletionScreen(_ leave: () -> Void) {
        self.clear()
        leave()
    }
}
