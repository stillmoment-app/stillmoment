//
//  GuidedMeditationsListView+Previews.swift
//  Still Moment
//
//  SwiftUI-Previews fuer die Library-Liste (Empty + diverse Geraetegroessen).
//

#if DEBUG
import SwiftUI

@available(iOS 17.0, *)
#Preview("Empty State") {
    NavigationStack {
        GuidedMeditationsListView()
    }
    .environmentObject(FileOpenHandler())
}

@available(iOS 17.0, *)
#Preview("With Meditations") {
    let service = PreviewMeditationService(meditations: PreviewMeditationService.sampleMeditations)
    return NavigationStack {
        GuidedMeditationsListView(meditationService: service)
    }
    .environmentObject(FileOpenHandler())
}

@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    let service = PreviewMeditationService(meditations: PreviewMeditationService.sampleMeditations)
    return NavigationStack {
        GuidedMeditationsListView(meditationService: service)
    }
    .environmentObject(FileOpenHandler())
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    let service = PreviewMeditationService(meditations: PreviewMeditationService.sampleMeditations)
    return NavigationStack {
        GuidedMeditationsListView(meditationService: service)
    }
    .environmentObject(FileOpenHandler())
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    let service = PreviewMeditationService(meditations: PreviewMeditationService.sampleMeditations)
    return NavigationStack {
        GuidedMeditationsListView(meditationService: service)
    }
    .environmentObject(FileOpenHandler())
}
#endif
