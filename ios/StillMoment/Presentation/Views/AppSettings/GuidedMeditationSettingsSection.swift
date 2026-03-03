//
//  GuidedMeditationSettingsSection.swift
//  Still Moment
//
//  Presentation Layer - Guided Meditation Settings Section for App Settings Tab
//

import SwiftUI

/// Settings section for guided meditation preparation time.
///
/// Used in the app settings tab to configure preparation time before
/// a guided meditation begins. Loads and saves settings directly via
/// the repository.
struct GuidedMeditationSettingsSection: View {
    // MARK: Lifecycle

    init(settingsRepository: GuidedSettingsRepository = GuidedMeditationSettingsRepository()) {
        self.settingsRepository = settingsRepository
        let settings = settingsRepository.load()
        _preparationTimeEnabled = State(initialValue: settings.preparationTimeSeconds != nil)
        _preparationTimeSeconds = State(
            initialValue: settings.preparationTimeSeconds ?? GuidedMeditationSettings.initialPreparationTimeSeconds
        )
    }

    // MARK: Internal

    var body: some View {
        Section {
            Toggle(isOn: self.$preparationTimeEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("guided_meditations.settings.preparationTime.title", bundle: .main)
                        .themeFont(.settingsLabel)
                    Text("guided_meditations.settings.preparationTime.description", bundle: .main)
                        .themeFont(.settingsDescription)
                }
            }
            .themedToggle()
            .accessibilityIdentifier("guidedMeditation.toggle.preparationTime")
            .cardRowBackground()
            .onChange(of: self.preparationTimeEnabled) { newValue in
                self.saveSettings(enabled: newValue, seconds: self.preparationTimeSeconds)
            }

            if self.preparationTimeEnabled {
                Picker(selection: self.$preparationTimeSeconds) {
                    ForEach(GuidedMeditationSettings.validPreparationTimeValues, id: \.self) { seconds in
                        Text("\(seconds)s").tag(seconds)
                    }
                } label: {
                    Text("guided_meditations.settings.preparationTime.duration", bundle: .main)
                        .themeFont(.settingsLabel)
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("guidedMeditation.picker.preparationTimeSeconds")
                .cardRowBackground()
                .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 16))
                .onChange(of: self.preparationTimeSeconds) { newValue in
                    HapticFeedback.selection()
                    self.saveSettings(enabled: true, seconds: newValue)
                }
            }
        } header: {
            Text("app.settings.guidedMeditations.header", bundle: .main)
                .foregroundColor(self.theme.textSecondary)
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    @State private var preparationTimeEnabled: Bool
    @State private var preparationTimeSeconds: Int

    private let settingsRepository: GuidedSettingsRepository

    private func saveSettings(enabled: Bool, seconds: Int) {
        let settings = GuidedMeditationSettings(
            preparationTimeSeconds: enabled ? seconds : nil
        )
        self.settingsRepository.save(settings)
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Preparation Disabled") {
    NavigationStack {
        Form {
            GuidedMeditationSettingsSection()
        }
        .scrollContentBackground(.hidden)
    }
}

@available(iOS 17.0, *)
#Preview("Preparation Enabled") {
    NavigationStack {
        Form {
            GuidedMeditationSettingsSection(
                settingsRepository: {
                    let repo = GuidedMeditationSettingsRepository()
                    repo.save(GuidedMeditationSettings(preparationTimeSeconds: 15))
                    return repo
                }()
            )
        }
        .scrollContentBackground(.hidden)
    }
}
