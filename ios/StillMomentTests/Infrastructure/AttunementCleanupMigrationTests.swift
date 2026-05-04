//
//  AttunementCleanupMigrationTests.swift
//  Still Moment
//
//  Tests for AttunementCleanupMigration (shared-088 silent legacy cleanup)
//

import XCTest
@testable import StillMoment

final class AttunementCleanupMigrationTests: XCTestCase {
    // MARK: - Properties

    private static let suiteName = "AttunementCleanupMigrationTests"

    private var testDefaults: UserDefaults?
    private var testAppSupport: URL?

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        self.testDefaults = UserDefaults(suiteName: Self.suiteName)
        self.testDefaults?.removePersistentDomain(forName: Self.suiteName)

        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )
        self.testAppSupport = dir
    }

    override func tearDown() {
        if let dir = testAppSupport {
            try? FileManager.default.removeItem(at: dir)
        }
        self.testDefaults?.removePersistentDomain(forName: Self.suiteName)
        self.testDefaults = nil
        self.testAppSupport = nil
        super.tearDown()
    }

    // MARK: - UserDefaults Cleanup

    func testRunIfNeeded_removesLegacyIntroductionKeys() {
        guard let defaults = testDefaults else {
            return XCTFail("testDefaults not initialized")
        }
        // Given - legacy persisted attunement settings from pre-shared-088 build
        defaults.set("breath", forKey: "introductionId")
        defaults.set(true, forKey: "introductionEnabled")
        defaults.set(Data(), forKey: "customAudioFiles_attunement")

        // When
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            applicationSupportURL: self.testAppSupport
        )

        // Then
        XCTAssertNil(defaults.object(forKey: "introductionId"))
        XCTAssertNil(defaults.object(forKey: "introductionEnabled"))
        XCTAssertNil(defaults.object(forKey: "customAudioFiles_attunement"))
    }

    func testRunIfNeeded_setsMarkerAfterRun() {
        guard let defaults = testDefaults else {
            return XCTFail("testDefaults not initialized")
        }

        // When
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            applicationSupportURL: self.testAppSupport
        )

        // Then
        XCTAssertTrue(defaults.bool(forKey: AttunementCleanupMigration.markerKey))
    }

    // MARK: - Idempotency

    func testRunIfNeeded_isIdempotent_doesNotTouchKeysOnSecondRun() {
        guard let defaults = testDefaults else {
            return XCTFail("testDefaults not initialized")
        }
        // Given - first run completes, marker is set
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            applicationSupportURL: self.testAppSupport
        )
        // Simulate a legacy key being re-added between launches (shouldn't happen,
        // but proves the migration won't re-run and clobber it).
        defaults.set("sentinel", forKey: "introductionId")

        // When - second run
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            applicationSupportURL: self.testAppSupport
        )

        // Then - second run was a no-op, sentinel value survives
        XCTAssertEqual(defaults.string(forKey: "introductionId"), "sentinel")
    }

    // MARK: - Filesystem Cleanup

    func testRunIfNeeded_removesAttunementDirectoryAndFiles() throws {
        guard let defaults = testDefaults, let appSupport = testAppSupport else {
            return XCTFail("setup not initialized")
        }
        // Given - legacy attunement directory with two MP3 files
        let attunementDir = appSupport.appendingPathComponent("CustomAudio/attunements")
        try FileManager.default.createDirectory(
            at: attunementDir,
            withIntermediateDirectories: true
        )
        try Data().write(to: attunementDir.appendingPathComponent("a.mp3"))
        try Data().write(to: attunementDir.appendingPathComponent("b.mp3"))

        // When
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            applicationSupportURL: appSupport
        )

        // Then
        XCTAssertFalse(FileManager.default.fileExists(atPath: attunementDir.path))
    }

    func testRunIfNeeded_withoutAttunementDirectory_doesNotCrash() {
        guard let defaults = testDefaults, let appSupport = testAppSupport else {
            return XCTFail("setup not initialized")
        }
        // Given - fresh install: no legacy directory exists

        // When / Then - no crash, marker is set
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            applicationSupportURL: appSupport
        )
        XCTAssertTrue(defaults.bool(forKey: AttunementCleanupMigration.markerKey))
    }
}
