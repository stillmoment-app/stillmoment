//
//  GuidedMeditationSettingsView.swift
//  Still Moment
//
//  Presentation Layer - Settings View for Guided Meditations
//

import SwiftUI

/// Settings view for configuring guided meditation options
///
/// Uses local @State to avoid SwiftUI binding propagation issues with Picker.
/// The onSave callback receives the final settings when user confirms.
struct GuidedMeditationSettingsView: View {
    // MARK: Lifecycle

    init(settings: GuidedMeditationSettings, onSave: @escaping (GuidedMeditationSettings) -> Void) {
        _localSettings = State(initialValue: settings)
        _preparationTimeEnabled = State(initialValue: settings.preparationTimeSeconds != nil)
        _preparationTimeSeconds = State(
            initialValue: settings.preparationTimeSeconds ?? GuidedMeditationSettings.initialPreparationTimeSeconds
        )
        self.onSave = onSave
    }

    // MARK: Internal

    var body: some View {
        NavigationView {
            ZStack {
                self.theme.backgroundGradient
                    .ignoresSafeArea()

                Form {
                    Section {
                        Toggle(isOn: self.$preparationTimeEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("guided_meditations.settings.preparationTime.title", bundle: .main)
                                    .settingsLabelStyle()
                                Text("guided_meditations.settings.preparationTime.description", bundle: .main)
                                    .settingsDescriptionStyle()
                            }
                        }
                        .accessibilityIdentifier("guidedMeditation.toggle.preparationTime")
                        .listRowBackground(self.theme.backgroundPrimary)
                        .onChange(of: self.preparationTimeEnabled) { newValue in
                            if newValue {
                                self.localSettings = self.localSettings.withPreparationTime(
                                    self.preparationTimeSeconds
                                )
                            } else {
                                self.localSettings = self.localSettings.withPreparationTime(nil)
                            }
                        }

                        if self.preparationTimeEnabled {
                            Picker(
                                NSLocalizedString("guided_meditations.settings.preparationTime.duration", comment: ""),
                                selection: self.$preparationTimeSeconds
                            ) {
                                ForEach(GuidedMeditationSettings.validPreparationTimeValues, id: \.self) { seconds in
                                    Text("\(seconds)s").tag(seconds)
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("guidedMeditation.picker.preparationTimeSeconds")
                            .listRowBackground(self.theme.backgroundPrimary)
                            .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))
                            .onChange(of: self.preparationTimeSeconds) { newValue in
                                self.localSettings = self.localSettings.withPreparationTime(newValue)
                            }
                        }
                    } header: {
                        Text("guided_meditations.settings.preparationTime.header", bundle: .main)
                    }

                    GeneralSettingsSection()
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(NSLocalizedString("guided_meditations.settings.title", comment: ""))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("button.done", comment: "")) {
                            self.onSave(self.localSettings)
                        }
                        .tint(self.theme.interactive)
                        .accessibilityIdentifier("button.done")
                    }
                }
            }
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    /// Local copy of settings for editing - avoids SwiftUI binding issues
    @State private var localSettings: GuidedMeditationSettings

    /// Local state for toggle - synced to localSettings via onChange
    @State private var preparationTimeEnabled: Bool

    /// Local state for picker - synced to localSettings via onChange
    @State private var preparationTimeSeconds: Int

    /// Callback when user confirms settings
    private let onSave: (GuidedMeditationSettings) -> Void
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Disabled") {
    GuidedMeditationSettingsView(
        settings: GuidedMeditationSettings(preparationTimeSeconds: nil)
    ) { _ in }
}

@available(iOS 17.0, *)
#Preview("Enabled 15s") {
    GuidedMeditationSettingsView(
        settings: GuidedMeditationSettings(preparationTimeSeconds: 15)
    ) { _ in }
}
