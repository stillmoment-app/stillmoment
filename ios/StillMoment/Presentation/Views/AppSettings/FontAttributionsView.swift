//
//  FontAttributionsView.swift
//  Still Moment
//
//  Presentation Layer - Font attribution and license screen (shared-136)
//

import SwiftUI

/// Screen naming the bundled fonts and showing their license.
///
/// Newsreader and Geist are licensed under the SIL Open Font License 1.1, which
/// requires the license text to ship with the app and be readable (OFL §2).
/// The license is read from the bundled `OFL.txt` and shown unchanged, in English.
struct FontAttributionsView: View {
    @Environment(\.themeColors)
    private var theme

    @State private var licenseText = FontLicense.loadText()

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            Form {
                self.fontsSection
                self.licenseSection
            }
            .scrollContentBackground(.hidden)
            .screenTitleBar("app.settings.fontAttributions.page.title")
        }
    }

    // MARK: - Sections

    private var fontsSection: some View {
        Section {
            // Font and author names are proper names and stay untranslated.
            self.fontRow(name: "Newsreader", author: "Production Type")
            self.fontRow(name: "Geist", author: "Vercel")
        } header: {
            Text("app.settings.fontAttributions.fonts.header", bundle: .main)
                .textStyle(.section, color: \.textSecondary)
                .textCase(nil)
        }
    }

    private var licenseSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                Text("app.settings.fontAttributions.license.intro", bundle: .main)
                    .textStyle(.body, color: \.textPrimary)
                if let licenseText = self.licenseText {
                    Text(verbatim: licenseText)
                        .textStyle(.caption, color: \.textPrimary)
                        .accessibilityIdentifier("app.settings.fontAttributions.licenseText")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardRowBackground()
        } header: {
            Text("app.settings.fontAttributions.license.header", bundle: .main)
                .textStyle(.section, color: \.textSecondary)
                .textCase(nil)
        }
    }

    // MARK: - Row Helper

    private func fontRow(name: String, author: String) -> some View {
        HStack {
            // The font name wins the width at large Dynamic Type sizes; the author wraps instead.
            Text(verbatim: name)
                .textStyle(.body, color: \.textPrimary)
                .layoutPriority(1)
            Spacer()
            Text(verbatim: author)
                .textStyle(.body, color: \.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .cardRowBackground()
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        FontAttributionsView()
    }
}
