//
//  ShareInboxTests.swift
//  Still Moment
//
//  shared-132: Die Share-Extension legt geteilte Links und Audiodateien in der Inbox ab.
//  Mehrfaches Teilen darf nie scheitern; der zuletzt geteilte Eintrag ersetzt einen
//  gleichnamigen, der noch wartet.
//

import XCTest
@testable import StillMoment

final class ShareInboxTests: XCTestCase {
    // MARK: Internal

    static let talk25401 = "https://www.audiodharma.org/talks/25401/download"
    static let talk25402 = "https://www.audiodharma.org/talks/25402/download"

    // swiftlint:disable:next implicitly_unwrapped_optional
    var inboxDirectory: URL!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sourceDirectory: URL!

    override func setUp() {
        super.setUp()
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("ShareInboxTests-\(UUID().uuidString)")
        self.inboxDirectory = base.appendingPathComponent("ShareInbox")
        self.sourceDirectory = base.appendingPathComponent("Source")
        try? FileManager.default.createDirectory(at: self.inboxDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: self.sourceDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: self.inboxDirectory.deletingLastPathComponent())
        self.inboxDirectory = nil
        self.sourceDirectory = nil
        super.tearDown()
    }

    // MARK: - Einzelnes Teilen (Erhalt)

    func testSharedLinkIsStoredSoTheAppCanReadAddressAndFilename() throws {
        // Given
        let link = try XCTUnwrap(URL(string: Self.talk25401))

        // When
        let entry = try ShareInbox.storeLink(link, in: self.inboxDirectory)

        // Then — die App liest den Eintrag mit demselben Schema
        let reference = try JSONDecoder().decode(URLReference.self, from: Data(contentsOf: entry))
        XCTAssertEqual(reference.url, Self.talk25401)
        XCTAssertEqual(reference.filename, "download")
        XCTAssertEqual(try self.visibleEntries(), [entry.lastPathComponent])
    }

    func testSharedAudioFileIsStoredUnderItsOwnName() throws {
        // Given
        let source = try self.makeSourceFile(named: "Vortrag.mp3", byte: 0xAA)

        // When
        let entry = try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)

        // Then
        XCTAssertEqual(entry.lastPathComponent, "Vortrag.mp3")
        XCTAssertEqual(try Data(contentsOf: entry), try Data(contentsOf: source))
        XCTAssertEqual(try self.visibleEntries(), ["Vortrag.mp3"])
    }

    func testOldAudioFileCountsAsFreshlyShared() throws {
        // Given — die geteilte Datei ist laengst aelter als 24 Stunden
        let source = try self.makeSourceFile(named: "Vortrag.mp3", byte: 0xAA)
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-30 * 24 * 3600)],
            ofItemAtPath: source.path
        )

        // When
        let entry = try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)

        // Then — die App raeumt den Eintrag nicht als veraltet weg
        let modified = try XCTUnwrap(self.modificationDate(of: entry))
        XCTAssertEqual(modified.timeIntervalSinceNow, 0, accuracy: 60)
    }

    func testUnreadableAudioFileFailsWithoutLeavingAnything() throws {
        // Given — die Quelle ist nicht (mehr) da
        let missing = self.sourceDirectory.appendingPathComponent("Weg.mp3")

        // When / Then
        XCTAssertThrowsError(try ShareInbox.storeAudioFile(from: missing, in: self.inboxDirectory))
        XCTAssertEqual(try self.allEntriesIncludingHidden(), [])
    }

    // MARK: - Mehrfach geteilt

    func testSameLinkSharedTwiceSucceedsAndLeavesOneEntry() throws {
        // Given
        let link = try XCTUnwrap(URL(string: Self.talk25401))
        try ShareInbox.storeLink(link, in: self.inboxDirectory)

        // When — versehentlich doppelt geteilt
        XCTAssertNoThrow(try ShareInbox.storeLink(link, in: self.inboxDirectory))

        // Then
        XCTAssertEqual(try self.visibleEntries(), ["download.json"])
        XCTAssertEqual(try self.allEntriesIncludingHidden(), ["download.json"], "Keine Temp-Datei bleibt liegen")
    }

    func testLaterLinkWithSameEndingReplacesTheWaitingOne() throws {
        // Given
        let first = try XCTUnwrap(URL(string: Self.talk25401))
        let second = try XCTUnwrap(URL(string: Self.talk25402))
        try ShareInbox.storeLink(first, in: self.inboxDirectory)

        // When
        let entry = try ShareInbox.storeLink(second, in: self.inboxDirectory)

        // Then — es wartet nur noch 25402
        XCTAssertEqual(try self.visibleEntries(), ["download.json"])
        let reference = try JSONDecoder().decode(URLReference.self, from: Data(contentsOf: entry))
        XCTAssertEqual(reference.url, Self.talk25402)
    }

    func testSameAudioFileSharedTwiceSucceedsAndLeavesOneEntry() throws {
        // Given
        let source = try self.makeSourceFile(named: "Vortrag.mp3", byte: 0xAA)
        try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)

        // When
        XCTAssertNoThrow(try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory))

        // Then
        XCTAssertEqual(try self.visibleEntries(), ["Vortrag.mp3"])
        XCTAssertEqual(try self.allEntriesIncludingHidden(), ["Vortrag.mp3"], "Keine Temp-Datei bleibt liegen")
    }

    func testResharedFileWaitingForMoreThan24HoursCountsAsFresh() throws {
        // Given — ein gleichnamiger Eintrag wartet seit 25 Stunden
        let source = try self.makeSourceFile(named: "Vortrag.mp3", byte: 0xAA)
        let waiting = try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(-25 * 3600)],
            ofItemAtPath: waiting.path
        )

        // When
        let entry = try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)

        // Then — die App importiert ihn, statt ihn als veraltet wegzuraeumen
        let modified = try XCTUnwrap(self.modificationDate(of: entry))
        XCTAssertEqual(modified.timeIntervalSinceNow, 0, accuracy: 60)
    }

    func testFailedReshareKeepsTheWaitingEntry() throws {
        // Given — Vortrag.mp3 wartet schon
        let source = try self.makeSourceFile(named: "Vortrag.mp3", byte: 0xAA)
        try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)
        try FileManager.default.removeItem(at: source)

        // When — die erneut geteilte Datei laesst sich nicht lesen
        XCTAssertThrowsError(try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory))

        // Then — der wartende Eintrag ist unversehrt
        let waiting = self.inboxDirectory.appendingPathComponent("Vortrag.mp3")
        XCTAssertEqual(try Data(contentsOf: waiting), Data(repeating: 0xAA, count: 64))
        XCTAssertEqual(try self.allEntriesIncludingHidden(), ["Vortrag.mp3"])
    }

    // MARK: - Ersetzen ohne Luecke

    func testResharedAudioFileReplacesWaitingEntryWithoutGap() throws {
        // Given — Vortrag.mp3 wartet schon
        let source = try self.makeSourceFile(named: "Vortrag.mp3", byte: 0xAA)
        try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)
        let waiting = self.inboxDirectory.appendingPathComponent("Vortrag.mp3")
        let fileManager = InboxWatchingFileManager(watched: waiting)

        // When
        try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory, fileManager: fileManager)

        // Then — die App findet den Eintrag in jedem Moment
        XCTAssertEqual(fileManager.removedWatchedItem, 0, "Der wartende Eintrag darf nie zuerst entfernt werden")
        XCTAssertEqual(try self.visibleEntries(), ["Vortrag.mp3"])
    }

    // MARK: - Datum

    func testReplacedEntryCarriesTheDateOfTheNewShare() throws {
        // Given — ein gleichnamiger Eintrag mit anderem Datum wartet
        let source = try self.makeSourceFile(named: "Vortrag.mp3", byte: 0xAA)
        try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory, date: Date(timeIntervalSince1970: 1000))
        let sharedAt = Date(timeIntervalSince1970: 2_000_000_000)

        // When
        let entry = try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory, date: sharedAt)

        // Then — das Datum des neuen Teilens gilt, nicht das des ersetzten Eintrags
        let modified = try XCTUnwrap(self.modificationDate(of: entry))
        XCTAssertEqual(modified.timeIntervalSince1970, sharedAt.timeIntervalSince1970, accuracy: 1)
    }

    func testAudioFileWhoseDateCannotBeSetIsReportedAsFailure() throws {
        // Given — das Datum laesst sich nicht setzen; die Kopie traegt das alte Datum
        // des Originals und wuerde von der App als veraltet weggeraeumt
        let source = try self.makeSourceFile(named: "Vortrag.mp3", byte: 0xAA)
        let fileManager = InboxWatchingFileManager(watched: nil)
        fileManager.failSettingAttributes = true

        // When / Then — lieber "Import fehlgeschlagen" als eine falsche Erfolgsmeldung
        XCTAssertThrowsError(
            try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory, fileManager: fileManager)
        )
        XCTAssertEqual(try self.allEntriesIncludingHidden(), [], "Keine Temp-Datei bleibt liegen")
    }

    func testFailedDateOnReshareKeepsTheWaitingEntry() throws {
        // Given — Vortrag.mp3 wartet schon
        let source = try self.makeSourceFile(named: "Vortrag.mp3", byte: 0xAA)
        try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory)
        let fileManager = InboxWatchingFileManager(watched: nil)
        fileManager.failSettingAttributes = true

        // When
        XCTAssertThrowsError(
            try ShareInbox.storeAudioFile(from: source, in: self.inboxDirectory, fileManager: fileManager)
        )

        // Then
        XCTAssertEqual(try self.allEntriesIncludingHidden(), ["Vortrag.mp3"])
    }

    // MARK: Helpers

    func makeSourceFile(named name: String, byte: UInt8) throws -> URL {
        let url = self.sourceDirectory.appendingPathComponent(name)
        try Data(repeating: byte, count: 64).write(to: url)
        return url
    }

    func visibleEntries() throws -> [String] {
        try FileManager.default.contentsOfDirectory(
            at: self.inboxDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .map(\.lastPathComponent)
        .sorted()
    }

    func allEntriesIncludingHidden() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: self.inboxDirectory.path).sorted()
    }

    func modificationDate(of url: URL) throws -> Date? {
        try FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }
}

// MARK: - InboxWatchingFileManager

/// Beobachtet, ob ein wartender Inbox-Eintrag entfernt wird, und kann das Setzen des Datums scheitern lassen.
private final class InboxWatchingFileManager: FileManager {
    // MARK: Lifecycle

    init(watched: URL?) {
        self.watchedPath = watched?.standardizedFileURL.path
        super.init()
    }

    // MARK: Internal

    var failSettingAttributes = false
    private(set) var removedWatchedItem = 0

    override func removeItem(at url: URL) throws {
        if url.standardizedFileURL.path == self.watchedPath {
            self.removedWatchedItem += 1
        }
        try super.removeItem(at: url)
    }

    override func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws {
        if self.failSettingAttributes {
            throw CocoaError(.fileWriteNoPermission)
        }
        try super.setAttributes(attributes, ofItemAtPath: path)
    }

    // MARK: Private

    private let watchedPath: String?
}
