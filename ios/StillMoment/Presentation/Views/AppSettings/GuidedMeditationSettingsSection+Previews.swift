//
//  GuidedMeditationSettingsSection+Previews.swift
//  Still Moment
//
//  SwiftUI previews for GuidedMeditationSettingsSection (DEBUG only; built on preview doubles /
//  AppDependencies.live()).
//

#if DEBUG
import SwiftUI

@available(iOS 17.0, *)
#Preview("Preparation Disabled") {
    NavigationStack {
        Form {
            GuidedMeditationSettingsSection(settingsRepository: AppDependencies.live().guidedSettingsRepository)
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
                    let repo = AppDependencies.live().guidedSettingsRepository
                    repo.save(GuidedMeditationSettings(preparationTimeSeconds: 15))
                    return repo
                }()
            )
        }
        .scrollContentBackground(.hidden)
    }
}
#endif
