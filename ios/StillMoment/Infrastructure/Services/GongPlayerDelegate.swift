//
//  GongPlayerDelegate.swift
//  Still Moment
//
//  Infrastructure - AVAudioPlayer Delegates for AudioService
//

import AVFoundation

// MARK: - GongPlayerDelegate

/// AVAudioPlayerDelegate that notifies when a gong finishes playing.
/// Used to transition the timer state machine after the start gong completes.
/// Fires onFinish when playback ends, also when it ends abnormally (successfully: false).
/// It does NOT fire on an audio session interruption: AVAudioPlayer only pauses then.
/// Callers that must never get stuck observe interruptions themselves
/// (see `MeditationGongPlayer`).
class GongPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        self.onFinish()
    }
}
