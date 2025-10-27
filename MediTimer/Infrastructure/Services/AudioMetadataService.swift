//
//  AudioMetadataService.swift
//  MediTimer
//
//  Infrastructure - Audio Metadata Extraction Service
//

import AVFoundation
import Foundation

/// Concrete implementation of AudioMetadataServiceProtocol
///
/// Uses AVFoundation to extract metadata from audio files, including:
/// - ID3 tags (artist, title, album)
/// - Duration
final class AudioMetadataService: AudioMetadataServiceProtocol {
    /// Extracts metadata from an audio file
    ///
    /// - Parameter url: URL to the audio file
    /// - Returns: AudioMetadata with extracted information
    /// - Throws: AudioMetadataError if extraction fails
    func extractMetadata(from url: URL) async throws -> AudioMetadata {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioMetadataError.fileNotAccessible
        }

        let asset = AVAsset(url: url)

        // Extract duration
        let duration: TimeInterval
        do {
            duration = try await asset.load(.duration).seconds
            guard duration.isFinite, duration > 0 else {
                throw AudioMetadataError.durationNotAvailable
            }
        } catch {
            throw AudioMetadataError.durationNotAvailable
        }

        // Extract ID3 tags
        var artist: String?
        var title: String?
        var album: String?

        do {
            let metadata = try await asset.load(.commonMetadata)

            for item in metadata {
                guard let key = item.commonKey?.rawValue,
                      let value = try? await item.load(.stringValue)
                else {
                    continue
                }

                switch key {
                case "artist":
                    artist = value
                case "title":
                    title = value
                case "albumName":
                    album = value
                default:
                    break
                }
            }
        } catch {
            // Metadata not available, continue with nil values
        }

        return AudioMetadata(
            artist: artist,
            title: title,
            duration: duration,
            album: album
        )
    }
}
