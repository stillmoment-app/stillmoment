//
//  Logger+StillMoment.swift
//  Still Moment
//
//  Infrastructure - Logging Framework
//

import Foundation
import OSLog

/// Centralized logging system for Still Moment using OSLog
/// Provides categorized loggers for different subsystems
extension Logger {
    // MARK: Internal

    // MARK: - Domain Loggers

    /// Logger for timer-related operations
    static let timer = Logger(subsystem: subsystem, category: "timer")

    /// Logger for audio playback operations
    static let audio = Logger(subsystem: subsystem, category: "audio")

    /// Logger for notification operations
    static let notifications = Logger(subsystem: subsystem, category: "notifications")

    /// Logger for guided meditation operations
    static let guidedMeditation = Logger(subsystem: subsystem, category: "guidedMeditation")

    /// Logger for audio player operations
    static let audioPlayer = Logger(subsystem: subsystem, category: "audioPlayer")

    // MARK: - Application Loggers

    /// Logger for ViewModel operations
    static let viewModel = Logger(subsystem: subsystem, category: "viewmodel")

    /// Logger for app lifecycle events
    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")

    // MARK: - Infrastructure Loggers

    /// Logger for general infrastructure operations
    static let infrastructure = Logger(subsystem: subsystem, category: "infrastructure")

    /// Logger for error tracking
    static let error = Logger(subsystem: subsystem, category: "error")

    /// Logger for performance monitoring
    static let performance = Logger(subsystem: subsystem, category: "performance")

    // MARK: Private

    /// Subsystem identifier for all Still Moment logs
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.stillmoment"
}

// MARK: - Logging Helpers

extension Logger {
    /// Logs a debug message with optional metadata
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata dictionary
    func debug(_ message: String, metadata: [String: Any]? = nil) {
        if let metadata {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            self.log(level: .debug, "\(message) [\(metadataString)]")
        } else {
            self.log(level: .debug, "\(message)")
        }
    }

    /// Logs an info message with optional metadata
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata dictionary
    func info(_ message: String, metadata: [String: Any]? = nil) {
        if let metadata {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            self.log(level: .info, "\(message) [\(metadataString)]")
        } else {
            self.log(level: .info, "\(message)")
        }
    }

    /// Logs a warning message with optional metadata
    /// - Parameters:
    ///   - message: The message to log
    ///   - metadata: Optional metadata dictionary
    func warning(_ message: String, metadata: [String: Any]? = nil) {
        if let metadata {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            self.log(level: .default, "\(message) [\(metadataString)]")
        } else {
            self.log(level: .default, "\(message)")
        }
    }

    /// Logs an error with optional error object and metadata
    /// - Parameters:
    ///   - message: The error message
    ///   - error: Optional error object
    ///   - metadata: Optional metadata dictionary
    func error(_ message: String, error: Error? = nil, metadata: [String: Any]? = nil) {
        var components: [String] = [message]

        if let error {
            components.append("error=\(error.localizedDescription)")
        }

        if let metadata {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            components.append("[\(metadataString)]")
        }

        self.log(level: .error, "\(components.joined(separator: " "))")
    }

    /// Logs a critical error that requires immediate attention
    /// - Parameters:
    ///   - message: The critical error message
    ///   - error: Optional error object
    ///   - metadata: Optional metadata dictionary
    func critical(_ message: String, error: Error? = nil, metadata: [String: Any]? = nil) {
        var components: [String] = ["CRITICAL:", message]

        if let error {
            components.append("error=\(error.localizedDescription)")
        }

        if let metadata {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            components.append("[\(metadataString)]")
        }

        self.log(level: .fault, "\(components.joined(separator: " "))")
    }
}

// MARK: - Performance Monitoring

extension Logger {
    /// Measures and logs the execution time of a code block
    /// - Parameters:
    ///   - operation: Description of the operation being measured
    ///   - block: The code block to measure
    /// - Returns: The result of the code block
    func measure<T>(
        operation: String,
        block: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            self.debug("⏱️ \(operation) completed", metadata: ["duration": String(format: "%.3fs", duration)])
        }
        return try block()
    }

    /// Measures and logs the execution time of an async code block
    /// - Parameters:
    ///   - operation: Description of the operation being measured
    ///   - block: The async code block to measure
    /// - Returns: The result of the code block
    func measure<T>(
        operation: String,
        block: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            self.debug("⏱️ \(operation) completed", metadata: ["duration": String(format: "%.3fs", duration)])
        }
        return try await block()
    }
}

// MARK: - Usage Examples

/*
 Example usage in different layers:

 // Timer Service
 Logger.timer.info("Starting timer", metadata: ["duration": 10])
 Logger.timer.debug("Timer tick", metadata: ["remaining": 595])
 Logger.timer.error("Timer start failed", error: someError)

 // Audio Service
 Logger.audio.info("Playing completion sound")
 Logger.audio.warning("Audio session not configured")
 Logger.audio.error("Failed to play sound", error: audioError)

 // ViewModel
 Logger.viewModel.info("Timer started", metadata: ["minutes": selectedMinutes])
 Logger.viewModel.debug("State updated", metadata: ["state": "running"])

 // Performance monitoring
 let result = Logger.performance.measure(operation: "Loading audio file") {
     try loadAudioFile()
 }
 */
