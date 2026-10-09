//
//  URLReference.swift
//  Still Moment
//
//  Domain - Inbox entry for a shared link.
//  Member of the app target and the Share Extension target.
//

import Foundation

/// JSON format of a shared link in the Share Extension inbox.
/// Written by the Share Extension via `ShareInbox.storeLink`, read by `InboxHandler`.
struct URLReference: Codable {
    let url: String
    let filename: String
    let timestamp: String
}
