//
//  MeditationFileInfoLine.swift
//  Still Moment
//
//  Presentation Layer - File info below the edit sheet's info section (shared-139)
//

import SwiftUI

/// What the file info in the edit sheet shows: the file name and the full file length.
///
/// The file info always names the full file length, also for a trimmed meditation
/// (glossary: `formattedFileDuration`); list and player show the effective duration.
struct MeditationFileInfo: Equatable {
    // MARK: Lifecycle

    init(meditation: GuidedMeditation) {
        self.fileName = meditation.fileName
        self.duration = meditation.formattedFileDuration
    }

    // MARK: Internal

    let fileName: String
    let duration: String

    /// Read by VoiceOver as one element — always the untruncated file name plus duration.
    var accessibilityLabel: String {
        "\(self.fileName), \(self.duration)"
    }
}

/// File info: icon, file name, duration.
///
/// The duration is never truncated. The file name is truncated in the middle, so its
/// beginning and the file extension stay readable.
///
/// Standard text sizes: one line, the duration sits directly behind the file name.
/// Accessibility text sizes: the file name gets up to three lines and the duration goes
/// below it — on one line the name would shrink to a few characters ("20…mp3"). With
/// several lines SwiftUI places the middle ellipsis in the last line, so the first lines
/// show the beginning and the last line ends with the extension. This is an iOS-only
/// adaptation: Android's largest font scale (2.0) stays readable on one line.
struct MeditationFileInfoLine: View {
    let info: MeditationFileInfo

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "doc")
                .font(.system(size: 11))
                .foregroundColor(self.theme.textSecondary)
            if self.dynamicTypeSize.isAccessibilitySize {
                self.stackedContent
            } else {
                self.singleLineContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: self.info.accessibilityLabel))
        .accessibilityIdentifier("editSheet.fileInfo")
    }

    // MARK: Private

    private static let separator = "  ·  "
    private static let accessibilityNameLineLimit = 3

    @Environment(\.themeColors)
    private var theme
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    /// Standard sizes: name and duration on one line.
    private var singleLineContent: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(verbatim: self.info.fileName)
                .textStyle(.caption, color: \.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(verbatim: Self.separator + self.info.duration)
                .textStyle(.caption, color: \.textSecondary)
                .lineLimit(1)
                .fixedSize()
                .layoutPriority(1)
        }
    }

    /// Accessibility sizes: name on its own lines, duration below it.
    private var stackedContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: self.info.fileName)
                .textStyle(.caption, color: \.textSecondary)
                .lineLimit(Self.accessibilityNameLineLimit)
                .truncationMode(.middle)
            Text(verbatim: self.info.duration)
                .textStyle(.caption, color: \.textSecondary)
                .lineLimit(1)
                .fixedSize()
        }
    }
}
