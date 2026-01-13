//
//  GuidedMeditationSettingsView.swift
//  Still Moment
//
//  Presentation Layer - Settings View for Guided Meditations
//

import SwiftUI

/// Settings view for configuring guided meditation options
struct GuidedMeditationSettingsView: View {
    // MARK: Lifecycle

    init(settings: Binding<GuidedMeditationSettings>, onDismiss: @escaping () -> Void) {
        _settings = settings
        self.onDismiss = onDismiss
    }

    // MARK: Internal

    var body: some View {
        NavigationView {
            ZStack {
                Color.warmGradient
                    .ignoresSafeArea()

                Form {
                    Section {
                        Toggle(isOn: self.preparationTimeEnabledBinding) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("guided_meditations.settings.preparationTime.title", bundle: .main)
                                    .settingsLabelStyle()
                                Text("guided_meditations.settings.preparationTime.description", bundle: .main)
                                    .settingsDescriptionStyle()
                            }
                        }
                        .accessibilityIdentifier("guidedMeditation.toggle.preparationTime")
                        .listRowBackground(Color.backgroundPrimary)

                        if self.settings.preparationTimeSeconds != nil {
                            Picker(
                                NSLocalizedString("guided_meditations.settings.preparationTime.duration", comment: ""),
                                selection: self.preparationTimeSecondsBinding
                            ) {
                                ForEach(GuidedMeditationSettings.validPreparationTimeValues, id: \.self) { seconds in
                                    Text("\(seconds)s").tag(seconds)
                                }
                            }
                            .pickerStyle(.menu)
                            .accessibilityIdentifier("guidedMeditation.picker.preparationTimeSeconds")
                            .listRowBackground(Color.backgroundPrimary)
                            .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))
                        }
                    } header: {
                        Text("guided_meditations.settings.preparationTime.header", bundle: .main)
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(NSLocalizedString("guided_meditations.settings.title", comment: ""))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("button.done", comment: "")) {
                            self.onDismiss()
                        }
                        .tint(.interactive)
                        .accessibilityIdentifier("button.done")
                    }
                }
            }
        }
    }

    // MARK: Private

    @Binding private var settings: GuidedMeditationSettings
    private let onDismiss: () -> Void

    /// Binding for the preparation time toggle (enabled/disabled)
    private var preparationTimeEnabledBinding: Binding<Bool> {
        Binding(
            get: { self.settings.preparationTimeSeconds != nil },
            set: { enabled in
                if enabled {
                    self.settings = self.settings.withPreparationTime(
                        GuidedMeditationSettings.initialPreparationTimeSeconds
                    )
                } else {
                    // Disable
                    self.settings = self.settings.withPreparationTime(nil)
                }
            }
        )
    }

    /// Binding for the preparation time seconds picker
    private var preparationTimeSecondsBinding: Binding<Int> {
        Binding(
            get: { self.settings.preparationTimeSeconds ?? GuidedMeditationSettings.initialPreparationTimeSeconds },
            set: { seconds in
                self.settings = self.settings.withPreparationTime(seconds)
            }
        )
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Disabled") {
    GuidedMeditationSettingsView(
        settings: .constant(GuidedMeditationSettings(preparationTimeSeconds: nil))
    ) {}
}

@available(iOS 17.0, *)
#Preview("Enabled 15s") {
    GuidedMeditationSettingsView(
        settings: .constant(GuidedMeditationSettings(preparationTimeSeconds: 15))
    ) {}
}
