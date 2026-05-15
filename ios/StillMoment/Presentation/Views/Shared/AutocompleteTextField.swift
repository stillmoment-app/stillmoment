//
//  AutocompleteTextField.swift
//  Still Moment
//
//  Presentation Layer - Reusable Autocomplete TextField Component
//

import SwiftUI

/// A TextField with autocomplete suggestions dropdown.
///
/// Features (ios-044):
/// - Filters suggestions case-insensitively as the user types.
/// - Match substring inside each suggestion is accent-highlighted (consistent with library search).
/// - Inline clear (X) button — appears while focused with non-empty text.
/// - Dropdown stays closed on empty input (no suggestions for an empty query — consistent with
///   the library search behavior).
/// - Parent owns focus via `FocusState<Bool>.Binding`, enabling multi-field navigation.
struct AutocompleteTextField: View {
    // MARK: Lifecycle

    init(
        text: Binding<String>,
        focus: FocusState<Bool>.Binding,
        placeholder: LocalizedStringKey,
        suggestions: [String],
        accessibilityLabel: LocalizedStringKey,
        accessibilityIdentifier: String? = nil,
        submitLabel: SubmitLabel = .return,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.focus = focus
        self.placeholder = placeholder
        self.suggestions = suggestions
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    // MARK: Internal

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ClearableTextField(
                self.placeholder,
                text: self.$text,
                focus: self.focus,
                accessibilityLabel: self.accessibilityLabel,
                accessibilityIdentifier: self.accessibilityIdentifier,
                submitLabel: self.submitLabel,
                onSubmit: self.onSubmit
            )
            .onChange(of: self.text) { newValue in
                let filtered = Self.filterSuggestions(self.suggestions, for: newValue)
                self.showSuggestions = !filtered.isEmpty
            }
            .onChange(of: self.focus.wrappedValue) { focused in
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

    @Environment(\.themeColors)
    private var theme
    @Binding private var text: String
    @State private var showSuggestions = false
    private let focus: FocusState<Bool>.Binding

    private let placeholder: LocalizedStringKey
    private let suggestions: [String]
    private let accessibilityLabel: LocalizedStringKey
    private let accessibilityIdentifier: String?
    private let submitLabel: SubmitLabel
    private let onSubmit: (() -> Void)?

    private var filteredSuggestions: [String] {
        Self.filterSuggestions(self.suggestions, for: self.text)
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Subtle top separator detaches the dropdown from the input without a box.
            Rectangle()
                .fill(self.theme.textSecondary.opacity(0.18))
                .frame(height: 0.5)

            ForEach(Array(self.filteredSuggestions.enumerated()), id: \.element) { index, suggestion in
                Button {
                    self.text = suggestion
                    self.showSuggestions = false
                    self.focus.wrappedValue = false
                } label: {
                    HStack {
                        HighlightedText(text: suggestion, query: self.text)
                            .themeFont(.bodyPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(
                    format: NSLocalizedString("autocomplete.suggestion", comment: ""),
                    suggestion
                ))
                .accessibilityHint(NSLocalizedString("autocomplete.suggestion.hint", comment: ""))

                if index < self.filteredSuggestions.count - 1 {
                    Rectangle()
                        .fill(self.theme.textSecondary.opacity(0.12))
                        .frame(height: 0.5)
                }
            }
        }
        .padding(.top, 6)
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("With Suggestions") {
    AutocompletePreviewWrapper(initialText: "Al")
}

@available(iOS 17.0, *)
#Preview("Empty") {
    AutocompletePreviewWrapper(initialText: "")
}

@available(iOS 17.0, *)
private struct AutocompletePreviewWrapper: View {
    let initialText: String
    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        Form {
            Section("Teacher") {
                AutocompleteTextField(
                    text: self.$text,
                    focus: self.$focused,
                    placeholder: "Enter teacher name",
                    suggestions: ["Alice", "Albert", "Bob", "Charlie"],
                    accessibilityLabel: "Teacher name"
                )
            }
        }
        .onAppear { self.text = self.initialText }
    }
}
