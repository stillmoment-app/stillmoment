//
//  GongPlayerDelegate.swift
//  Still Moment
//
//  Infrastructure - AVAudioPlayer Delegates for AudioService
//

import AVFoundation

// MARK: - GongPlayerDelegate

/// AVAudioPlayerDelegate that notifies when a gong finishes playing.
/// Used to sequence introduction audio after the start gong completes.
/// Always fires onFinish — even on interruption (successfully: false) — to prevent
/// the state machine from getting stuck in `.startGong`.
class GongPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        self.onFinish()
    }
}
