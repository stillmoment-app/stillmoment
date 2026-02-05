//
//  TimerFocusView.swift
//  Still Moment
//
//  Presentation Layer - Distraction-free Timer Focus View
//

import SwiftUI

/// Distraction-free view for active meditation timer.
///
/// Features:
/// - Overlay presentation with slide-up animation
/// - Timer display with countdown/progress ring
/// - Pause/Resume controls only (no reset - close button handles that)
/// - Close button to cancel and return to selection
/// - Auto-closes when meditation completes
struct TimerFocusView: View {
    // MARK: Lifecycle

    init(viewModel: TimerViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let isCompactHeight = geometry.size.height < 700
                let circleSize: CGFloat = isCompactHeight ? 220 : 280
                let spacing: CGFloat = isCompactHeight ? 16 : 24

                VStack(spacing: 0) {
                    Spacer()

                    // Title
                    Text("welcome.title", bundle: .main)
                        .font(.system(size: isCompactHeight ? 24 : 28, weight: .light, design: .rounded))
                        .foregroundColor(self.theme.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()
                        .frame(height: spacing)

                    // Timer Display
                    self.timerDisplay(circleSize: circleSize, isCompact: isCompactHeight)

                    Spacer()
                        .frame(height: spacing)

                    // State Text / Affirmation
                    Text(self.stateText)
                        .font(.system(size: isCompactHeight ? 14 : 16, weight: .regular, design: .rounded))
                        .foregroundColor(self.theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .accessibilityIdentifier("focus.state.text")

                    Spacer()

                    // Control Buttons
                    self.controlButtons
                        .padding(.horizontal)
                        .padding(.bottom, isCompactHeight ? 24 : 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(self.theme.backgroundGradient)
            }
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.close", comment: "")) {
                        self.viewModel.resetTimer()
                        self.dismiss()
                    }
                    .foregroundColor(self.theme.textSecondary)
                    .accessibilityIdentifier("focus.button.close")
                    .accessibilityLabel("accessibility.closeFocus")
                    .accessibilityHint("accessibility.closeFocus.hint")
                }
            }
            .onAppear {
                // Start timer when focus view appears
                if self.viewModel.timerState == .idle {
                    self.viewModel.startTimer()
                }
            }
            .onChange(of: self.viewModel.timerState) { newState in
                // Auto-close when timer returns to idle after completion
                if self.wasActive, newState == .idle {
                    self.dismiss()
                }

                // Track if timer was ever active
                if newState == .preparation || newState == .running {
                    self.wasActive = true
                }
            }
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: TimerViewModel
    @State private var wasActive = false

    private var stateText: String {
        switch self.viewModel.timerState {
        case .idle:
            NSLocalizedString("state.ready", comment: "")
        case .preparation:
            self.viewModel.currentPreparationAffirmation
        case .running:
            self.viewModel.currentRunningAffirmation
        case .paused:
            NSLocalizedString("state.paused", comment: "")
        case .completed:
            NSLocalizedString("state.completed", comment: "")
        }
    }

    // MARK: - View Components

    private func timerDisplay(circleSize: CGFloat, isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 12 : 20) {
            ZStack {
                if self.viewModel.isPreparation {
                    self.preparationCircle(size: circleSize, isCompact: isCompact)
                } else {
                    self.progressCircle(size: circleSize, isCompact: isCompact)
                }
            }
        }
    }

    private func preparationCircle(size: CGFloat, isCompact: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(self.theme.ringTrack, lineWidth: 10)
                .frame(width: size, height: size)

            Text(self.viewModel.formattedTime)
                .font(.system(size: isCompact ? 90 : 110, weight: .ultraLight, design: .rounded))
                .foregroundColor(self.theme.textPrimary)
                .monospacedDigit()
                .accessibilityIdentifier("focus.display.preparation")
                .accessibilityLabel(String(
                    format: NSLocalizedString("accessibility.preparation", comment: ""),
                    self.viewModel.remainingPreparationSeconds
                ))
        }
    }

    private func progressCircle(size: CGFloat, isCompact: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(self.theme.ringTrack, lineWidth: 10)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: self.viewModel.progress)
                .stroke(self.theme.progress, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: self.viewModel.progress)
                .shadow(color: self.theme.progress.opacity(.opacityShadow), radius: 8, x: 0, y: 0)

            Text(self.viewModel.formattedTime)
                .font(.system(size: isCompact ? 56 : 72, weight: .thin, design: .rounded))
                .foregroundColor(self.theme.textPrimary)
                .monospacedDigit()
                .accessibilityIdentifier("focus.display.time")
                .accessibilityLabel(String(
                    format: NSLocalizedString("accessibility.remainingTime", comment: ""),
                    self.viewModel.formattedTime
                ))
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 30) {
            if self.viewModel.canPause {
                Button(action: self.viewModel.pauseTimer) {
                    Label(NSLocalizedString("button.pause", comment: ""), systemImage: "pause.circle")
                }
                .warmSecondaryButton()
                .accessibilityIdentifier("focus.button.pause")
                .accessibilityLabel("accessibility.pauseMeditation")
                .accessibilityHint("accessibility.pauseMeditation.hint")
            } else if self.viewModel.canResume {
                Button(action: self.viewModel.resumeTimer) {
                    Label(NSLocalizedString("button.resume", comment: ""), systemImage: "play.fill")
                }
                .warmPrimaryButton()
                .accessibilityIdentifier("focus.button.resume")
                .accessibilityLabel("accessibility.resumeMeditation")
                .accessibilityHint("accessibility.resumeMeditation.hint")
            }
        }
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Preparation") {
    TimerFocusView(viewModel: TimerViewModel.preview(state: .preparation))
}

@available(iOS 17.0, *)
#Preview("Running") {
    TimerFocusView(viewModel: TimerViewModel.preview(state: .running))
}

@available(iOS 17.0, *)
#Preview("Paused") {
    TimerFocusView(viewModel: TimerViewModel.preview(state: .paused))
}

@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    TimerFocusView(viewModel: TimerViewModel.preview(state: .running))
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    TimerFocusView(viewModel: TimerViewModel.preview(state: .running))
}
