//
//  String+NonBlankTrimmed.swift
//  Still Moment
//
//  Domain Helper - Empty text counts as missing (shared-128)
//

import Foundation

extension String {
    /// The text without whitespace at the edges; `nil` if nothing remains.
    /// Only the edges are cut — e.g. "(20:34 Min.)" inside a title stays.
    var nonBlankTrimmed: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
