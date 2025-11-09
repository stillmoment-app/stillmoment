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
/// - Play/Pause/Stop controls
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
                            .foregroundColor(Color.terracotta)
                            .accessibilityLabel("guided_meditations.player.teacher")
                            .accessibilityValue(self.viewModel.meditation.effectiveTeacher)

                        Text(self.viewModel.meditation.effectiveName)
                            .font(.system(.title, design: .rounded, weight: .semibold))
                            .multilineTextAlignment(.center)
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
                        .tint(Color.terracotta)
                        .accessibilityLabel("guided_meditations.player.progress")
                        .accessibilityValue("\(Int(self.viewModel.progress * 100)) percent")

                        // Time labels
                        HStack {
                            Text(self.viewModel.formattedCurrentTime)
                                .font(.system(.caption, design: .rounded).monospacedDigit())
                                .foregroundColor(.secondary)
                                .accessibilityLabel("guided_meditations.player.currentTime")
                                .accessibilityValue(self.viewModel.formattedCurrentTime)

                            Spacer()

                            Text(self.viewModel.formattedRemainingTime)
                                .font(.system(.caption, design: .rounded).monospacedDigit())
                                .foregroundColor(.secondary)
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
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 32, design: .rounded))
                                .foregroundColor(Color.terracotta)
                        }
                        .accessibilityLabel("guided_meditations.player.skipBackward")

                        // Play/Pause
                        Button {
                            self.viewModel.togglePlayPause()
                        } label: {
                            Image(systemName: self.viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64, design: .rounded))
                                .foregroundColor(Color.terracotta)
                        }
                        .accessibilityLabel(
                            self.viewModel.isPlaying ?
                                "guided_meditations.player.pause" :
                                "guided_meditations.player.play"
                        )

                        // Skip forward
                        Button {
                            self.viewModel.skipForward()
                        } label: {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 32, design: .rounded))
                                .foregroundColor(Color.terracotta)
                        }
                        .accessibilityLabel("guided_meditations.player.skipForward")
                    }
                    .padding(.vertical)

                    // Stop button
                    Button {
                        self.viewModel.stop()
                    } label: {
                        Text("guided_meditations.player.stop")
                            .frame(maxWidth: .infinity)
                    }
                    .warmPrimaryButton()
                    .padding(.horizontal)
                    .accessibilityLabel("guided_meditations.player.stop")

                    Spacer()
                }
                .padding()

                // Loading overlay
                if self.viewModel.playbackState == .loading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        self.viewModel.cleanup()
                        self.dismiss()
                    }
                    .foregroundColor(.warmGray)
                }
            }
            .alert("Error", isPresented: .constant(self.viewModel.errorMessage != nil)) {
                Button("OK") {
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

// MARK: - Preview

#Preview {
    GuidedMeditationPlayerView(
        meditation: GuidedMeditation(
            fileBookmark: Data(),
            fileName: "test.mp3",
            duration: 600,
            teacher: "Jon Kabat-Zinn",
            name: "Body Scan Meditation"
        )
    )
}
