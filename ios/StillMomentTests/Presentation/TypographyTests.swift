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
            ("Headings", [.screenTitle, .sectionTitle]),
            ("Body", [.bodyPrimary, .bodySecondary, .caption]),
            ("Settings", [.settingsLabel, .settingsDescription]),
            ("Player", [.playerTitle, .playerTeacher, .playerTimestamp, .playerCountdown]),
            ("List", [.listTitle, .listSubtitle, .listBody, .listSectionTitle, .listActionLabel]),
            ("Edit", [.editLabel, .editCaption])
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
        XCTAssertEqual(self.allRoles.count, 20, "Update this count when adding new TypographyRole cases")
    }

    // MARK: - Font Spec Expectations

    func testTimerCountdownIsFixedUltraLight100() {
        XCTAssertEqual(
            TypographyRole.timerCountdown.fontSpec,
            .fixed(size: 100, weight: .ultraLight, design: .rounded)
        )
    }

    func testTimerRunningIsFixedThin60() {
        XCTAssertEqual(
            TypographyRole.timerRunning.fontSpec,
            .fixed(size: 60, weight: .thin, design: .rounded)
        )
    }

    func testScreenTitleIsFixedLight28() {
        XCTAssertEqual(
            TypographyRole.screenTitle.fontSpec,
            .fixed(size: 28, weight: .light, design: .rounded)
        )
    }

    func testSettingsLabelIsFixedRegular17() {
        XCTAssertEqual(
            TypographyRole.settingsLabel.fontSpec,
            .fixed(size: 17, weight: .regular, design: .rounded)
        )
    }

    func testListTitleIsDynamicHeadlineWithoutWeight() {
        XCTAssertEqual(
            TypographyRole.listTitle.fontSpec,
            .dynamic(style: .headline, weight: nil, design: .rounded)
        )
    }

    // MARK: - Text Color Expectations

    func testPrimaryColorRoles() {
        let primaryRoles: [TypographyRole] = [
            .timerCountdown, .timerRunning,
            .screenTitle, .sectionTitle,
            .bodyPrimary,
            .settingsLabel,
            .playerTitle, .playerCountdown,
            .listTitle, .listSectionTitle, .listActionLabel,
            .editLabel
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
            .listSubtitle, .listBody,
            .editCaption
        ]
        for role in secondaryRoles {
            XCTAssertEqual(role.textColor, \ThemeColors.textSecondary, "Role \(role) should use textSecondary")
        }
    }

    func testPlayerTeacherUsesInteractiveColor() {
        XCTAssertEqual(TypographyRole.playerTeacher.textColor, \ThemeColors.interactive)
    }

    // MARK: - Design Consistency

    func testAllRolesUseRoundedDesign() {
        for role in self.allRoles {
            switch role.fontSpec {
            case let .fixed(_, _, design):
                XCTAssertEqual(design, .rounded, "Role \(role) should use rounded design")
            case let .dynamic(_, _, design):
                XCTAssertEqual(design, .rounded, "Role \(role) should use rounded design")
            }
        }
    }
}
