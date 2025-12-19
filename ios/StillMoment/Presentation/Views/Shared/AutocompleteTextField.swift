//
//  AutocompleteTextField.swift
//  Still Moment
//
//  Presentation Layer - Reusable Autocomplete TextField Component
//

import SwiftUI

/// A TextField with autocomplete suggestions dropdown
///
/// Features:
/// - Shows filtered suggestions as user types
/// - Case-insensitive contains matching
/// - Tap to select fills the text field
/// - Dismisses on outside tap or selection
/// - Warm earth tone design matching app theme
struct AutocompleteTextField: View {
    // MARK: Lifecycle

    init(
        text: Binding<String>,
        placeholder: LocalizedStringKey,
        suggestions: [String],
        accessibilityLabel: LocalizedStringKey,
        accessibilityIdentifier: String? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.suggestions = suggestions
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    // MARK: Internal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(self.placeholder, text: self.$text)
                .focused(self.$isFocused)
                .accessibilityLabel(self.accessibilityLabel)
                .accessibilityIdentifier(self.accessibilityIdentifier ?? "")
                .onChange(of: self.text) { newValue in
                    let filtered = Self.filterSuggestions(self.suggestions, for: newValue)
                    self.showSuggestions = !filtered.isEmpty
                }
                .onChange(of: self.isFocused) { focused in
                    if !focused {
                        // Delay to allow tap on suggestion to register
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            self.showSuggestions = false
                        }
                    }
                }

            if self.showSuggestions {
                self.suggestionsList
            }
        }
    }

    /// Filters suggestions based on input text
    ///
    /// - Parameters:
    ///   - suggestions: All available suggestions
    ///   - text: Current input text
    /// - Returns: Filtered suggestions (max 5), excluding exact matches
    static func filterSuggestions(_ suggestions: [String], for text: String) -> [String] {
        guard !text.isEmpty else {
            return []
        }

        return Array(suggestions.filter { suggestion in
            suggestion.localizedCaseInsensitiveContains(text) &&
                suggestion.localizedCaseInsensitiveCompare(text) != .orderedSame
        }
        .prefix(5))
    }

    // MARK: Private

    @Binding private var text: String
    @State private var showSuggestions = false
    @FocusState private var isFocused: Bool

    private let placeholder: LocalizedStringKey
    private let suggestions: [String]
    private let accessibilityLabel: LocalizedStringKey
    private let accessibilityIdentifier: String?

    private var filteredSuggestions: [String] {
        Self.filterSuggestions(self.suggestions, for: self.text)
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(self.filteredSuggestions, id: \.self) { suggestion in
                Button {
                    self.text = suggestion
                    self.showSuggestions = false
                    self.isFocused = false
                } label: {
                    HStack {
                        Text(suggestion)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(
                    format: NSLocalizedString("autocomplete.suggestion", comment: ""),
                    suggestion
                ))
                .accessibilityHint(NSLocalizedString("autocomplete.suggestion.hint", comment: ""))

                if suggestion != self.filteredSuggestions.last {
                    Divider()
                        .background(Color.textSecondary.opacity(.opacityTertiary))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundSecondary)
                .shadow(color: Color.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.top, 4)
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("With Suggestions") {
    @Previewable @State var text = "Al"

    Form {
        Section("Teacher") {
            AutocompleteTextField(
                text: $text,
                placeholder: "Enter teacher name",
                suggestions: ["Alice", "Albert", "Bob", "Charlie"],
                accessibilityLabel: "Teacher name"
            )
        }
    }
}

@available(iOS 17.0, *)
#Preview("Empty") {
    @Previewable @State var text = ""

    Form {
        Section("Teacher") {
            AutocompleteTextField(
                text: $text,
                placeholder: "Enter teacher name",
                suggestions: ["Alice", "Albert", "Bob"],
                accessibilityLabel: "Teacher name"
            )
        }
    }
}
