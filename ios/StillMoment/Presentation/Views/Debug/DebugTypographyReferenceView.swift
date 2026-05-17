//
//  DebugTypographyReferenceView.swift
//  Still Moment
//
//  Presentation Layer (DEBUG only) - Typography Reference fuer visuelles Tuning.
//
//  Zeigt alle 10 Typografie-Tokens nebeneinander in Light und Dark Mode.
//  Steuerung oben: Dynamic-Type-Stufe (xS → AX5) und Bold-Text-Toggle —
//  damit man die Plan-Acceptance (Schritt 9 + 10) visuell pruefen kann,
//  ohne durch die Settings-App navigieren zu muessen.
//

#if DEBUG
import SwiftUI

struct DebugTypographyReferenceView: View {
    @State private var dynamicTypeStop: DynamicTypeStop = .large
    @State private var legibilityIsBold: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            self.controls
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(TextStyle.allCases, id: \.self) { token in
                        TokenRow(token: token)
                        Divider()
                    }
                }
            }
        }
        .environment(\.dynamicTypeSize, self.dynamicTypeStop.dynamicTypeSize)
        .environment(\.legibilityWeight, self.legibilityIsBold ? .bold : .regular)
        .navigationTitle("Typography Reference")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Dynamic Type")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(self.dynamicTypeStop.label)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.primary)
            }
            Picker("Dynamic Type", selection: self.$dynamicTypeStop) {
                ForEach(DynamicTypeStop.allCases) { stop in
                    Text(stop.shortLabel).tag(stop)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Bold Text", isOn: self.$legibilityIsBold)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tint(.accentColor)
        }
    }
}

// MARK: - Stops fuer den Picker

private enum DynamicTypeStop: String, CaseIterable, Identifiable {
    case xSmall
    case large
    case ax1
    case ax3
    case ax5

    var id: String {
        self.rawValue
    }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .xSmall: .xSmall
        case .large: .large
        case .ax1: .accessibility1
        case .ax3: .accessibility3
        case .ax5: .accessibility5
        }
    }

    var label: String {
        switch self {
        case .xSmall: "xSmall"
        case .large: "Large (Default)"
        case .ax1: "AX1"
        case .ax3: "AX3"
        case .ax5: "AX5"
        }
    }

    var shortLabel: String {
        switch self {
        case .xSmall: "xS"
        case .large: "L"
        case .ax1: "AX1"
        case .ax3: "AX3"
        case .ax5: "AX5"
        }
    }
}

// MARK: - Token-Reihe

private struct TokenRow: View {
    let token: TextStyle

    @Environment(\.legibilityWeight)
    private var legibility

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
        let effective = self.token.effectiveFontName(legibility: self.legibility)
        return "\(self.token.textStyle) · \(Int(self.token.baseSize))pt · \(effective)"
    }
}

// MARK: - Sample-Zelle

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
        // Plan-spezifische Sample-Texte aus der Token-Tabelle.
        switch self.token {
        case .display: "15:00"
        case .title: "Player-Titel"
        case .screenTitle: "Einstellungen"
        case .section: "Erinnerungen"
        case .body: "Stille beobachten."
        case .bodyEmphasis: "Meditation starten"
        case .bodyItalic: "— Anna Maria Berg"
        case .caption: "Sanfter Hintergrund-Sound"
        case .micro: "12:34 · Min"
        case .eyebrow: "Heute · 14. März"
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        DebugTypographyReferenceView()
    }
}
#endif
