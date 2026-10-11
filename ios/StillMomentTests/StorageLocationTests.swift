//
//  StorageLocationTests.swift
//  Still Moment
//
//  ios-056: test runs use a storage of their own, never the app's real data.
//

import XCTest
@testable import StillMoment

final class StorageLocationTests: XCTestCase {
    // MARK: Internal

    override func tearDown() {
        // The test storage under test has a name of its own, so the one the running
        // unit-test host uses stays untouched.
        UserDefaults(suiteName: self.storageName)?.removePersistentDomain(forName: self.storageName)
        try? FileManager.default.removeItem(
            at: FileManager.default.temporaryDirectory.appendingPathComponent(self.storageName)
        )
        super.tearDown()
    }

    // MARK: - Which storage a launch gets

    func testUnitTestRunUsesTestStorage() {
        XCTAssertTrue(StorageLocation.usesTestStorage(arguments: [], isUnitTestHost: true))
    }

    func testUITestArgumentSelectsTestStorage() {
        XCTAssertTrue(StorageLocation.usesTestStorage(
            arguments: ["StillMoment", "-AppleLanguages", "(en)", "-UseTestStorage"],
            isUnitTestHost: false
        ))
    }

    func testNormalLaunchUsesTheAppsOwnStorage() {
        XCTAssertFalse(StorageLocation.usesTestStorage(
            arguments: ["StillMoment", "-AppleLanguages", "(en)", "-DisablePreparation"],
            isUnitTestHost: false
        ))
    }

    // MARK: - What the test storage guarantees

    func testFreshTestStorageStartsEmptyAfterAnEarlierRunLeftAMeditation() throws {
        // Given — an earlier test run imported a meditation and changed a setting
        let earlier = StorageLocation.freshTestStorage(named: self.storageName)
        let audioFile = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp3")
        FileManager.default.createFile(atPath: audioFile.path, contents: Data([0x1]))
        defer { try? FileManager.default.removeItem(at: audioFile) }
        _ = try GuidedMeditationService(userDefaults: earlier.userDefaults, baseDirectory: earlier.baseDirectory)
            .addMeditation(
                from: audioFile,
                metadata: AudioMetadata(artist: nil, title: nil, duration: 300),
                teacher: "Melissa Gein",
                name: "Achtsame Übung"
            )
        earlier.userDefaults.set(AppearanceMode.light.rawValue, forKey: "appearanceMode")

        // When — the next test launch asks for a test storage
        let fresh = StorageLocation.freshTestStorage(named: self.storageName)

        // Then — library, files and settings are gone
        let library = GuidedMeditationService(userDefaults: fresh.userDefaults, baseDirectory: fresh.baseDirectory)
        XCTAssertTrue(try library.loadMeditations().isEmpty)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: fresh.baseDirectory.path), [])
        XCTAssertNil(fresh.userDefaults.object(forKey: "appearanceMode"))
    }

    func testTestStorageIsSeparateFromTheAppsOwnStorage() {
        // Given
        let test = StorageLocation.freshTestStorage(named: self.storageName)
        let app = StorageLocation.production()
        let key = "storageLocationTests.\(UUID().uuidString)"

        // When — a test writes a setting
        test.userDefaults.set(true, forKey: key)

        // Then — the app's settings do not see it, and no folder lies inside the app's own
        XCTAssertNil(app.userDefaults.object(forKey: key))
        XCTAssertFalse(self.path(of: test.baseDirectory).hasPrefix(self.path(of: app.baseDirectory)))
        XCTAssertTrue(self.path(of: test.shareInboxDirectory).hasPrefix(self.path(of: test.baseDirectory)))
    }

    @MainActor
    func testLaunchArgumentsStillApplyInTestStorage() {
        // Given — the app was launched with "-appearanceMode light" (the Snapfile passes the
        // appearance the same way; light, because dark is the default anyway)
        let original = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        var arguments = original
        arguments["appearanceMode"] = AppearanceMode.light.rawValue
        UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
        defer { UserDefaults.standard.setVolatileDomain(original, forName: UserDefaults.argumentDomain) }

        // When — the app runs on a test storage
        let test = StorageLocation.freshTestStorage(named: self.storageName)
        let theme = ThemeManager(store: test.userDefaults)

        // Then — the launch argument still wins
        XCTAssertEqual(theme.appearanceMode, .light)
    }

    // MARK: Private

    private let storageName = "StillMomentTests.StorageLocationTests"

    private func path(of url: URL) -> String {
        url.standardizedFileURL.path + "/"
    }
}
