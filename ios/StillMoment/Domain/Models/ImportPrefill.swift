//
//  ImportPrefill.swift
//  Still Moment
//
//  Domain-Value: Vorgeschlagene Werte fuer das Edit-Sheet beim Meditation-Import (ios-043).
//
//  Zwei Optionals — nil bedeutet "kein Vorschlag, das Feld bleibt im Edit-Sheet leer".
//  Quelle (ID3 vs. Filename) wird nicht persistiert: der Handoff verzichtet bewusst auf
//  Source-Badges und Banner ("Prefill ist still"), also wird die Information auch nicht
//  in der Domain benoetigt.
//

import Foundation

struct ImportPrefill: Equatable {
    let teacher: String?
    let name: String?

    /// Zentrale Filterung fuer ID3-Werte, Eintraege aus knownTeachers und den preprocessed Filename.
    ///
    /// Schritte:
    /// 1. Whitespace trimmen → wenn leer: nil.
    /// 2. Vergleichs-Kopie bilden (lowercase, alle Trenner entfernt).
    /// 3. Wenn die Vergleichs-Kopie in der Blacklist liegt → nil.
    /// 4. Wenn die Vergleichs-Kopie reine Track-Nummerierung ist → nil.
    /// 5. Sonst: getrimmter Original-Wert (Inhalt unveraendert).
    static func sanitize(_ raw: String?) -> String? {
        guard let raw else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        let comparison = trimmed
            .lowercased()
            .components(separatedBy: self.separators)
            .joined()
        if self.excludedTokens.contains(comparison) {
            return nil
        }
        if Self.isPureTrackNumbering(comparison) {
            return nil
        }
        return trimmed
    }

    /// Saeubert einen Dateinamen fuer die Verwendung in beiden Kaskaden.
    ///
    /// Schritte:
    /// 1. Endung entfernen (`.mp3`, `.m4a`, …).
    /// 2. Track-Nummer-Praefix entfernen (`^\d{1,3}[-_.\s]+`).
    /// 3. Trenner `_`, `-`, `.` zu Spaces; multiple Spaces zusammenfassen.
    /// 4. CamelCase-Wechsel und Zahl/Wort-Uebergaenge mit Space ergaenzen — so wird
    ///    `04Fuesse` zu `04 Fuesse` und `MomentMal` zu `Moment Mal`. Der Wechsel von
    ///    Klein zu Gross deutet auf ein Wort-Trennzeichen hin, das in Filesharing-
    ///    Dateinamen oft an Stelle eines echten Trenners verwendet wird.
    /// 5. Casing innerhalb der Woerter wird **nicht** veraendert — der Inhalt bleibt
    ///    verbatim, damit Deutsch mit Praepositionen wie "im" lesbar bleibt.
    ///
    /// Diakritika-Rueckabbildung (`ue`→`ü`, `oe`→`ö`, `ae`→`ä`, `ss`→`ß`) findet
    /// **bewusst nicht** statt — die Heuristik produziert zu viele false positives
    /// (z. B. `Quelle` → `Quölle`). User korrigiert verbliebene Sonderzeichen manuell.
    static func preprocessFilename(_ raw: String) -> String {
        var working = (raw as NSString).deletingPathExtension
        if let trackMatch = working.range(of: #"^\d{1,3}[-_.\s]+"#, options: .regularExpression) {
            working.removeSubrange(trackMatch)
        }
        let spaced = working
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ".", with: " ")
        let segmented = self.insertWordBoundaries(in: spaced)
        let collapsed = segmented
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Fuegt Spaces an CamelCase- und Zahl/Buchstabe-Uebergaengen ein.
    private static func insertWordBoundaries(in input: String) -> String {
        let characters = Array(input)
        var result = ""
        result.reserveCapacity(characters.count)
        for index in characters.indices {
            let current = characters[index]
            if index > 0 {
                let previous = characters[index - 1]
                let next = index + 1 < characters.count ? characters[index + 1] : nil
                if self.isWordBoundary(previous: previous, current: current, next: next) {
                    result.append(" ")
                }
            }
            result.append(current)
        }
        return result
    }

    private static func isWordBoundary(
        previous: Character,
        current: Character,
        next: Character?
    ) -> Bool {
        // lowercase letter followed by uppercase letter: "MomentMal" → "Moment Mal"
        if previous.isLetter, previous.isLowercase, current.isUppercase {
            return true
        }
        // Acronym followed by a capitalized word: "MBSRBodyscan" → "MBSR Bodyscan"
        // (previous uppercase, current uppercase, next lowercase).
        if previous.isLetter, previous.isUppercase,
           current.isLetter, current.isUppercase,
           let next, next.isLetter, next.isLowercase {
            return true
        }
        // digit ↔ letter: "04Fuesse" → "04 Fuesse"
        if previous.isNumber, current.isLetter {
            return true
        }
        if previous.isLetter, current.isNumber {
            return true
        }
        return false
    }

    /// Berechnet Prefill-Vorschlaege fuer `teacher` und `name` aus ID3-Metadaten und Dateiname.
    ///
    /// `knownTeachers` ist die deduplizierte Liste der bereits in der Library vorhandenen Lehrer
    /// (siehe ViewModel-Aggregation). Alte `"Unknown Artist"`-Eintraege werden durch `sanitize`
    /// vor dem Match aussortiert, sodass der Filename-Match-Pfad sie nicht zurueckholt.
    static func compute(
        metadata: AudioMetadata,
        fileName: String,
        knownTeachers: [String]
    ) -> ImportPrefill {
        let basename = (fileName as NSString).deletingPathExtension
        let preprocessed = self.preprocessFilename(fileName)
        let teacher = self.computeTeacher(
            artist: metadata.artist,
            preprocessedFilename: preprocessed,
            knownTeachers: knownTeachers
        )
        let name = self.computeName(
            title: metadata.title,
            basename: basename,
            preprocessedFilename: preprocessed,
            teacher: teacher
        )
        return ImportPrefill(teacher: teacher, name: name)
    }

    private static func computeName(
        title: String?,
        basename: String,
        preprocessedFilename: String,
        teacher: String?
    ) -> String? {
        if let sanitizedTitle = self.sanitize(title) {
            return sanitizedTitle
        }
        if self.isGarbageFilename(basename) || self.isGarbageFilename(preprocessedFilename) {
            return nil
        }
        if let teacher,
           let stripped = self.removeTeacherSubstring(from: preprocessedFilename, teacher: teacher),
           let candidate = self.sanitize(stripped),
           candidate.count >= 3 {
            return candidate
        }
        if let candidate = self.sanitize(preprocessedFilename), candidate.count >= 3 {
            return candidate
        }
        return nil
    }

    private static func removeTeacherSubstring(from filename: String, teacher: String) -> String? {
        let needle = teacher.lowercased()
        guard let range = filename.range(of: needle, options: .caseInsensitive) else {
            return nil
        }
        var working = filename
        working.removeSubrange(range)
        let collapsed = working.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func computeTeacher(
        artist: String?,
        preprocessedFilename: String,
        knownTeachers: [String]
    ) -> String? {
        if let sanitizedArtist = self.sanitize(artist) {
            return sanitizedArtist
        }
        let sanitizedKnown = knownTeachers
            .compactMap { self.sanitize($0) }
            .filter { Self.isEligibleTeacherForFilenameMatch($0) }
            .sorted { $0.count > $1.count }
        let needle = preprocessedFilename.lowercased()
        for candidate in sanitizedKnown where needle.contains(candidate.lowercased()) {
            return candidate
        }
        return nil
    }

    private static func isEligibleTeacherForFilenameMatch(_ name: String) -> Bool {
        let words = name.split { $0.isWhitespace }.count
        return words >= 2 || name.count >= 6
    }

    /// Erkennt unbrauchbare Filenames (UUID-Pattern, langes Token ohne Trenner, leer).
    ///
    /// Platzhalter wie `audio`, `voicememo` werden bereits durch `sanitize` ausgesiebt —
    /// diese Stelle deckt nur das ab, was sanitize nicht greift.
    static func isGarbageFilename(_ candidate: String) -> Bool {
        if candidate.isEmpty {
            return true
        }
        if candidate.range(of: self.uuidPattern, options: [.regularExpression, .caseInsensitive]) != nil {
            return true
        }
        if candidate.count >= 24, !candidate.contains(where: self.isFilenameSeparator) {
            return true
        }
        return false
    }

    // MARK: - Internal helpers

    private static let uuidPattern = #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#

    private static func isFilenameSeparator(_ character: Character) -> Bool {
        character == "_" || character == "-" || character == "." || character == " " || character == "/"
    }

    private static let separators = CharacterSet(charactersIn: "_-. /")

    private static let excludedTokens: Set<String> = [
        "unknown",
        "unknownartist",
        "untitled",
        "audio",
        "recording",
        "voicememo",
        "voicerecording"
    ]

    private static func isPureTrackNumbering(_ comparison: String) -> Bool {
        let stripped = comparison.hasPrefix("track") ? String(comparison.dropFirst(5)) : comparison
        guard !stripped.isEmpty, stripped.count <= 3 else {
            return false
        }
        return stripped.allSatisfy(\.isASCII) && stripped.allSatisfy(\.isNumber)
    }
}
