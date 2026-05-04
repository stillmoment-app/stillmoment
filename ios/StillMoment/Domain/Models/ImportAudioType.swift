//
//  ImportAudioType.swift
//  Still Moment
//
//  Domain - Import type selection when sharing audio files with the app
//

import Foundation

/// The type of audio content a shared file should be imported as.
///
/// Presented to the user in a selection sheet when sharing an audio file
/// with the app. Each type routes the file to a different storage location
/// and navigation destination.
enum ImportAudioType: Equatable {
    /// A guided meditation — stored in the meditation library
    case guidedMeditation
    /// A background sound loop — stored as custom soundscape
    case soundscape

    /// Maps to CustomAudioType for soundscape imports.
    /// Returns nil for guided meditations (different import path).
    var customAudioType: CustomAudioType? {
        switch self {
        case .guidedMeditation: nil
        case .soundscape: .soundscape
        }
    }
}
