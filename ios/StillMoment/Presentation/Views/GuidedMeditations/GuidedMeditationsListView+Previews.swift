//
//  GuidedMeditationsListView+Previews.swift
//  Still Moment
//
//  SwiftUI-Previews fuer die Library-Liste (Empty + diverse Geraetegroessen).
//

#if DEBUG
import SwiftUI

/// Builds the library the way `StillMomentApp` does, but on preview doubles for the
/// library contents and audio. Preview files are exempt from the composition-root lint.
@MainActor
private func previewLibrary(meditations: [GuidedMeditation]) -> some View {
    let dependencies = AppDependencies.live()
    let service = PreviewMeditationService(meditations: meditations)
    let viewModel = GuidedMeditationsListViewModel(
        meditationService: service,
        metadataService: dependencies.metadataService,
        audioService: MockPreviewAudioService(),
        meditationSourceRepository: dependencies.meditationSourceRepository,
        searchHistoryStore: dependencies.searchHistoryStore,
        waveformProvider: PreviewWaveformProvider()
    )
    return NavigationStack {
        GuidedMeditationsListView(viewModel: viewModel, dependencies: dependencies)
    }
    .environmentObject(FileOpenHandler(
        meditationService: service,
        metadataService: dependencies.metadataService
    ))
}

@available(iOS 17.0, *)
#Preview("Empty State") {
    previewLibrary(meditations: [])
}

@available(iOS 17.0, *)
#Preview("With Meditations") {
    previewLibrary(meditations: PreviewMeditationService.sampleMeditations)
}

@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    previewLibrary(meditations: PreviewMeditationService.sampleMeditations)
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    previewLibrary(meditations: PreviewMeditationService.sampleMeditations)
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    previewLibrary(meditations: PreviewMeditationService.sampleMeditations)
}
#endif
