//
//  GuidedMeditationPlayerView+Previews.swift
//  Still Moment
//
//  SwiftUI previews for GuidedMeditationPlayerView (DEBUG only; built on preview doubles / AppDependencies.live()).
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

private let previewMeditationLongName = GuidedMeditation(
    fileBookmark: Data(),
    fileName: "test.mp3",
    duration: 600,
    teacher: "Dr. Kristin Neff & Dr. Christopher Germer",
    name: "Loving Kindness Meditation for Self-Compassion and Inner Peace"
)

@available(iOS 17.0, *)
#Preview("Default") {
    GuidedMeditationPlayerView(meditation: previewMeditation, dependencies: .live())
}

@available(iOS 17.0, *)
#Preview("Long Name") {
    GuidedMeditationPlayerView(meditation: previewMeditationLongName, dependencies: .live())
}

@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    GuidedMeditationPlayerView(meditation: previewMeditationLongName, dependencies: .live())
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    GuidedMeditationPlayerView(meditation: previewMeditationLongName, dependencies: .live())
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    GuidedMeditationPlayerView(meditation: previewMeditationLongName, dependencies: .live())
}
#endif
