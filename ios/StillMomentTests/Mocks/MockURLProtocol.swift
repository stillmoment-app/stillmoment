//
//  MockURLProtocol.swift
//  Still Moment
//

import Foundation

/// URLProtocol subclass that intercepts network requests for testing.
/// Supports both sync and async request handlers.
final class MockURLProtocol: URLProtocol {
    /// Handler that receives the request and returns a response + data, or throws.
    static var requestHandler: ((URLRequest) async throws -> (HTTPURLResponse, Data))?

    /// Pause between delivering the response (headers) and the body — simulates a slow,
    /// long file whose headers arrive long before its content. Reset in `tearDown`.
    static var bodyDelayNanoseconds: UInt64 = 0

    /// Requests to a key URL are answered with `302 Found` (`text/html`) pointing at the value URL;
    /// the session then requests the target, which `requestHandler` serves. Reset in `tearDown`.
    static var redirects: [URL: URL] = [:]

    /// Called right after the response (headers) has been handed to the client, before the body.
    static var onResponseDelivered: (() -> Void)?

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        if self.redirectIfConfigured() {
            return
        }
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        let request = self.request
        let bodyDelay = MockURLProtocol.bodyDelayNanoseconds
        let onResponseDelivered = MockURLProtocol.onResponseDelivered
        self.loadingTask = Task {
            do {
                let (response, data) = try await handler(request)
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                onResponseDelivered?()
                if bodyDelay > 0 {
                    try await Task.sleep(nanoseconds: bodyDelay)
                }
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocolDidFinishLoading(self)
            } catch {
                // After stopLoading the client must not be called anymore.
                guard !Task.isCancelled else {
                    return
                }
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {
        self.loadingTask?.cancel()
    }

    // MARK: Private

    private var loadingTask: Task<Void, Never>?

    /// Answers with a 302 if the request URL has a configured redirect. The loading system then
    /// stops this instance and starts a new one for the target request.
    private func redirectIfConfigured() -> Bool {
        guard let sourceURL = self.request.url,
              let targetURL = MockURLProtocol.redirects[sourceURL],
              let redirectResponse = HTTPURLResponse(
                  url: sourceURL,
                  statusCode: 302,
                  httpVersion: "HTTP/1.1",
                  headerFields: ["Location": targetURL.absoluteString, "Content-Type": "text/html"]
              )
        else {
            return false
        }
        var targetRequest = self.request
        targetRequest.url = targetURL
        self.client?.urlProtocol(self, wasRedirectedTo: targetRequest, redirectResponse: redirectResponse)
        return true
    }
}
