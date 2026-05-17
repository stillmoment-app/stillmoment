//
//  TextStyleTests.swift
//  Still Moment
//
//  Unit tests fuer Typografie 2.1 (TextStyle.swift).
//
//  Acceptance-Quelle: handoffs/Typografie 2.1 - Plan.html (Sektion "Die zehn Tokens").
//

import SwiftUI
import XCTest
@testable import StillMoment

final class TextStyleTests: XCTestCase {
    // MARK: - System Shape

    func testHasExactlyTenTokens() {
        // Plan-Regel: zehn Tokens, niemals mehr. Ein elftes hiesse, ein Screen ist
        // falsch entworfen — nicht das System.
        XCTAssertEqual(TextStyle.allCases.count, 10)
    }

    // MARK: - Dynamic-Type-Basis pro Token

    func testTextStyleMapping() {
        XCTAssertEqual(TextStyle.display.textStyle, .largeTitle)
        XCTAssertEqual(TextStyle.title.textStyle, .largeTitle)
        XCTAssertEqual(TextStyle.screenTitle.textStyle, .title)
        XCTAssertEqual(TextStyle.section.textStyle, .title3)
        XCTAssertEqual(TextStyle.body.textStyle, .body)
        XCTAssertEqual(TextStyle.bodyEmphasis.textStyle, .body)
        XCTAssertEqual(TextStyle.bodyItalic.textStyle, .body)
        XCTAssertEqual(TextStyle.caption.textStyle, .subheadline)
        XCTAssertEqual(TextStyle.micro.textStyle, .caption2)
        XCTAssertEqual(TextStyle.eyebrow.textStyle, .caption2)
    }

    // MARK: - Base-Size pro Token (bei Dynamic-Type "Large")

    func testBaseSizesFollowPlan() {
        XCTAssertEqual(TextStyle.title.baseSize, 30)
        XCTAssertEqual(TextStyle.screenTitle.baseSize, 26)
        XCTAssertEqual(TextStyle.section.baseSize, 20)
        XCTAssertEqual(TextStyle.body.baseSize, 17)
        XCTAssertEqual(TextStyle.bodyEmphasis.baseSize, 17)
        XCTAssertEqual(TextStyle.bodyItalic.baseSize, 17)
        XCTAssertEqual(TextStyle.caption.baseSize, 14)
        XCTAssertEqual(TextStyle.micro.baseSize, 11)
        XCTAssertEqual(TextStyle.eyebrow.baseSize, 11)
    }

    // MARK: - Font-Familie (Newsreader = Serif "spricht", Geist = Sans "steuert")

    func testSerifTokensUseNewsreader() {
        // Display, Title, ScreenTitle, Section, BodyItalic → Newsreader (Serif).
        let serifTokens: [TextStyle] = [.display, .title, .screenTitle, .section, .bodyItalic]
        for token in serifTokens {
            XCTAssertTrue(
                token.fontName.contains("Newsreader"),
                "Serif token \(token) should use Newsreader, got \(token.fontName)"
            )
        }
    }

    func testSansTokensUseGeist() {
        // Body, BodyEmphasis, Caption, Micro, Eyebrow → Geist (Sans).
        let sansTokens: [TextStyle] = [.body, .bodyEmphasis, .caption, .micro, .eyebrow]
        for token in sansTokens {
            XCTAssertTrue(
                token.fontName.contains("Geist"),
                "Sans token \(token) should use Geist, got \(token.fontName)"
            )
        }
    }

    func testBodyEmphasisUsesGeistMedium() {
        // CTAs sollen klar staerker ranken als normaler Body — Medium 500.
        XCTAssertEqual(TextStyle.bodyEmphasis.fontName, "Geist-Medium")
    }

    func testBodyItalicUsesNewsreaderItalic() {
        XCTAssertEqual(TextStyle.bodyItalic.fontName, "Newsreader16pt-Italic")
    }

    // MARK: - Tracking & Casing

    func testEyebrowHasTrackedCaps() {
        XCTAssertTrue(TextStyle.eyebrow.uppercase)
        XCTAssertGreaterThan(TextStyle.eyebrow.tracking, 0)
    }

    func testOnlyEyebrowIsUppercase() {
        for token in TextStyle.allCases where token != .eyebrow {
            XCTAssertFalse(token.uppercase, "Token \(token) must not force uppercase")
        }
    }

    func testTitleAndScreenTitleHaveTighterTracking() {
        // Editorial-Display: leicht enger fuer grosse Buchstaben.
        XCTAssertLessThan(TextStyle.title.tracking, 0)
        XCTAssertLessThan(TextStyle.screenTitle.tracking, 0)
    }

    func testBodyAndCaptionHaveNoTracking() {
        XCTAssertEqual(TextStyle.body.tracking, 0)
        XCTAssertEqual(TextStyle.caption.tracking, 0)
        XCTAssertEqual(TextStyle.micro.tracking, 0)
    }

    // MARK: - Bold-Text-Setting Bump

    func testBoldTextBumpsGeistRegularToMedium() {
        XCTAssertEqual(TextStyle.body.effectiveFontName(legibility: .bold), "Geist-Medium")
        XCTAssertEqual(TextStyle.caption.effectiveFontName(legibility: .bold), "Geist-Medium")
    }

    func testBoldTextBumpsGeistMediumToSemiBold() {
        // Setzt voraus, dass Geist-SemiBold im Bundle liegt (Schritt 1).
        XCTAssertEqual(TextStyle.bodyEmphasis.effectiveFontName(legibility: .bold), "Geist-SemiBold")
    }

    func testBoldTextBumpsNewsreaderLightToRegular() {
        XCTAssertEqual(TextStyle.title.effectiveFontName(legibility: .bold), "Newsreader16pt-Regular")
        XCTAssertEqual(TextStyle.screenTitle.effectiveFontName(legibility: .bold), "Newsreader16pt-Regular")
        XCTAssertEqual(TextStyle.section.effectiveFontName(legibility: .bold), "Newsreader16pt-Regular")
    }

    func testBoldTextKeepsItalic() {
        // Newsreader-Bold-Italic-Cut existiert im Bundle nicht — Italic bleibt Italic.
        XCTAssertEqual(TextStyle.bodyItalic.effectiveFontName(legibility: .bold), "Newsreader16pt-Italic")
    }

    func testRegularLegibilityReturnsDefaultFont() {
        for token in TextStyle.allCases {
            XCTAssertEqual(
                token.effectiveFontName(legibility: .regular),
                token.fontName,
                "Token \(token) should return default font when legibilityWeight is .regular"
            )
            XCTAssertEqual(
                token.effectiveFontName(legibility: nil),
                token.fontName,
                "Token \(token) should return default font when legibilityWeight is nil"
            )
        }
    }
}
