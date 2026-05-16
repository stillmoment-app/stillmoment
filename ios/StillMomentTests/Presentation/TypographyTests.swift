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

    // MARK: - Dark Mode Halation Compensation

    func testLightModeReturnsOriginalWeight() {
        let weights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        for weight in weights {
            XCTAssertEqual(
                weight.darkModeCompensated(.light),
                weight,
                "Light mode should return original weight"
            )
        }
    }

    func testDarkModeCompensatesUltraLightToThin() {
        XCTAssertEqual(Font.Weight.ultraLight.darkModeCompensated(.dark), .thin)
    }

    func testDarkModeCompensatesThinToLight() {
        XCTAssertEqual(Font.Weight.thin.darkModeCompensated(.dark), .light)
    }

    func testDarkModeCompensatesLightToRegular() {
        XCTAssertEqual(Font.Weight.light.darkModeCompensated(.dark), .regular)
    }

    func testDarkModeCompensatesRegularToMedium() {
        XCTAssertEqual(Font.Weight.regular.darkModeCompensated(.dark), .medium)
    }

    func testDarkModeDoesNotCompensateHeavierWeights() {
        let heavyWeights: [Font.Weight] = [.medium, .semibold, .bold, .heavy, .black]
        for weight in heavyWeights {
            XCTAssertEqual(
                weight.darkModeCompensated(.dark),
                weight,
                "Weights heavier than regular should not be compensated"
            )
        }
    }

    // MARK: - Role Uniqueness

    func testNoDuplicateRolesWithinSameGroup() {
        // Roles across groups may share specs (e.g. playerTimestamp and editCaption),
        // but within a group each role should be visually distinct.
        let groups: [(String, [TypographyRole])] = [
            ("Timer", [.timerCountdown, .timerRunning]),
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
        XCTAssertEqual(self.allRoles.count, 27, "Update this count when adding new TypographyRole cases")
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

    func testListTitleIsDynamicHeadlineWithoutWeight() {
        XCTAssertEqual(
            TypographyRole.listTitle.fontSpec,
            .dynamic(style: .headline, weight: nil)
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

    func testDefaultRoleHasNoTracking() {
        // Bestehende Rollen duerfen sich durch das Tracking-Feature nicht aendern.
        XCTAssertEqual(TypographyRole.bodyPrimary.tracking, 0, accuracy: 0.0001)
        XCTAssertEqual(TypographyRole.screenTitle.tracking, 0, accuracy: 0.0001)
    }

    // MARK: - Text Color Expectations

    func testPrimaryColorRoles() {
        let primaryRoles: [TypographyRole] = [
            .timerCountdown, .timerRunning,
            .screenTitle, .inlineNavigationTitle, .sectionTitle,
            .bodyPrimary,
            .settingsLabel,
            .playerTitle, .playerCountdown,
            .listTitle, .listSectionTitle, .listActionLabel,
            .editLabel,
            .dialogTitle
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
            .dialUnit
        ]
        for role in uiRoles {
            XCTAssertEqual(role.fontFamily, .ui, "Role \(role) should use the ui family (Geist)")
        }
    }

    /// Jede Rolle muss explizit einer Familie zugeordnet sein — die Aufteilung
    /// in Display+UI deckt alle 27 Rollen ab.
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
}
