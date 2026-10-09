//
//  FeedbackLinks.swift
//  Still Moment
//
//  Domain Model - Addresses for "Rate the App" and "Write to Us" (shared-134)
//

import Foundation

/// Addresses behind the feedback rows in the settings' info section.
///
/// The app never asks for a review on its own — "Rate the App" opens the App Store page,
/// "Write to Us" opens a prepared mail in the person's default mail app.
enum FeedbackLinks {
    // MARK: Internal

    /// Address that receives messages from "Write to Us".
    static let contactAddress = "hello@stillmoment.app"

    /// App Store page of Still Moment, opened directly at "write a review".
    static let rateAppURL = URL(string: "https://apps.apple.com/app/id\(Self.appStoreId)?action=write-review")

    /// A new mail to `contactAddress` with subject "Still Moment".
    ///
    /// The body starts with two empty lines (room to write), followed by app version, build
    /// and iOS version — visible before sending and deletable by the person.
    /// Line breaks are CRLF and everything is percent-encoded (spaces as `%20`, never `+`),
    /// as RFC 6068 requires for `mailto` URLs.
    static func writeToUsURL(appVersion: String, build: String, osVersion: String) -> URL? {
        let versionLine = "Still Moment \(appVersion) (\(build)) · iOS \(osVersion)"
        let body = "\r\n\r\n" + versionLine

        guard let encodedSubject = Self.percentEncoded(Self.mailSubject),
              let encodedBody = Self.percentEncoded(body)
        else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.contactAddress
        components.percentEncodedQueryItems = [
            URLQueryItem(name: "subject", value: encodedSubject),
            URLQueryItem(name: "body", value: encodedBody)
        ]
        return components.url
    }

    // MARK: Private

    private static let appStoreId = "6755774465"

    /// Brand name, intentionally not localized.
    private static let mailSubject = "Still Moment"

    /// Unreserved characters only, so `+`, `&` and `=` in values cannot break the query.
    private static let allowedValueCharacters: CharacterSet = {
        var allowed = CharacterSet.alphanumerics.intersection(.urlQueryAllowed)
        allowed.insert(charactersIn: "-._~")
        return allowed
    }()

    private static func percentEncoded(_ value: String) -> String? {
        value.addingPercentEncoding(withAllowedCharacters: self.allowedValueCharacters)
    }
}
