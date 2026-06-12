//
//  WaveformProviderTests.swift
//  Still Moment
//

import XCTest
@testable import StillMoment

@MainActor
final class WaveformProviderTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        self.generator = MockWaveformGenerationService()
        self.cache = MockWaveformCacheService()
        self.meditation = GuidedMeditation(
            localFilePath: "file.mp3",
            fileName: "file.mp3",
            duration: 600,
            teacher: "Teacher",
            name: "Name"
        )
        let meditationService = MockGuidedMeditationService()
        meditationService.mockFileExists = true
        self.sut = WaveformProvider(
            generationService: self.generator,
            cacheService: self.cache,
            meditationService: meditationService
        )
    }

    override func tearDown() {
        self.sut = nil
        self.generator = nil
        self.cache = nil
        self.meditation = nil
        super.tearDown()
    }

    func testCacheHitReturnsCachedWithoutGenerating() async throws {
        // Given
        let cached = MeditationWaveform(samples: [Float](repeating: 0.3, count: MeditationWaveform.sampleCount))
        self.cache.storage[self.meditation.id] = cached

        // When
        let result = try await self.sut.waveform(for: self.meditation)

        // Then
        XCTAssertEqual(result, cached)
        XCTAssertEqual(self.generator.generateCallCount, 0)
    }

    func testStaleResolutionCacheEntryIsRegenerated() async throws {
        // Given: a cached waveform from an older build with a lower resolution
        let stale = MeditationWaveform(samples: [Float](repeating: 0.3, count: 220))
        self.cache.storage[self.meditation.id] = stale
        let generated = MeditationWaveform(
            samples: [Float](repeating: 0.7, count: MeditationWaveform.sampleCount)
        )
        self.generator.fixedWaveform = generated

        // When
        let result = try await self.sut.waveform(for: self.meditation)

        // Then: the stale entry is ignored, the waveform regenerated and re-cached
        XCTAssertEqual(result, generated)
        XCTAssertEqual(self.generator.generateCallCount, 1)
        XCTAssertEqual(self.cache.storage[self.meditation.id], generated)
    }

    func testCacheMissGeneratesSavesAndReturns() async throws {
        // Given
        let generated = MeditationWaveform(samples: [Float](repeating: 0.7, count: MeditationWaveform.sampleCount))
        self.generator.fixedWaveform = generated

        // When
        let result = try await self.sut.waveform(for: self.meditation)

        // Then
        XCTAssertEqual(result, generated)
        XCTAssertEqual(self.generator.generateCallCount, 1)
        XCTAssertEqual(self.cache.storage[self.meditation.id], generated)
    }

    func testConcurrentRequestsForSameMeditationGenerateOnce() async throws {
        // Given a generation that is held until both callers are inside the provider
        self.generator.gateGeneration()

        // When two concurrent requests run for the same meditation
        async let first = self.sut.waveform(for: self.meditation)
        async let second = self.sut.waveform(for: self.meditation)

        // Give both tasks a chance to enter the provider and reach the gate
        try await Task.sleep(nanoseconds: 50_000_000)
        self.generator.openGate()

        _ = try await first
        _ = try await second

        // Then the underlying generator ran exactly once (shared in-flight task)
        XCTAssertEqual(self.generator.generateCallCount, 1)
    }

    func testAfterSuccessSubsequentRequestIsServedFromCacheWithoutSecondGeneration() async throws {
        // Given a generated waveform on the first (cache-miss) request
        let generated = MeditationWaveform(samples: [Float](repeating: 0.6, count: MeditationWaveform.sampleCount))
        self.generator.fixedWaveform = generated

        // When the first request completes
        let first = try await self.sut.waveform(for: self.meditation)
        XCTAssertEqual(first, generated)
        XCTAssertEqual(self.generator.generateCallCount, 1)

        // Then a subsequent request is served from the cache (in-flight entry was cleared
        // only after generateAndCache, so no duplicate decode can slip in)
        let second = try await self.sut.waveform(for: self.meditation)

        XCTAssertEqual(second, generated)
        XCTAssertEqual(self.generator.generateCallCount, 1)
    }

    func testGenerationErrorPropagates() async {
        // Given
        self.generator.generateShouldThrow = true

        // When / Then
        do {
            _ = try await self.sut.waveform(for: self.meditation)
            XCTFail("Expected generation error to propagate")
        } catch {
            XCTAssertTrue(error is WaveformGenerationError)
        }
    }

    func testCacheSaveErrorStillReturnsWaveform() async throws {
        // Given a generator that succeeds but a cache that fails to save
        let generated = MeditationWaveform(samples: [Float](repeating: 0.4, count: MeditationWaveform.sampleCount))
        self.generator.fixedWaveform = generated
        self.cache.saveShouldThrow = true

        // When
        let result = try await self.sut.waveform(for: self.meditation)

        // Then the generated waveform is returned despite the save failure
        XCTAssertEqual(result, generated)
        XCTAssertEqual(self.generator.generateCallCount, 1)
    }

    func testRemoveCachedDelegatesToCache() {
        // When
        self.sut.removeCached(id: self.meditation.id)

        // Then
        XCTAssertEqual(self.cache.deleteCallCount, 1)
    }

    // MARK: Private

    // swiftlint:disable implicitly_unwrapped_optional
    private var sut: WaveformProvider!
    private var generator: MockWaveformGenerationService!
    private var cache: MockWaveformCacheService!
    private var meditation: GuidedMeditation!
    // swiftlint:enable implicitly_unwrapped_optional
}
