//
//  MeditationCompletionViewTests.swift
//  Still Moment
//
//  Structural tests for the meditation completion view: verifies that the
//  back closure is invoked and the accessibility label resolves correctly.
//

import XCTest
@testable import StillMoment

final class MeditationCompletionViewTests: XCTestCase {
    func testOnBackClosureIsExposedAndCallable() {
        // Given
        var didInvoke = false
        let view = MeditationCompletionView { didInvoke = true }

        // When
        view.onBack()

        // Then
        XCTAssertTrue(didInvoke, "The onBack closure should be exposed on the view and invoke the caller's handler")
    }

    func testDefaultAccessibilityLabelResolvesFromLocalization() {
        // Given
        let expected = NSLocalizedString("accessibility.backToLibrary", comment: "")

        // When
        let view = MeditationCompletionView {}

        // Then
        XCTAssertEqual(view.backAccessibilityLabel, expected)
    }

    func testCustomAccessibilityLabelIsForwarded() {
        // Given / When
        let view = MeditationCompletionView(
            onBack: {},
            backAccessibilityLabel: "Custom Label"
        )

        // Then
        XCTAssertEqual(view.backAccessibilityLabel, "Custom Label")
    }
}
