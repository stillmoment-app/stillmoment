//
//  ContentGuideViewModelTests.swift
//  Still Moment
//
//  Tests for the Content Guide sheet integration on the library ViewModel.
//

import XCTest
@testable import StillMoment

@MainActor
final class ContentGuideViewModelTests: XCTestCase {
    // MARK: Internal

    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: GuidedMeditationsListViewModel!
    // swiftlint:disable:next implicitly_unwrapped_optional
    var mockMeditationSourceRepository: MockMeditationSourceRepository!

    override func setUp() {
        super.setUp()
        self.mockMeditationSourceRepository = MockMeditationSourceRepository()
        self.sut = GuidedMeditationsListViewModel(
            meditationService: MockGuidedMeditationService(),
            metadataService: MockAudioMetadataService(),
            audioService: MockAudioService(),
            meditationSourceRepository: self.mockMeditationSourceRepository
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockMeditationSourceRepository = nil
        super.tearDown()
    }

    func testOpenGuideSheetLoadsSourcesForRequestedLanguage() {
        // Given
        self.mockMeditationSourceRepository.catalog = [
            "de": [self.makeSource(id: "koeln")],
            "en": [self.makeSource(id: "tara-brach")]
        ]

        // When
        self.sut.openGuideSheet(languageCode: "de")

        // Then
        XCTAssertEqual(self.mockMeditationSourceRepository.lastRequestedLanguage, "de")
        XCTAssertEqual(self.sut.guideSources.map(\.id), ["koeln"])
        XCTAssertTrue(self.sut.showingGuideSheet)
    }

    func testOpenGuideSheetFallsBackToEnglishWhenLanguageMissing() {
        // Given
        self.mockMeditationSourceRepository.catalog = [
            "en": [self.makeSource(id: "fallback")]
        ]

        // When
        self.sut.openGuideSheet(languageCode: "fr")

        // Then
        XCTAssertEqual(self.sut.guideSources.map(\.id), ["fallback"])
        XCTAssertTrue(self.sut.showingGuideSheet)
    }

    func testCloseGuideSheetHidesSheet() {
        // Given
        self.mockMeditationSourceRepository.catalog = ["en": [self.makeSource(id: "x")]]
        self.sut.openGuideSheet(languageCode: "en")
        XCTAssertTrue(self.sut.showingGuideSheet)

        // When
        self.sut.closeGuideSheet()

        // Then
        XCTAssertFalse(self.sut.showingGuideSheet)
    }

    // MARK: Private

    private func makeSource(id: String) -> MeditationSource {
        MeditationSource(
            id: id,
            name: id,
            author: nil,
            description: "desc",
            host: "h",
            // swiftlint:disable:next force_unwrapping
            url: URL(string: "https://example.com/\(id)")!
        )
    }
}
