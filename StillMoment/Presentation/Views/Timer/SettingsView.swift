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

    init(settings: Binding<MeditationSettings>, onDismiss: @escaping () -> Void) {
        _settings = settings
        self.onDismiss = onDismiss
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
                            selection: self.$settings.backgroundAudioMode
                        ) {
                            ForEach(BackgroundAudioMode.allCases, id: \.self) { mode in
                                Text(
                                    mode == .silent ? NSLocalizedString(
                                        "settings.backgroundAudio.silent",
                                        comment: ""
                                    ) :
                                        NSLocalizedString(
                                            "settings.backgroundAudio.whiteNoise",
                                            comment: ""
                                        )
                                ).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("accessibility.backgroundAudioMode")
                        .accessibilityHint("accessibility.backgroundAudioMode.hint")
                    } header: {
                        Text("settings.backgroundAudio.title", bundle: .main)
                    } footer: {
                        switch self.settings.backgroundAudioMode {
                        case .silent:
                            Text("settings.backgroundAudio.footer.silent", bundle: .main)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                        case .whiteNoise:
                            Text("settings.backgroundAudio.footer.whiteNoise", bundle: .main)
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
                                    .foregroundColor(.warmGray)
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
                        .tint(.terracotta)
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
}

// MARK: - Previews

#Preview("Default Settings") {
    SettingsView(
        settings: .constant(MeditationSettings(
            intervalGongsEnabled: false,
            intervalMinutes: 5,
            backgroundAudioMode: .silent
        ))
    ) {}
}

#Preview("White Noise + Intervals") {
    SettingsView(
        settings: .constant(MeditationSettings(
            intervalGongsEnabled: true,
            intervalMinutes: 5,
            backgroundAudioMode: .whiteNoise
        ))
    ) {}
}
