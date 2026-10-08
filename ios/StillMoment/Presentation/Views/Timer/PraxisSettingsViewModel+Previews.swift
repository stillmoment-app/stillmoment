//
//  PraxisSettingsViewModel+Previews.swift
//  Still Moment
//
//  Presentation - SwiftUI preview support for the timer setting screens (built on AppDependencies).
//

#if DEBUG
extension PraxisSettingsViewModel {
    /// Creates a view model for the default Praxis on the app's real services for SwiftUI previews.
    @MainActor
    static func preview() -> PraxisSettingsViewModel {
        let dependencies = AppDependencies.live()
        return PraxisSettingsViewModel(
            praxis: .default,
            repository: dependencies.praxisRepository,
            audioService: dependencies.audioService,
            soundRepository: dependencies.backgroundSoundRepository,
            customAudioRepository: dependencies.customAudioRepository
        ) { _ in }
    }
}
#endif
