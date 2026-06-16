//
//  AudioFrameReader.swift
//  Still Moment
//
//  Infrastructure - Seam over AVAudioFile for chunk-wise decoding
//

import AVFoundation

/// The slice of `AVAudioFile` the waveform decoder relies on.
///
/// Extracting it as a protocol lets tests inject a reader that throws a read error
/// mid-stream — the real-world case where `AVAudioFile.length` counts MP3 encoder
/// padding the decoder cannot actually reach, so the final `read` fails. `AVAudioFile`
/// already exposes every member, so it conforms without any extra code.
protocol AudioFrameReader: AnyObject {
    var processingFormat: AVAudioFormat { get }
    var length: AVAudioFramePosition { get }
    var framePosition: AVAudioFramePosition { get }
    func read(into buffer: AVAudioPCMBuffer, frameCount frames: AVAudioFrameCount) throws
}

extension AVAudioFile: AudioFrameReader {}
