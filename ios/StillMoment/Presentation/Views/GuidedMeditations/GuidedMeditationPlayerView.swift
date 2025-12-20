//
//  GuidedMeditationPlayerView.swift
//  Still Moment
//
//  Presentation Layer - Guided Meditation Player View
//

import SwiftUI

/// View for playing guided meditation audio
///
/// Features:
/// - Teacher and meditation name display
/// - Duration and remaining time
/// - Progress slider with seek functionality
/// - Play/Pause controls
/// - Skip forward/backward buttons
/// - Background audio with lock screen controls
struct GuidedMeditationPlayerView: View {
    // MARK: Lifecycle

    init(meditation: GuidedMeditation) {
        _viewModel = StateObject(wrappedValue: GuidedMeditationPlayerViewModel(meditation: meditation))
    }

    // MARK: Internal

    var body: some View {
        NavigationView {
            ZStack {
                // Warm gradient background (consistent with Timer tab)
                Color.warmGradient
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // Meditation info
                    VStack(spacing: 12) {
                        Text(self.viewModel.meditation.effectiveTeacher)
                            .font(.system(.title3, design: .rounded, weight: .medium))
                            .foregroundColor(Color.interactive)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .accessibilityLabel("guided_meditations.player.teacher")
                            .accessibilityValue(self.viewModel.meditation.effectiveTeacher)

                        Text(self.viewModel.meditation.effectiveName)
                            .font(.system(.title, design: .rounded, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .accessibilityLabel("guided_meditations.player.title")
                            .accessibilityValue(self.viewModel.meditation.effectiveName)
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Progress section
                    VStack(spacing: 16) {
                        // Progress slider
                        Slider(
                            value: Binding(
                                get: { self.viewModel.currentTime },
                                set: { self.viewModel.seek(to: $0) }
                            ),
                            in: 0...max(self.viewModel.duration, 1)
                        )
                        .tint(Color.interactive)
                        .accessibilityIdentifier("player.slider.progress")
                        .accessibilityLabel("guided_meditations.player.progress")
                        .accessibilityValue("\(Int(self.viewModel.progress * 100)) percent")

                        // Time labels
                        HStack {
                            Text(self.viewModel.formattedCurrentTime)
                                .font(.system(.caption, design: .rounded).monospacedDigit())
                                .foregroundColor(.textSecondary)
                                .accessibilityIdentifier("player.text.currentTime")
                                .accessibilityLabel("guided_meditations.player.currentTime")
                                .accessibilityValue(self.viewModel.formattedCurrentTime)

                            Spacer()

                            Text(self.viewModel.formattedRemainingTime)
                                .font(.system(.caption, design: .rounded).monospacedDigit())
                                .foregroundColor(.textSecondary)
                                .accessibilityIdentifier("player.text.remainingTime")
                                .accessibilityLabel("guided_meditations.player.remainingTime")
                                .accessibilityValue(self.viewModel.formattedRemainingTime)
                        }
                    }
                    .padding(.horizontal)

                    // Controls
                    HStack(spacing: 40) {
                        // Skip backward
                        Button {
                            self.viewModel.skipBackward()
                        } label: {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 32, design: .rounded))
                                .foregroundColor(Color.interactive)
                        }
                        .accessibilityIdentifier("player.button.skipBackward")
                        .accessibilityLabel("guided_meditations.player.skipBackward")

                        // Play/Pause
                        Button {
                            self.viewModel.togglePlayPause()
                        } label: {
                            Image(systemName: self.viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64, design: .rounded))
                                .foregroundColor(Color.interactive)
                        }
                        .accessibilityIdentifier("player.button.playPause")
                        .accessibilityLabel(
                            self.viewModel.isPlaying ?
                                "guided_meditations.player.pause" :
                                "guided_meditations.player.play"
                        )

                        // Skip forward
                        Button {
                            self.viewModel.skipForward()
                        } label: {
                            Image(systemName: "goforward.10")
                                .font(.system(size: 32, design: .rounded))
                                .foregroundColor(Color.interactive)
                        }
                        .accessibilityIdentifier("player.button.skipForward")
                        .accessibilityLabel("guided_meditations.player.skipForward")
                    }
                    .padding(.vertical)

                    Spacer()
                }
                .padding()

                // Loading overlay
                if self.viewModel.playbackState == .loading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.textPrimary.opacity(.opacityOverlay))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", comment: "")) {
                        self.viewModel.cleanup()
                        self.dismiss()
                    }
                    .foregroundColor(.textSecondary)
                    .accessibilityIdentifier("player.button.close")
                }
            }
            .alert(
                NSLocalizedString("common.error", comment: ""),
                isPresented: .constant(self.viewModel.errorMessage != nil)
            ) {
                Button(NSLocalizedString("common.ok", comment: "")) {
                    self.viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .onAppear {
                Task {
                    await self.viewModel.loadAudio()
                }
            }
            .onDisappear {
                self.viewModel.cleanup()
            }
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss
    @StateObject private var viewModel: GuidedMeditationPlayerViewModel
}

// MARK: - Previews

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
    GuidedMeditationPlayerView(meditation: previewMeditation)
}

@available(iOS 17.0, *)
#Preview("Long Name") {
    GuidedMeditationPlayerView(meditation: previewMeditationLongName)
}

// Device Size Previews
@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    GuidedMeditationPlayerView(meditation: previewMeditationLongName)
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    GuidedMeditationPlayerView(meditation: previewMeditationLongName)
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    GuidedMeditationPlayerView(meditation: previewMeditationLongName)
}
