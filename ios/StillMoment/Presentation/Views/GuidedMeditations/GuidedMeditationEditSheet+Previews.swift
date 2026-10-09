//
//  GuidedMeditationEditSheet+Previews.swift
//  Still Moment
//
//  SwiftUI previews for GuidedMeditationEditSheet (DEBUG only; built on preview doubles / AppDependencies.live()).
//

#if DEBUG
import SwiftUI

private let previewMeditation = GuidedMeditation(
    fileBookmark: Data(),
    fileName: "test.mp3",
    duration: 600,
    teacher: "Jon Kabat-Zinn",
    name: "Body Scan Meditation"
)

@available(iOS 17.0, *)
#Preview("Edit") {
    GuidedMeditationEditSheet(
        meditation: previewMeditation,
        mode: .edit,
        availableTeachers: ["Jon Kabat-Zinn", "Jack Kornfield", "Tara Brach", "Joseph Goldstein"],
        audioService: MockPreviewAudioService(),
        waveformProvider: PreviewWaveformProvider(),
        meditationService: PreviewMeditationService(),
        praxisRepository: AppDependencies.live().praxisRepository,
        onSave: { _ in },
        onCancel: {}
    )
}

@available(iOS 17.0, *)
#Preview("Import (Prefilled)") {
    GuidedMeditationEditSheet(
        meditation: previewMeditation,
        mode: .importMode,
        availableTeachers: ["Jon Kabat-Zinn", "Tara Brach"],
        audioService: MockPreviewAudioService(),
        waveformProvider: PreviewWaveformProvider(),
        meditationService: PreviewMeditationService(),
        praxisRepository: AppDependencies.live().praxisRepository,
        onSave: { _ in },
        onCancel: {}
    )
}

@available(iOS 17.0, *)
#Preview("Import (Empty Prefill)") {
    let draft = GuidedMeditation(
        localFilePath: "",
        fileName: "d067c0ea-2c04-b934.mp3",
        duration: 600,
        teacher: "",
        name: ""
    )
    return GuidedMeditationEditSheet(
        meditation: draft,
        mode: .importMode,
        availableTeachers: ["Jon Kabat-Zinn", "Tara Brach"],
        audioService: MockPreviewAudioService(),
        waveformProvider: PreviewWaveformProvider(),
        meditationService: PreviewMeditationService(),
        praxisRepository: AppDependencies.live().praxisRepository,
        onSave: { _ in },
        onCancel: {}
    )
}
#endif
