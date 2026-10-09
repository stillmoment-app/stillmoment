//
//  FontLicense.swift
//  Still Moment
//
//  Presentation Layer - Reads the SIL Open Font License shipped with the bundled fonts
//

import Foundation
import OSLog

/// The license text of the bundled fonts (Newsreader, Geist), read from `OFL.txt`.
///
/// OFL §2 requires the license to ship with the software; the font attributions page shows it.
/// The text is read from the file next to the fonts, never copied into code, so a font update
/// that changes the file is reflected automatically.
enum FontLicense {
    /// Loads the license text, or returns `nil` (and logs) if the file is missing or unreadable.
    static func loadText(from bundle: Bundle = .main) -> String? {
        guard let url = bundle.url(forResource: "OFL", withExtension: "txt") else {
            Logger.infrastructure.error("Font license file OFL.txt not found in bundle")
            return nil
        }
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            Logger.infrastructure.error("Failed to read font license file", error: error)
            return nil
        }
    }
}
