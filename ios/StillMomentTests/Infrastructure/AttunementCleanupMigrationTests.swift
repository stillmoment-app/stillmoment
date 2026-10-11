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

    private var storage: TestStorage?

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.storage = try TestStorage()
    }

    override func tearDown() {
        self.storage?.remove()
        self.storage = nil
        super.tearDown()
    }

    // MARK: - UserDefaults Cleanup

    func testRunIfNeeded_removesLegacyIntroductionKeys() throws {
        let storage = try XCTUnwrap(self.storage)
        let defaults = storage.userDefaults
        // Given - legacy persisted attunement settings from pre-shared-088 build
        defaults.set("breath", forKey: "introductionId")
        defaults.set(true, forKey: "introductionEnabled")
        defaults.set(Data(), forKey: "customAudioFiles_attunement")

        // When
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            baseDirectory: storage.baseDirectory
        )

        // Then
        XCTAssertNil(defaults.object(forKey: "introductionId"))
        XCTAssertNil(defaults.object(forKey: "introductionEnabled"))
        XCTAssertNil(defaults.object(forKey: "customAudioFiles_attunement"))
    }

    func testRunIfNeeded_setsMarkerAfterRun() throws {
        let storage = try XCTUnwrap(self.storage)
        let defaults = storage.userDefaults

        // When
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            baseDirectory: storage.baseDirectory
        )

        // Then
        XCTAssertTrue(defaults.bool(forKey: AttunementCleanupMigration.markerKey))
    }

    // MARK: - Idempotency

    func testRunIfNeeded_isIdempotent_doesNotTouchKeysOnSecondRun() throws {
        let storage = try XCTUnwrap(self.storage)
        let defaults = storage.userDefaults
        // Given - first run completes, marker is set
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            baseDirectory: storage.baseDirectory
        )
        // Simulate a legacy key being re-added between launches (shouldn't happen,
        // but proves the migration won't re-run and clobber it).
        defaults.set("sentinel", forKey: "introductionId")

        // When - second run
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            baseDirectory: storage.baseDirectory
        )

        // Then - second run was a no-op, sentinel value survives
        XCTAssertEqual(defaults.string(forKey: "introductionId"), "sentinel")
    }

    // MARK: - Filesystem Cleanup

    func testRunIfNeeded_removesAttunementDirectoryAndFiles() throws {
        let storage = try XCTUnwrap(self.storage)
        let defaults = storage.userDefaults
        let appSupport = storage.baseDirectory
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
            baseDirectory: appSupport
        )

        // Then
        XCTAssertFalse(FileManager.default.fileExists(atPath: attunementDir.path))
    }

    func testRunIfNeeded_withoutAttunementDirectory_doesNotCrash() throws {
        let storage = try XCTUnwrap(self.storage)
        let defaults = storage.userDefaults
        let appSupport = storage.baseDirectory
        // Given - fresh install: no legacy directory exists

        // When / Then - no crash, marker is set
        AttunementCleanupMigration.runIfNeeded(
            userDefaults: defaults,
            baseDirectory: appSupport
        )
        XCTAssertTrue(defaults.bool(forKey: AttunementCleanupMigration.markerKey))
    }
}
