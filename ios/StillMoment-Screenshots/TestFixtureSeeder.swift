//
//  TestFixtureSeeder.swift
//  Still Moment
//
//  Infrastructure - Test Fixture Seeder for Screenshots
//
//  Seeds the library with test meditations for screenshot automation.
//  This file belongs ONLY to StillMoment-Screenshots target.
//

import Foundation
import OSLog

/// Test fixture definition for screenshot automation
struct TestFixture {
    let resourceName: String
    let fileName: String
    let duration: TimeInterval
    let teacher: String
    let name: String
}

/// Seeds the meditation library with test fixtures for screenshot automation
///
/// This struct provides pre-defined meditation entries that point to
/// bundle resources, allowing the Screenshots target to launch with
/// a populated library without requiring manual imports.
enum TestFixtureSeeder {
    // MARK: Internal

    /// Test fixture definitions
    ///
    /// Each fixture maps to a silent MP3 file in Resources/TestFixtures/
    /// with realistic duration for authentic screenshots.
    static let fixtures: [TestFixture] = [
        TestFixture(
            resourceName: "test-mindful-breathing",
            fileName: "mindful-breathing.mp3",
            duration: 453,
            teacher: "Sarah Kornfield",
            name: "Mindful Breathing"
        ),
        TestFixture(
            resourceName: "test-body-scan",
            fileName: "body-scan.mp3",
            duration: 942,
            teacher: "Sarah Kornfield",
            name: "Body Scan for Beginners"
        ),
        TestFixture(
            resourceName: "test-loving-kindness",
            fileName: "loving-kindness.mp3",
            duration: 737,
            teacher: "Tara Goldstein",
            name: "Loving Kindness"
        ),
        TestFixture(
            resourceName: "test-evening-wind-down",
            fileName: "evening-wind-down.mp3",
            duration: 1145,
            teacher: "Tara Goldstein",
            name: "Evening Wind Down"
        ),
        TestFixture(
            resourceName: "test-present-moment",
            fileName: "present-moment.mp3",
            duration: 1548,
            teacher: "Jon Salzberg",
            name: "Present Moment Awareness"
        )
    ]

    /// Seeds test meditations if the library is empty
    ///
    /// - Parameter service: The meditation service to use for persistence
    static func seedIfNeeded(service: GuidedMeditationServiceProtocol) {
        do {
            let existing = try service.loadMeditations()
            guard existing.isEmpty else {
                Logger.infrastructure.debug("Library not empty, skipping test fixture seeding")
                return
            }

            let meditations = try createMeditations()
            try service.saveMeditations(meditations)

            Logger.infrastructure.info("Seeded \(meditations.count) test meditations for screenshots")
        } catch {
            Logger.infrastructure.error("Failed to seed test fixtures: \(error.localizedDescription)")
        }
    }

    /// Forces re-seeding of test meditations (clears existing and adds fixtures)
    ///
    /// - Parameter service: The meditation service to use for persistence
    static func forceSeed(service: GuidedMeditationServiceProtocol) {
        do {
            let meditations = try createMeditations()
            try service.saveMeditations(meditations)

            Logger.infrastructure.info("Force-seeded \(meditations.count) test meditations for screenshots")
        } catch {
            Logger.infrastructure.error("Failed to force-seed test fixtures: \(error.localizedDescription)")
        }
    }

    // MARK: Private

    /// Creates GuidedMeditation objects from fixtures
    ///
    /// - Returns: Array of GuidedMeditation objects with bundle bookmarks
    /// - Throws: If bundle resources cannot be found or bookmarks fail
    private static func createMeditations() throws -> [GuidedMeditation] {
        var meditations: [GuidedMeditation] = []

        for fixture in self.fixtures {
            guard let url = Bundle.main.url(forResource: fixture.resourceName, withExtension: "mp3") else {
                Logger.infrastructure.warning("Test fixture not found in bundle: \(fixture.resourceName)")
                continue
            }

            // Create bookmark for bundle URL
            // Note: Bundle URLs don't require security-scoped access,
            // but we create a bookmark for consistency with the data model
            let bookmark = try url.bookmarkData()

            let meditation = GuidedMeditation(
                fileBookmark: bookmark,
                fileName: fixture.fileName,
                duration: fixture.duration,
                teacher: fixture.teacher,
                name: fixture.name
            )

            meditations.append(meditation)
        }

        return meditations
    }
}
