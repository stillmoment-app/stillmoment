//
//  DebugTypographyReferenceView.swift
//  Still Moment
//
//  Presentation Layer (DEBUG only) - Typography Reference fuer visuelles Tuning.
//
//  Zeigt alle 10 Typografie-Tokens nebeneinander in Light und Dark Mode auf einer
//  Seite. Hilft beim Tuning ohne durch die App zu navigieren.
//  Schritt 10 der Typografie-2.1-Migration erweitert diesen Screen um einen Slider
//  fuer Dynamic-Type-Groessen — diese Variante ist die minimale Brueckenversion.
//

#if DEBUG
import SwiftUI

struct DebugTypographyReferenceView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(TextStyle.allCases, id: \.self) { token in
                    TokenRow(token: token)
                    Divider()
                }
            }
        }
        .navigationTitle("Typography Reference")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TokenRow: View {
    let token: TextStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(self.tokenName)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text(self.specDescription)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            HStack(spacing: 0) {
                SampleCell(token: self.token, palette: .light)
                SampleCell(token: self.token, palette: .dark)
            }
        }
    }

    private var tokenName: String {
        ".\(self.token)"
    }

    private var specDescription: String {
        "\(Int(self.token.baseSize))pt · \(self.token.fontName)"
    }
}

private struct SampleCell: View {
    let token: TextStyle
    let palette: ThemeColors

    var body: some View {
        Text(self.sampleText)
            .textStyle(self.token)
            .foregroundColor(self.palette.textPrimary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(self.palette.backgroundPrimary)
    }

    private var sampleText: String {
        "Aa Bb 0123"
    }
}

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        DebugTypographyReferenceView()
    }
}
#endif
