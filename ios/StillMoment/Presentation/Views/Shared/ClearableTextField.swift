//
//  ClearableTextField.swift
//  Still Moment
//
//  Presentation Layer - Text field with a clear (X) button overlay (ios-044).
//

import SwiftUI

/// A SwiftUI `TextField` with a trailing clear (X) button.
///
/// The clear button follows the iOS-native `.whileEditing` rule: it appears only
/// while the field is focused **and** contains text, and clears the field on tap.
///
/// The parent owns focus via a `@FocusState` binding so it can coordinate
/// multi-field navigation (e.g. Return moves focus to the next field).
struct ClearableTextField: View {
    // MARK: Lifecycle

    init(
        _ placeholder: LocalizedStringKey,
        text: Binding<String>,
        focus: FocusState<Bool>.Binding,
        accessibilityLabel: LocalizedStringKey,
        accessibilityIdentifier: String? = nil,
        submitLabel: SubmitLabel = .return,
        lineLimit: ClosedRange<Int>? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.focus = focus
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.submitLabel = submitLabel
        self.lineLimit = lineLimit
        self.onSubmit = onSubmit
    }

    // MARK: Internal

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            self.textField
                .focused(self.focus)
                .submitLabel(self.submitLabel)
                .onSubmit {
                    self.onSubmit?()
                }
                .accessibilityLabel(self.accessibilityLabel)
                .accessibilityIdentifier(self.accessibilityIdentifier ?? "")

            if self.shouldShowClearButton {
                self.clearButton
                    .padding(.top, 2) // visually aligns with first text line when wrapped
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: self.shouldShowClearButton)
    }

    @ViewBuilder private var textField: some View {
        if let lineLimit {
            TextField(self.placeholder, text: self.$text, axis: .vertical)
                .lineLimit(lineLimit)
        } else {
            TextField(self.placeholder, text: self.$text)
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @Binding private var text: String
    private let focus: FocusState<Bool>.Binding

    private let placeholder: LocalizedStringKey
    private let accessibilityLabel: LocalizedStringKey
    private let accessibilityIdentifier: String?
    private let submitLabel: SubmitLabel
    private let lineLimit: ClosedRange<Int>?
    private let onSubmit: (() -> Void)?

    private var shouldShowClearButton: Bool {
        self.focus.wrappedValue && !self.text.isEmpty
    }

    private var clearButton: some View {
        Button {
            self.text = ""
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(self.theme.textSecondary.opacity(0.6))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("accessibility.clearButton.label")
        .accessibilityIdentifier("clearableTextField.button.clear")
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("With Text") {
    PreviewWrapper(initialText: "Tara Brach")
}

@available(iOS 17.0, *)
#Preview("Empty") {
    PreviewWrapper(initialText: "")
}

@available(iOS 17.0, *)
private struct PreviewWrapper: View {
    let initialText: String
    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        Form {
            Section("Teacher") {
                ClearableTextField(
                    "guided_meditations.edit.teacherPlaceholder",
                    text: self.$text,
                    focus: self.$focused,
                    accessibilityLabel: "guided_meditations.edit.teacher"
                )
            }
        }
        .onAppear { self.text = self.initialText }
    }
}
