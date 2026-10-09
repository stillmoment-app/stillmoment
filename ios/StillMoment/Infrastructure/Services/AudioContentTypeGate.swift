//
//  AudioContentTypeGate.swift
//  Still Moment
//
//  Infrastructure - Rejects a download by its file type as soon as the server's answer arrives (shared-131)
//

import Foundation
import OSLog

/// Per-download task delegate that checks the server-reported file type before the file is loaded.
///
/// The async `URLSession.download(for:delegate:)` does not deliver response or progress callbacks,
/// but it does deliver `urlSession(_:didCreateTask:)`. The gate uses it to observe the task's
/// `response` (all task properties support KVO): once a successful (2xx) answer with a type that
/// `AudioContentType` does not accept arrives, the task is cancelled. The caller then reports
/// `unsupportedContentType` instead of a user cancel (see `isRejected`).
///
/// Only the raw `Content-Type` header is judged — never `URLResponse.mimeType`, which guesses
/// a type when the header is missing or empty.
final class AudioContentTypeGate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    // MARK: Internal

    /// Whether the gate cancelled the download because of its file type.
    var isRejected: Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.rejected
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        // Called before the task starts, so the response is still missing — `.new` suffices.
        let observation = task.observe(\.response, options: [.new]) { [weak self] task, _ in
            self?.judge(task)
        }
        self.lock.lock()
        self.observation = observation
        self.lock.unlock()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.stopObserving()
    }

    deinit {
        self.observation?.invalidate()
    }

    // MARK: Private

    private let lock = NSLock()
    private var rejected = false
    private var observation: NSKeyValueObservation?

    /// Called on an arbitrary thread whenever the task's response changes.
    private func judge(_ task: URLSessionTask) {
        guard let response = task.response as? HTTPURLResponse,
              (200...299).contains(response.statusCode)
        else {
            // No answer yet, or an error/redirect answer — the status check after loading decides.
            return
        }
        let contentType = response.value(forHTTPHeaderField: "Content-Type")
        guard !AudioContentType.isAccepted(contentType) else {
            self.stopObserving()
            return
        }
        self.lock.lock()
        let alreadyRejected = self.rejected
        self.rejected = true
        self.lock.unlock()
        guard !alreadyRejected else {
            return
        }
        Logger.infrastructure.info("Rejecting download, unsupported content type: \(contentType ?? "")")
        self.stopObserving()
        task.cancel()
    }

    private func stopObserving() {
        self.lock.lock()
        let observation = self.observation
        self.observation = nil
        self.lock.unlock()
        observation?.invalidate()
    }
}
