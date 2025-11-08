//
//  AudioMetadataService.swift
//  Still Moment
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
    // MARK: Internal

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
        let duration = try await extractDuration(from: asset)
        let tags = await extractID3Tags(from: asset)

        return AudioMetadata(
            artist: tags.artist,
            title: tags.title,
            duration: duration,
            album: tags.album
        )
    }

    // MARK: Private

    // MARK: - Private Types

    /// Container for ID3 tag metadata
    private struct ID3Tags {
        let artist: String?
        let title: String?
        let album: String?
    }

    /// Extracts duration from an AVAsset
    private func extractDuration(from asset: AVAsset) async throws -> TimeInterval {
        do {
            let duration = try await asset.load(.duration).seconds
            guard duration.isFinite, duration > 0 else {
                throw AudioMetadataError.durationNotAvailable
            }
            return duration
        } catch {
            throw AudioMetadataError.durationNotAvailable
        }
    }

    /// Extracts ID3 tags (artist, title, album) from an AVAsset
    private func extractID3Tags(from asset: AVAsset) async -> ID3Tags {
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

        return ID3Tags(artist: artist, title: title, album: album)
    }
}
