//
//  LibrarySearchEngine.swift
//  Still Moment
//
//  Domain Service - Pure Search-Engine fuer die Library-Suche
//

import Foundation

/// Pure Such-Funktionen fuer die Volltext-Suche in der Library.
///
/// - Multi-Token-Split (Whitespace), UND-Verknuepfung.
/// - Case- und diakritika-insensitiver Substring-Match.
/// - Ranking nach 4 Buckets:
///   1. Wortanfang im Titel
///   2. Wortanfang im Lehrer
///   3. Substring im Titel
///   4. Substring im Lehrer
/// - Bei mehreren Tokens gewinnt der beste Bucket (best-match-wins).
/// - Tiebreaker: neueres `dateAdded` zuerst.
enum LibrarySearchEngine {
    /// Zerlegt die Eingabe in Tokens (Whitespace-getrennt).
    static func tokens(from query: String) -> [String] {
        query
            .split { $0.isWhitespace }
            .map(String.init)
    }

    /// Liefert alle Vorkommen jedes Tokens im Text als Ranges. Mehrfach-Matches inklusive.
    ///
    /// - Wird zum Highlighten in der UI verwendet.
    /// - Case- und diakritika-insensitiv.
    /// - Ueberlappende Ranges werden zusammengefasst.
    static func highlightRanges(in text: String, query: String) -> [Range<String.Index>] {
        let queryTokens = self.tokens(from: query)
        guard !queryTokens.isEmpty else {
            return []
        }

        var collected: [Range<String.Index>] = []
        for token in queryTokens {
            collected.append(contentsOf: self.ranges(of: token, in: text))
        }
        return self.mergeOverlapping(collected, in: text)
    }

    /// Filtert und sortiert Meditationen nach Relevanz.
    static func search(meditations: [GuidedMeditation], query: String) -> [GuidedMeditation] {
        let queryTokens = self.tokens(from: query)
        guard !queryTokens.isEmpty else {
            return []
        }

        let ranked: [(meditation: GuidedMeditation, bucket: MatchBucket)] = meditations.compactMap { med in
            var tokenBuckets: [MatchBucket] = []
            for token in queryTokens {
                guard let bucket = self.bestBucket(for: token, in: med) else {
                    return nil
                }
                tokenBuckets.append(bucket)
            }
            // best-match-wins: bester (kleinster) Bucket ueber alle Tokens
            guard let bestForMeditation = tokenBuckets.min() else {
                return nil
            }
            return (med, bestForMeditation)
        }

        return ranked
            .sorted { lhs, rhs in
                if lhs.bucket != rhs.bucket {
                    return lhs.bucket < rhs.bucket
                }
                return lhs.meditation.dateAdded > rhs.meditation.dateAdded
            }
            .map(\.meditation)
    }

    // MARK: - Private

    /// Bucket des besten Treffers fuer ein einzelnes Token in einer Meditation.
    private static func bestBucket(for token: String, in meditation: GuidedMeditation) -> MatchBucket? {
        let title = meditation.effectiveName
        let teacher = meditation.effectiveTeacher

        if self.hasWordStartMatch(of: token, in: title) {
            return .wordStartInTitle
        }
        if self.hasWordStartMatch(of: token, in: teacher) {
            return .wordStartInTeacher
        }
        if self.hasSubstring(token, in: title) {
            return .substringInTitle
        }
        if self.hasSubstring(token, in: teacher) {
            return .substringInTeacher
        }
        return nil
    }

    private static func hasSubstring(_ token: String, in text: String) -> Bool {
        text.range(of: token, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    private static func hasWordStartMatch(of token: String, in text: String) -> Bool {
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(
            of: token,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: searchRange
        ) {
            if self.isWordStart(at: range.lowerBound, in: text) {
                return true
            }
            searchRange = range.upperBound..<text.endIndex
        }
        return false
    }

    private static func isWordStart(at index: String.Index, in text: String) -> Bool {
        if index == text.startIndex {
            return true
        }
        let previous = text[text.index(before: index)]
        return previous.isWhitespace || previous.isPunctuation || previous.isSymbol
    }

    private static func ranges(of substring: String, in text: String) -> [Range<String.Index>] {
        guard !substring.isEmpty else {
            return []
        }
        var result: [Range<String.Index>] = []
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(
            of: substring,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: searchRange
        ) {
            result.append(range)
            // Verhindert Endlosschleife wenn substring leer waere; substring ist hier garantiert nicht-leer.
            searchRange = range.upperBound..<text.endIndex
        }
        return result
    }

    /// Fasst ueberlappende oder beruehrende Ranges zusammen.
    private static func mergeOverlapping(
        _ ranges: [Range<String.Index>],
        in text: String
    ) -> [Range<String.Index>] {
        guard !ranges.isEmpty else {
            return []
        }
        let sorted = ranges.sorted { $0.lowerBound < $1.lowerBound }
        var merged: [Range<String.Index>] = [sorted[0]]
        for range in sorted.dropFirst() {
            // swiftlint:disable:next force_unwrapping
            let last = merged.last!
            if range.lowerBound <= last.upperBound {
                let upper = range.upperBound > last.upperBound ? range.upperBound : last.upperBound
                merged[merged.count - 1] = last.lowerBound..<upper
            } else {
                merged.append(range)
            }
        }
        return merged
    }

    private enum MatchBucket: Int, Comparable {
        case wordStartInTitle = 0
        case wordStartInTeacher = 1
        case substringInTitle = 2
        case substringInTeacher = 3

        static func < (lhs: MatchBucket, rhs: MatchBucket) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
