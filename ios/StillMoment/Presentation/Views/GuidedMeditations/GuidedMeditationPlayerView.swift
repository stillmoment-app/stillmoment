//
//  GuidedMeditationPlayerView.swift
//  Still Moment
//
//  Presentation Layer - Guided Meditation Player View
//

import SwiftUI

/// Atemkreis-Player fuer Guided Meditations.
///
/// Komplett auf eine Geste reduziert: Pause/Play in der Hauptphase ist die einzige
/// sichtbare Bedienung. Auto-Start beim Oeffnen — Pre-Roll oder Audio startet
/// sofort, kein initialer Play-Tap. Lehrer + Titel oben, Atemkreis zentriert,
/// Restzeit-Label unten, Schliessen-Button oben links.
struct GuidedMeditationPlayerView: View {
    // MARK: Lifecycle

    init(
        meditation: GuidedMeditation,
        preparationTimeSeconds: Int? = nil,
        meditationService: GuidedMeditationServiceProtocol = GuidedMeditationService()
    ) {
        _viewModel = StateObject(wrappedValue: GuidedMeditationPlayerViewModel(
            meditation: meditation,
            preparationTimeSeconds: preparationTimeSeconds,
            meditationService: meditationService
        ))
    }

    init(viewModel: GuidedMeditationPlayerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            if self.viewModel.isCompleted {
                MeditationCompletionView {
                    self.dismiss()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            } else if self.didKickOff {
                self.playerContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.7), value: self.viewModel.isCompleted)
        .animation(.easeInOut(duration: 0.4), value: self.didKickOff)
        .animation(.easeInOut(duration: 0.4), value: self.viewModel.phase)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !self.viewModel.isCompleted {
                    Button {
                        self.viewModel.stop()
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(self.theme.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityIdentifier("player.button.close")
                    .accessibilityLabel("accessibility.backToLibrary")
                }
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
            // Clear any stale completion marker so a new session starts fresh
            self.completedAtRaw = 0
            self.meditationIdRaw = ""
            Task {
                await self.viewModel.loadAudio()
                // Auto-Start: kein initialer Play-Tap — Pre-Roll bzw. Audio
                // startet sofort beim Oeffnen des Players. ViewModel guarded
                // selbst, falls loadAudio einen Fehler gesetzt hat.
                guard self.viewModel.errorMessage == nil else {
                    self.didKickOff = true
                    return
                }
                self.viewModel.startPlayback()
                self.didKickOff = true
            }
        }
        .onDisappear {
            self.viewModel.cleanup()
        }
        .onChange(of: self.viewModel.completionEvent) { event in
            guard let event else {
                return
            }
            self.completedAtRaw = event.completedAt.timeIntervalSince1970
            self.meditationIdRaw = event.meditationId.uuidString
        }
        .toolbar(self.isZenMode ? .hidden : .visible, for: .tabBar)
        .animation(.easeInOut(duration: 0.35), value: self.isZenMode)
        .onChange(of: self.fileOpenHandler.shouldStopMeditation) { shouldStop in
            guard shouldStop
            else { return }
            self.viewModel.stop()
            self.dismiss()
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.themeColors)
    private var theme
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @EnvironmentObject private var fileOpenHandler: FileOpenHandler
    @StateObject private var viewModel: GuidedMeditationPlayerViewModel

    @SceneStorage("completion.completedAt")
    private var completedAtRaw: Double = 0
    @SceneStorage("completion.meditationId")
    private var meditationIdRaw: String = ""

    /// Erst gesetzt nachdem `loadAudio()` durch und `startPlayback()` aufgerufen ist.
    /// Verhindert, dass die Hauptphasen-UI (Pause-Button + Restzeit-Label) kurz
    /// aufblitzt, bevor die Pre-Roll-Phase greift.
    @State private var didKickOff = false

    private var isZenMode: Bool {
        self.viewModel.isZenMode
    }

    @ViewBuilder private var playerContent: some View {
        VStack(spacing: 0) {
            // Lehrer + Titel
            VStack(spacing: 8) {
                Text(self.viewModel.meditation.effectiveTeacher)
                    .themeFont(.playerTeacher)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel("guided_meditations.player.teacher")
                    .accessibilityValue(self.viewModel.meditation.effectiveTeacher)

                Text(self.viewModel.meditation.effectiveName)
                    .themeFont(.playerTitle)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel("guided_meditations.player.title")
                    .accessibilityValue(self.viewModel.meditation.effectiveName)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer(minLength: 12)

            // Atemkreis
            BreathingCircleView(
                phase: self.viewModel.phase,
                progress: self.viewModel.progress,
                preRollStartedAt: self.viewModel.countdownStartedAt,
                preRollTotalSeconds: self.viewModel.countdownTotalSeconds,
                reduceMotion: self.reduceMotion
            ) {
                self.circleContent
            }

            Spacer(minLength: 12)

            // Hint (Pre-Roll) oder Restzeit-Label (Hauptphase)
            self.bottomLabel
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        // Loading overlay
        if self.viewModel.playbackState == .loading {
            ProgressView()
                .scaleEffect(1.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(self.theme.textPrimary.opacity(.opacityOverlay))
        }
    }

    @ViewBuilder private var circleContent: some View {
        switch self.viewModel.phase {
        case .preRoll:
            VStack(spacing: 6) {
                Text("\(self.viewModel.remainingCountdownSeconds)")
                    .themeFont(.playerCountdown, size: 72)
                    .monospacedDigit()
                    .accessibilityIdentifier("player.countdown")
                    .accessibilityLabel(
                        String(
                            format: NSLocalizedString(
                                "guided_meditations.player.countdown",
                                comment: ""
                            ),
                            self.viewModel.remainingCountdownSeconds
                        )
                    )

                Text("guided_meditations.player.preroll.label")
                    .themeFont(.playerTimestamp)
                    .foregroundColor(self.theme.textSecondary)
            }
            .transition(.opacity)
        case .playing,
             .paused:
            GlassPauseButton(isPlaying: self.viewModel.isPlaying) {
                HapticFeedback.impact(.soft)
                self.viewModel.togglePlayPause()
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder private var bottomLabel: some View {
        switch self.viewModel.phase {
        case .preRoll:
            Text("guided_meditations.player.preroll.hint")
                .themeFont(.playerTimestamp)
                .foregroundColor(self.theme.textSecondary)
                .textCase(.uppercase)
                .accessibilityIdentifier("player.text.preRollHint")
        case .playing,
             .paused:
            Text(String(
                format: NSLocalizedString(
                    "guided_meditations.player.remainingTime.format",
                    comment: ""
                ),
                self.viewModel.formattedRemainingMinutes
            ))
            .themeFont(.playerRemainingTime)
            .monospacedDigit()
            .textCase(.uppercase)
            .tracking(1.5)
            .accessibilityIdentifier("player.text.remainingTime")
            .accessibilityLabel("guided_meditations.player.remainingTime")
            .accessibilityValue(self.viewModel.formattedRemainingTime)
        }
    }
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
