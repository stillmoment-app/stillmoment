//
//  TypographyTests.swift
//  Still Moment
//
//  Unit tests for the centralized Typography System (Font+Theme.swift).
//

import SwiftUI
import XCTest
@testable import StillMoment

final class TypographyTests: XCTestCase {
    // MARK: - All Roles (used for exhaustive tests)

    private let allRoles = TypographyRole.allCases

    // MARK: - Role Uniqueness

    func testNoDuplicateRolesWithinSameGroup() {
        // Roles across groups may share specs (e.g. playerTimestamp and editCaption),
        // but within a group each role should be visually distinct.
        let groups: [(String, [TypographyRole])] = [
            ("Timer", [.timerCountdown, .timerRunning, .timerStepperValue]),
            ("Buttons", [.buttonLabel]),
            ("Headings", [.screenTitle, .inlineNavigationTitle, .sectionTitle]),
            ("Body", [.bodyPrimary, .bodySecondary, .caption]),
            ("Settings", [.settingsLabel, .settingsDescription]),
            ("Player", [.playerTitle, .playerTeacher, .playerTimestamp, .playerCountdown, .playerRemainingTime]),
            ("List", [.listTitle, .listSubtitle, .listBody, .listSectionTitle, .listActionLabel]),
            ("Edit", [.editLabel, .editCaption]),
            ("Dialog", [.dialogTitle, .dialogBody]),
            ("Card", [.cardLabel]),
            ("Dial", [.dialValue, .dialUnit])
        ]

        for (groupName, roles) in groups {
            var seen: [(TypographyRole.FontSpec, KeyPath<ThemeColors, Color>)] = []
            for role in roles {
                let spec = role.fontSpec
                let color = role.textColor
                let isDuplicate = seen.contains { $0.0 == spec && $0.1 == color }
                XCTAssertFalse(isDuplicate, "\(groupName): Role \(role) duplicates another role in the same group")
                seen.append((spec, color))
            }
        }
    }

    func testAllRolesCovered() {
        XCTAssertEqual(self.allRoles.count, 29, "Update this count when adding new TypographyRole cases")
    }

    // MARK: - Font Spec Expectations

    func testTimerCountdownIsFixedUltraLight100() {
        XCTAssertEqual(
            TypographyRole.timerCountdown.fontSpec,
            .fixed(size: 100, weight: .ultraLight)
        )
    }

    func testTimerRunningIsFixedThin64() {
        // ios-046: Restzeit-Display im Sanduhr-Running-Screen.
        // 64 pt entspricht dem Handoff (Newsreader 64/300).
        XCTAssertEqual(
            TypographyRole.timerRunning.fontSpec,
            .fixed(size: 64, weight: .thin)
        )
    }

    func testTimerRunningHasNegativeTracking() {
        // ios-046: Restzeit braucht negatives Tracking (~-0.02em bei 64 pt),
        // damit die grosse Ziffer kompakt wirkt.
        XCTAssertLessThan(TypographyRole.timerRunning.tracking, 0)
    }

    func testScreenTitleIsFixedLight28() {
        XCTAssertEqual(
            TypographyRole.screenTitle.fontSpec,
            .fixed(size: 28, weight: .light)
        )
    }

    func testSettingsLabelIsFixedRegular17() {
        XCTAssertEqual(
            TypographyRole.settingsLabel.fontSpec,
            .fixed(size: 17, weight: .regular)
        )
    }

    func testListTitleIsFixedRegular14() {
        // Author-Header in der Library: Geist Regular 14 — kein Bold, kein Headline-Style.
        XCTAssertEqual(
            TypographyRole.listTitle.fontSpec,
            .fixed(size: 14, weight: .regular)
        )
    }

    func testListActionLabelIsFixedRegular15() {
        // Track-Titel: Geist Regular 15 — "minimal groesser" als Author-Header (14),
        // damit kein groessen-induzierter Weight-Eindruck entsteht.
        XCTAssertEqual(
            TypographyRole.listActionLabel.fontSpec,
            .fixed(size: 15, weight: .regular)
        )
    }

    func testDialogTitleIsFixedLight18() {
        XCTAssertEqual(
            TypographyRole.dialogTitle.fontSpec,
            .fixed(size: 18, weight: .light)
        )
    }

    func testDialogBodyIsFixedRegular12() {
        XCTAssertEqual(
            TypographyRole.dialogBody.fontSpec,
            .fixed(size: 12, weight: .regular)
        )
    }

    // MARK: - Player Role Specs (Editorial-Voice)

    func testPlayerTitleIsFixedLight30() {
        // Meditationstitel: Newsreader Light 30 — Editorial-Stimme, ruhig.
        XCTAssertEqual(
            TypographyRole.playerTitle.fontSpec,
            .fixed(size: 30, weight: .light)
        )
    }

    func testPlayerTeacherIsFixedLight18Italic() {
        // Lehrer-Name: Newsreader Italic 18 — kursiver Akzent in Sunrise,
        // setzt visuell vom Titel ab (Editorial-Hierarchie).
        XCTAssertEqual(
            TypographyRole.playerTeacher.fontSpec,
            .fixed(size: 18, weight: .light)
        )
        XCTAssertTrue(TypographyRole.playerTeacher.isItalic)
    }

    func testPlayerRemainingTimeIsFixedRegular11() {
        // Eyebrow "NOCH X MIN": Geist Regular 11 — sehr ruhig, gross zuegig getrackt.
        XCTAssertEqual(
            TypographyRole.playerRemainingTime.fontSpec,
            .fixed(size: 11, weight: .regular)
        )
    }

    func testPlayerRemainingTimeHasGenerousTracking() {
        // ~0.2em bei 11 pt = 2.2 pt — verleiht der All-Caps-Beschriftung Format.
        XCTAssertEqual(TypographyRole.playerRemainingTime.tracking, 2.2, accuracy: 0.0001)
    }

    func testIsItalicDefaultsToFalse() {
        // Nur explizit gesetzte Rollen sind kursiv — alle anderen sind aufrecht.
        let nonItalicRoles = TypographyRole.allCases.filter { $0 != .playerTeacher }
        for role in nonItalicRoles {
            XCTAssertFalse(role.isItalic, "Role \(role) should not be italic by default")
        }
    }

    // MARK: - Breath Dial Roles (shared-086)

    func testCardLabelIsFixedRegular11() {
        XCTAssertEqual(
            TypographyRole.cardLabel.fontSpec,
            .fixed(size: 11, weight: .regular)
        )
    }

    func testCardLabelUsesSecondaryColor() {
        XCTAssertEqual(TypographyRole.cardLabel.textColor, \ThemeColors.textSecondary)
    }

    func testDialValueIsFixedLight62() {
        // 62 px ist die kompakte Untergrenze; Views skalieren bis 76 ueber size-Override.
        XCTAssertEqual(
            TypographyRole.dialValue.fontSpec,
            .fixed(size: 62, weight: .light)
        )
    }

    func testDialValueUsesPrimaryColor() {
        XCTAssertEqual(TypographyRole.dialValue.textColor, \ThemeColors.textPrimary)
    }

    func testDialValueHasNegativeTracking() {
        XCTAssertLessThan(TypographyRole.dialValue.tracking, 0)
    }

    func testDialUnitIsFixedRegular10() {
        XCTAssertEqual(
            TypographyRole.dialUnit.fontSpec,
            .fixed(size: 10, weight: .regular)
        )
    }

    func testDialUnitUsesSecondaryColor() {
        XCTAssertEqual(TypographyRole.dialUnit.textColor, \ThemeColors.textSecondary)
    }

    func testDialUnitHasNoTracking() {
        // Sentence-Case-Label ("Minuten") braucht kein Letter-Spacing.
        XCTAssertEqual(TypographyRole.dialUnit.tracking, 0, accuracy: 0.0001)
    }

    // MARK: - Button + Stepper Roles (Handoff "Kerzenschein 2.0")

    func testButtonLabelIsFixedMedium15() {
        // Handoff: "CTA / Play — 15 / 500 — Geist". Loest die alte
        // SF-Pro-Rounded-Voice ab.
        XCTAssertEqual(
            TypographyRole.buttonLabel.fontSpec,
            .fixed(size: 15, weight: .medium)
        )
    }

    func testButtonLabelUsesGeistFamily() {
        XCTAssertEqual(TypographyRole.buttonLabel.fontFamily, .ui)
    }

    func testTimerStepperValueIsFixedRegular15() {
        // Stepper-Werte (Idle-Settings-Liste): Geist Regular, Default 15pt,
        // size-Override fuer compact height (14pt).
        XCTAssertEqual(
            TypographyRole.timerStepperValue.fontSpec,
            .fixed(size: 15, weight: .regular)
        )
    }

    func testTimerStepperValueUsesGeistFamily() {
        XCTAssertEqual(TypographyRole.timerStepperValue.fontFamily, .ui)
    }

    func testDefaultRoleHasNoTracking() {
        // Bestehende Rollen duerfen sich durch das Tracking-Feature nicht aendern.
        XCTAssertEqual(TypographyRole.bodyPrimary.tracking, 0, accuracy: 0.0001)
        XCTAssertEqual(TypographyRole.screenTitle.tracking, 0, accuracy: 0.0001)
    }

    // MARK: - Text Color Expectations

    func testPrimaryColorRoles() {
        let primaryRoles: [TypographyRole] = [
            .timerCountdown, .timerRunning, .timerStepperValue,
            .screenTitle, .inlineNavigationTitle, .sectionTitle,
            .bodyPrimary,
            .settingsLabel,
            .playerTitle, .playerCountdown,
            .listTitle, .listSectionTitle, .listActionLabel,
            .editLabel,
            .dialogTitle,
            .buttonLabel
        ]
        for role in primaryRoles {
            XCTAssertEqual(role.textColor, \ThemeColors.textPrimary, "Role \(role) should use textPrimary")
        }
    }

    func testSecondaryColorRoles() {
        let secondaryRoles: [TypographyRole] = [
            .bodySecondary, .caption,
            .settingsDescription,
            .playerTimestamp,
            .playerRemainingTime,
            .listSubtitle, .listBody,
            .editCaption,
            .dialogBody
        ]
        for role in secondaryRoles {
            XCTAssertEqual(role.textColor, \ThemeColors.textSecondary, "Role \(role) should use textSecondary")
        }
    }

    func testPlayerTeacherUsesInteractiveColor() {
        XCTAssertEqual(TypographyRole.playerTeacher.textColor, \ThemeColors.interactive)
    }

    // MARK: - Font Family Mapping (ios-048)

    /// Display-Rollen (Handoff: "Stimme, Inhalt, Numerik") werden in Newsreader (Serif) gesetzt.
    func testDisplayRolesUseNewsreaderFamily() {
        let displayRoles: [TypographyRole] = [
            .timerCountdown, .timerRunning,
            .screenTitle, .inlineNavigationTitle, .sectionTitle,
            .bodyPrimary, .bodySecondary,
            .playerTitle, .playerTeacher, .playerCountdown,
            .dialogTitle,
            .dialValue
        ]
        for role in displayRoles {
            XCTAssertEqual(role.fontFamily, .display, "Role \(role) should use the display family (Newsreader)")
        }
    }

    /// UI-Rollen (Handoff: "Labels, Werte, Steuerung") werden in Geist (Sans) gesetzt.
    func testUIRolesUseGeistFamily() {
        let uiRoles: [TypographyRole] = [
            .caption,
            .settingsLabel, .settingsDescription,
            .playerTimestamp, .playerRemainingTime,
            .listTitle, .listSubtitle, .listBody, .listSectionTitle, .listActionLabel,
            .editLabel, .editCaption,
            .dialogBody,
            .cardLabel,
            .dialUnit,
            .buttonLabel, .timerStepperValue
        ]
        for role in uiRoles {
            XCTAssertEqual(role.fontFamily, .ui, "Role \(role) should use the ui family (Geist)")
        }
    }

    /// Jede Rolle muss explizit einer Familie zugeordnet sein — die Aufteilung
    /// in Display+UI deckt alle 29 Rollen ab.
    func testEveryRoleHasFontFamily() {
        for role in self.allRoles {
            let family = role.fontFamily
            XCTAssertTrue(family == .display || family == .ui, "Role \(role) must be display or ui")
        }
    }

    // MARK: - Family PostScript Name Mapping

    func testDisplayFamilyMapsLightWeightsToNewsreaderLight() {
        // ultraLight/thin/light klemmen auf Newsreader 300 (Light).
        let lightWeights: [Font.Weight] = [.ultraLight, .thin, .light]
        for weight in lightWeights {
            XCTAssertEqual(
                TypographyRole.Family.display.postScriptName(for: weight),
                "Newsreader16pt-Light"
            )
        }
    }

    func testDisplayFamilyMapsRegularToNewsreaderRegular() {
        XCTAssertEqual(
            TypographyRole.Family.display.postScriptName(for: .regular),
            "Newsreader16pt-Regular"
        )
    }

    func testDisplayFamilyMapsHeavyWeightsToNewsreaderMedium() {
        // medium/semibold/bold/heavy klemmen auf Newsreader 500 (Medium).
        let heavyWeights: [Font.Weight] = [.medium, .semibold, .bold, .heavy]
        for weight in heavyWeights {
            XCTAssertEqual(
                TypographyRole.Family.display.postScriptName(for: weight),
                "Newsreader16pt-Medium"
            )
        }
    }

    func testUIFamilyMapsLightWeightsToGeistLight() {
        XCTAssertEqual(
            TypographyRole.Family.ui.postScriptName(for: .light),
            "Geist-Light"
        )
    }

    func testUIFamilyMapsRegularToGeistRegular() {
        XCTAssertEqual(
            TypographyRole.Family.ui.postScriptName(for: .regular),
            "Geist-Regular"
        )
    }

    func testUIFamilyMapsHeavyWeightsToGeistMedium() {
        XCTAssertEqual(
            TypographyRole.Family.ui.postScriptName(for: .semibold),
            "Geist-Medium"
        )
    }

    // MARK: - Italic Variant (Display only)

    func testDisplayFamilyMapsItalicToNewsreaderItalic() {
        // Italic ist eine eigene Schnittdatei (Newsreader16pt-Italic) — der
        // Weight-Parameter wird ignoriert, weil nur ein Italic-Cut existiert.
        let allWeights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold]
        for weight in allWeights {
            XCTAssertEqual(
                TypographyRole.Family.display.postScriptName(for: weight, italic: true),
                "Newsreader16pt-Italic"
            )
        }
    }

    func testUIFamilyIgnoresItalicFlag() {
        // Geist hat keinen Italic-Cut im Bundle — der Flag wird stillschweigend
        // ignoriert, Geist faellt zurueck auf den weight-basierten Namen.
        XCTAssertEqual(
            TypographyRole.Family.ui.postScriptName(for: .regular, italic: true),
            "Geist-Regular"
        )
    }

    // MARK: - Bundled Font Cuts (Schritt 1 Typografie 2.1)

    /// Schritt 1 der Typografie-2.1-Migration verlangt, dass alle erwarteten
    /// Schriftschnitte registriert sind. Dieser Test ist die Acceptance —
    /// wenn ein Cut fehlt, ist `UIAppFonts` schief oder die Datei nicht im Target.
    func testNewsreaderFamilyShipsRequiredCuts() {
        let expected = [
            "Newsreader16pt-Light",
            "Newsreader16pt-Regular",
            "Newsreader16pt-Medium",
            "Newsreader16pt-Italic"
        ]
        let available = Self.fontNames(forFamiliesContaining: "Newsreader")
        for name in expected {
            XCTAssertTrue(
                available.contains(name),
                "Erwarteter Newsreader-Cut fehlt: \(name). Verfuegbar: \(available)"
            )
        }
    }

    func testGeistFamilyShipsRequiredCutsIncludingSemiBold() {
        // SemiBold ist neu (Typografie 2.1) — Bold-Text-Setting bumpt .bodyEmphasis
        // von Geist-Medium auf Geist-SemiBold.
        let expected = [
            "Geist-Light",
            "Geist-Regular",
            "Geist-Medium",
            "Geist-SemiBold"
        ]
        let available = Self.fontNames(forFamiliesContaining: "Geist")
        for name in expected {
            XCTAssertTrue(
                available.contains(name),
                "Erwarteter Geist-Cut fehlt: \(name). Verfuegbar: \(available)"
            )
        }
    }

    private static func fontNames(forFamiliesContaining needle: String) -> [String] {
        UIFont.familyNames
            .filter { $0.contains(needle) }
            .flatMap { UIFont.fontNames(forFamilyName: $0) }
    }
}
