//
//  SettingsView.swift
//  Still Moment
//
//  Presentation Layer - Settings View
//

import SwiftUI

/// Settings view for configuring meditation session options
struct SettingsView: View {
    // MARK: Lifecycle

    init(
        settings: Binding<MeditationSettings>,
        onDismiss: @escaping () -> Void,
        soundRepository: BackgroundSoundRepositoryProtocol = BackgroundSoundRepository()
    ) {
        _settings = settings
        self.onDismiss = onDismiss
        self.soundRepository = soundRepository
        self.availableSounds = soundRepository.availableSounds
    }

    // MARK: Internal

    var body: some View {
        NavigationView {
            ZStack {
                // Warm gradient background (consistent with Timer tab)
                Color.warmGradient
                    .ignoresSafeArea()

                Form {
                    Section {
                        Picker(
                            NSLocalizedString("settings.backgroundAudio.title", comment: ""),
                            selection: self.$settings.backgroundSoundId
                        ) {
                            ForEach(self.availableSounds) { sound in
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sound.name.localized)
                                            .font(.system(size: 17, weight: .regular, design: .rounded))
                                        Text(sound.description.localized)
                                            .font(.system(size: 13, weight: .regular, design: .rounded))
                                            .foregroundColor(.textSecondary)
                                    }
                                } icon: {
                                    Image(systemName: sound.iconName)
                                        .foregroundColor(.interactive)
                                }
                                .tag(sound.id)
                                .accessibilityLabel("\(sound.name.localized). \(sound.description.localized)")
                                .accessibilityHint(
                                    NSLocalizedString(
                                        "settings.backgroundAudio.hint",
                                        value: "Select background sound for meditation",
                                        comment: "Accessibility hint for sound selection"
                                    )
                                )
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel(
                            NSLocalizedString("settings.backgroundAudio.title", comment: "")
                        )
                    } header: {
                        Text("settings.backgroundAudio.title", bundle: .main)
                    } footer: {
                        if let currentSound = self.availableSounds
                            .first(where: { $0.id == self.settings.backgroundSoundId }) {
                            Text(currentSound.description.localized)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                        }
                    }

                    Section {
                        Toggle(isOn: self.$settings.intervalGongsEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("settings.intervalGongs.title", bundle: .main)
                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                Text("settings.intervalGongs.description", bundle: .main)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .accessibilityLabel("accessibility.intervalGongs")
                        .accessibilityHint("accessibility.intervalGongs.hint")

                        if self.settings.intervalGongsEnabled {
                            Picker(
                                NSLocalizedString("settings.intervalGongs.interval", comment: ""),
                                selection: self.$settings.intervalMinutes
                            ) {
                                Text("settings.interval.3min", bundle: .main).tag(3)
                                Text("settings.interval.5min", bundle: .main).tag(5)
                                Text("settings.interval.10min", bundle: .main).tag(10)
                            }
                            .pickerStyle(.menu)
                            .accessibilityLabel("accessibility.intervalDuration")
                            .accessibilityHint("accessibility.intervalDuration.hint")
                        }
                    } header: {
                        Text("settings.soundSettings.title", bundle: .main)
                    } footer: {
                        if self.settings.intervalGongsEnabled {
                            Text(String(
                                format: NSLocalizedString("settings.intervalGongs.footer", comment: ""),
                                self.settings.intervalMinutes
                            ))
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(NSLocalizedString("settings.title", comment: ""))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(NSLocalizedString("button.done", comment: "")) {
                            self.onDismiss()
                        }
                        .tint(.interactive)
                        .accessibilityIdentifier("button.done")
                        .accessibilityLabel("accessibility.done")
                        .accessibilityHint("accessibility.done.hint")
                    }
                }
            }
        }
    }

    // MARK: Private

    @Binding private var settings: MeditationSettings

    private let onDismiss: () -> Void
    private let soundRepository: BackgroundSoundRepositoryProtocol
    private let availableSounds: [BackgroundSound]
}

// MARK: - Previews

private let defaultSettings = MeditationSettings(
    intervalGongsEnabled: false,
    intervalMinutes: 5,
    backgroundSoundId: "silent"
)

private let forestSettings = MeditationSettings(
    intervalGongsEnabled: true,
    intervalMinutes: 5,
    backgroundSoundId: "forest"
)

#Preview("Default Settings") {
    SettingsView(settings: .constant(defaultSettings)) {}
}

#Preview("Forest + Intervals") {
    SettingsView(settings: .constant(forestSettings)) {}
}

// Device Size Previews
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    SettingsView(settings: .constant(forestSettings)) {}
}

#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    SettingsView(settings: .constant(forestSettings)) {}
}

#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    SettingsView(settings: .constant(forestSettings)) {}
}
