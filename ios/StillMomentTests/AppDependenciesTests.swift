//
//  AppDependenciesTests.swift
//  Still Moment
//
//  ios-055: Composition Root — what the app-wide dependency graph guarantees.
//

import XCTest
@testable import StillMoment

@MainActor
final class AppDependenciesTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var storage: TestStorage!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // The live graph gets its own storage, never the app's real data (ios-056)
        self.storage = try TestStorage()
    }

    override func tearDown() {
        self.storage.remove()
        self.storage = nil
        super.tearDown()
    }

    func testEachPlayerGetsItsOwnPlaybackService() {
        // Given — the app's dependency graph
        let dependencies = AppDependencies.live(storage: self.storage.location)

        // When — two players are opened one after the other
        let first = dependencies.makeAudioPlayerService()
        let second = dependencies.makeAudioPlayerService()

        // Then — playback state of one player never leaks into the next
        XCTAssertFalse(first as AnyObject === second as AnyObject)
    }

    func testEachPlayerGetsItsOwnEndGongPlayer() {
        // Given
        let dependencies = AppDependencies.live(storage: self.storage.location)

        // When
        let first = dependencies.makeGongPlayer()
        let second = dependencies.makeGongPlayer()

        // Then — a gong still ringing in a closed player cannot be stopped by the next one
        XCTAssertFalse(first as AnyObject === second as AnyObject)
    }

    func testLiveGraphUsesProductionImplementations() {
        // Given
        let dependencies = AppDependencies.live(storage: self.storage.location)

        // Then — the app runs on the real services, not on preview or test doubles
        XCTAssertTrue(dependencies.audioService is AudioService)
        XCTAssertTrue(dependencies.waveformProvider is WaveformProvider)
        XCTAssertTrue(dependencies.meditationService is GuidedMeditationService)
    }

    func testTimerAndPlayerShareOneAudioSessionCoordinator() throws {
        // Given — the app's dependency graph
        let dependencies = AppDependencies.live(storage: self.storage.location)

        // When — the timer's audio and an opened player are taken from it
        let timerAudio = try XCTUnwrap(dependencies.audioService as? AudioService)
        let player = try XCTUnwrap(dependencies.makeAudioPlayerService() as? AudioPlayerService)

        // Then — both hand the one audio session back and forth through the app's single
        // coordinator, so gongs and keep-alive keep working on the lock screen (ios-058)
        XCTAssertTrue(timerAudio.coordinator === player.coordinator)
        XCTAssertTrue(timerAudio.coordinator === AudioSessionCoordinator.shared)
    }

    // MARK: - Shared instances where the app wires its screens (Plan AK-1/2)

    func testTimerAndLibraryPlayThroughTheSameAudioService() {
        // Given — the app's wiring on one set of doubles
        let mocked = MockedAppDependencies()
        let dependencies = mocked.dependencies
        let timer = dependencies.makeTimerViewModel()
        let library = dependencies.makeGuidedListViewModel()

        // When — the timer previews a gong and the library previews a meditation
        timer.playGongPreview(soundId: GongSound.defaultSoundId, volume: 0.5)
        library.startPreview(for: Self.meditation)

        // Then — both went through the one AudioService (one conflict handler, one keep-alive)
        XCTAssertTrue(mocked.audioService.playGongPreviewCalled)
        XCTAssertTrue(mocked.audioService.playMeditationPreviewCalled)
    }

    func testLibraryAndPlayerShareTheWaveformProvider() async {
        // Given
        let mocked = MockedAppDependencies()
        let dependencies = mocked.dependencies
        let library = dependencies.makeGuidedListViewModel()
        let player = dependencies.makePlayerViewModel(meditation: Self.meditation, preparationTimeSeconds: nil)

        // When — the library drops a cached waveform and the player loads one
        library.deleteMeditation(Self.meditation)
        await player.loadWaveform()

        // Then — both used the same provider, so in-flight generation is de-duplicated app-wide
        XCTAssertEqual(mocked.waveformProvider.removedCachedIds, [Self.meditation.id])
        XCTAssertEqual(mocked.waveformProvider.waveformCallCount, 1)
    }

    func testLibraryAndPlayerReadTheSameLibrary() async {
        // Given — the library holds one meditation
        let mocked = MockedAppDependencies()
        mocked.meditationService.meditations = [Self.meditation]
        let dependencies = mocked.dependencies
        let library = dependencies.makeGuidedListViewModel()
        let player = dependencies.makePlayerViewModel(meditation: Self.meditation, preparationTimeSeconds: nil)

        // When — the library loads and the player opens the meditation
        await library.loadMeditations()
        await player.loadAudio()

        // Then — the library lists it, and the player resolved its audio file through the same service
        XCTAssertEqual(library.meditations.map(\.id), [Self.meditation.id])
        XCTAssertEqual(mocked.meditationService.fileURLRequests, [Self.meditation.id])
    }

    func testFileImportRecognizesMeditationsAlreadyInTheLibrary() async throws {
        // Given — the library already holds "ios055.mp3" (stored file not resolvable,
        // so the duplicate check matches by file name alone)
        let mocked = MockedAppDependencies()
        mocked.meditationService.meditations = [Self.meditation]
        mocked.meditationService.mockFileExists = false
        let handler = mocked.dependencies.makeFileOpenHandler()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ios055-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent(Self.meditation.fileName)
        FileManager.default.createFile(atPath: file.path, contents: Data([0x1]))

        // When — the same file is opened via "Open with"
        let result = await handler.importFile(from: file)

        // Then — the duplicate check saw the library's meditations, i.e. the same service
        guard case .failure(.alreadyImported) = result else {
            return XCTFail("Expected the import to be recognized as already imported, got \(result)")
        }
    }

    private static let meditation = GuidedMeditation(
        localFilePath: "ios055.mp3",
        fileName: "ios055.mp3",
        duration: 600,
        teacher: "Teacher",
        name: "Meditation"
    )
}
