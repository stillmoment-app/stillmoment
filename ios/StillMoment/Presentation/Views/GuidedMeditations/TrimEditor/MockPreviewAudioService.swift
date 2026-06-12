//
//  MockPreviewAudioService.swift
//  Still Moment
//
//  Preview-only audio service for the trim editor (shared-107).
//

import Combine
import Foundation

#if DEBUG
/// Preview audio service — no-op playback so the editor previews never touch the audio
/// session. Only the publishers the editor binds to carry meaningful values.
@MainActor
final class MockPreviewAudioService: AudioServiceProtocol {
    var meditationPreviewPositionPublisher: AnyPublisher<TimeInterval, Never> {
        self.positionSubject.eraseToAnyPublisher()
    }

    var meditationPreviewDurationPublisher: AnyPublisher<TimeInterval, Never> {
        Just(0).eraseToAnyPublisher()
    }

    var meditationPreviewCompletionPublisher: AnyPublisher<Void, Never> {
        self.completionSubject.eraseToAnyPublisher()
    }

    var gongCompletionPublisher: AnyPublisher<Void, Never> {
        self.completionSubject.eraseToAnyPublisher()
    }

    func configureAudioSession() throws {}
    func activateTimerSession() throws {}
    func deactivateTimerSession() {}
    func startBackgroundAudio(soundId _: String, volume _: Float) throws {}
    func stopBackgroundAudio() {}
    func playStartGong(soundId _: String, volume _: Float) throws {}
    func playIntervalGong(soundId _: String, volume _: Float) throws {}
    func playCompletionSound(soundId _: String, volume _: Float) throws {}
    func playGongPreview(soundId _: String, volume _: Float) throws {}
    func stopGongPreview() {}
    func playBackgroundPreview(soundId _: String, volume _: Float) throws {}
    func stopBackgroundPreview() {}
    func playMeditationPreview(fileURL _: URL) throws {}
    func stopMeditationPreview() {}
    func seekMeditationPreview(to _: TimeInterval) {}
    func stop() {}

    private let positionSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let completionSubject = PassthroughSubject<Void, Never>()
}
#endif
