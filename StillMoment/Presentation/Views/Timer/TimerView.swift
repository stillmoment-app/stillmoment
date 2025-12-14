//
//  TimerView.swift
//  Still Moment
//
//  Presentation Layer - Main Timer View
//

import SwiftUI

/// Main view for the meditation timer
struct TimerView: View {
    // MARK: Lifecycle

    init(viewModel: TimerViewModel? = nil) {
        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: TimerViewModel())
        }
    }

    // MARK: Internal

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(minHeight: 20, maxHeight: geometry.size.height * 0.05)

                // Title
                Text("welcome.title", bundle: .main)
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal)

                Spacer()
                    .frame(minHeight: 24, maxHeight: geometry.size.height * 0.05)

                // Timer Display or Picker
                if self.viewModel.timerState == .idle {
                    self.minutePicker
                } else {
                    self.timerDisplay
                }

                Spacer()
                    .frame(minHeight: 40, maxHeight: geometry.size.height * 0.1)

                // Control Buttons
                self.controlButtons
                    .padding(.horizontal)
                    .padding(.bottom, max(16, geometry.safeAreaInsets.bottom > 0 ? 8 : 16))

                // Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(
                Color.warmGradient
                    .ignoresSafeArea()
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.showSettings = true
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.textSecondary)
                        .rotationEffect(.degrees(90))
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityIdentifier("timer.button.settings")
                .accessibilityLabel("accessibility.settings")
                .accessibilityHint("accessibility.settings.hint")
            }
        }
        .sheet(isPresented: self.$showSettings) {
            SettingsView(settings: self.$viewModel.settings) {
                self.showSettings = false
                self.viewModel.saveSettings()
            }
        }
    }

    // MARK: Private

    @StateObject private var viewModel: TimerViewModel
    @State private var showSettings = false

    private var stateText: String {
        switch self.viewModel.timerState {
        case .idle:
            NSLocalizedString("state.ready", comment: "")
        case .countdown:
            self.viewModel.currentCountdownAffirmation
        case .running:
            self.viewModel.currentRunningAffirmation
        case .paused:
            NSLocalizedString("state.paused", comment: "")
        case .completed:
            NSLocalizedString("state.completed", comment: "")
        }
    }

    // MARK: - Accessibility Helpers

    private var accessibilityTimeValue: String {
        let minutes = self.viewModel.remainingSeconds / 60
        let seconds = self.viewModel.remainingSeconds % 60

        var components: [String] = []

        if minutes > 0 {
            let minutesKey = minutes == 1 ? "time.minute" : "time.minutes"
            components.append(String(format: NSLocalizedString(minutesKey, comment: ""), minutes))
        }

        if seconds > 0 {
            let secondsKey = seconds == 1 ? "time.second" : "time.seconds"
            components.append(String(format: NSLocalizedString(secondsKey, comment: ""), seconds))
        }

        if components.isEmpty {
            return NSLocalizedString("time.zeroRemaining", comment: "")
        }

        let andSeparator = NSLocalizedString("common.and", comment: "")
        let remaining = NSLocalizedString("time.remaining", comment: "")
        return components.joined(separator: " \(andSeparator) ") + " \(remaining)"
    }

    private var accessibilityStateLabel: String {
        switch self.viewModel.timerState {
        case .idle:
            NSLocalizedString("accessibility.timerState.idle", comment: "")
        case .countdown:
            NSLocalizedString("accessibility.timerState.countdown", comment: "")
        case .running:
            NSLocalizedString("accessibility.timerState.running", comment: "")
        case .paused:
            NSLocalizedString("accessibility.timerState.paused", comment: "")
        case .completed:
            NSLocalizedString("accessibility.timerState.completed", comment: "")
        }
    }

    // MARK: - View Components

    private var minutePicker: some View {
        VStack(spacing: 20) {
            Text("🤲")
                .font(.system(size: 48))
                .padding(.bottom, 8)

            Text("duration.question", bundle: .main)
                .font(.system(size: 20, weight: .light, design: .rounded))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal)
                .accessibilityIdentifier("timer.duration.question")

            Picker(
                NSLocalizedString("accessibility.durationPicker.label", comment: ""),
                selection: self.$viewModel.selectedMinutes
            ) {
                ForEach(1...60, id: \.self) { minute in
                    Text(String(format: NSLocalizedString("duration.minutes", comment: ""), minute))
                        .tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .accessibilityIdentifier("timer.picker.minutes")
            .accessibilityLabel("accessibility.durationPicker")
            .accessibilityHint("accessibility.durationPicker.hint")

            Text("duration.footer", bundle: .main)
                .font(.system(size: 15, weight: .light, design: .rounded))
                .foregroundColor(.textSecondary)
                .italic()
                .padding(.horizontal)
                .padding(.top, 16)
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 20) {
            // Circular Progress (or Countdown Display)
            ZStack {
                if self.viewModel.isCountdown {
                    // Countdown Display
                    Circle()
                        .stroke(Color.ringBackground, lineWidth: 8)
                        .frame(width: 250, height: 250)

                    Text(self.viewModel.formattedTime)
                        .font(.system(size: 100, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .monospacedDigit()
                        .accessibilityIdentifier("timer.display.time")
                        .accessibilityLabel(String(
                            format: NSLocalizedString("accessibility.countdown", comment: ""),
                            self.viewModel.countdownSeconds
                        ))
                } else {
                    // Regular Timer Display
                    Circle()
                        .stroke(Color.ringBackground, lineWidth: 8)
                        .frame(width: 250, height: 250)

                    Circle()
                        .trim(from: 0, to: self.viewModel.progress)
                        .stroke(
                            Color.progress,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: self.viewModel.progress)
                        .shadow(color: Color.progress.opacity(.opacityShadow), radius: 8, x: 0, y: 0)

                    // Time Display
                    Text(self.viewModel.formattedTime)
                        .font(.system(size: 60, weight: .thin, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .monospacedDigit()
                        .accessibilityIdentifier("timer.display.time")
                        .accessibilityLabel(String(
                            format: NSLocalizedString("accessibility.remainingTime", comment: ""),
                            self.viewModel.formattedTime
                        ))
                        .accessibilityValue(self.accessibilityTimeValue)
                }
            }

            // State Indicator
            Text(self.stateText)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.textSecondary)
                .accessibilityIdentifier("timer.state.text")
                .accessibilityLabel(self.accessibilityStateLabel)

            // Gentle reminder for running state
            if self.viewModel.timerState == .running {
                Text("timer.lockscreen.hint", bundle: .main)
                    .font(.system(size: 13, weight: .light, design: .rounded))
                    .foregroundColor(.textSecondary.opacity(.opacityTertiary))
                    .padding(.top, 40)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 30) {
            // Start/Resume/Pause Button
            if self.viewModel.canStart {
                Button(action: self.viewModel.startTimer) {
                    Label(NSLocalizedString("button.start", comment: ""), systemImage: "play.fill")
                }
                .warmPrimaryButton()
                .accessibilityIdentifier("timer.button.start")
                .accessibilityLabel("accessibility.startMeditation")
                .accessibilityHint("accessibility.startMeditation.hint")
            } else if self.viewModel.canPause {
                Button(action: self.viewModel.pauseTimer) {
                    Label(NSLocalizedString("button.pause", comment: ""), systemImage: "pause.circle")
                }
                .warmSecondaryButton()
                .accessibilityIdentifier("timer.button.pause")
                .accessibilityLabel("accessibility.pauseMeditation")
                .accessibilityHint("accessibility.pauseMeditation.hint")
            } else if self.viewModel.canResume {
                Button(action: self.viewModel.resumeTimer) {
                    Label(NSLocalizedString("button.resume", comment: ""), systemImage: "play.fill")
                }
                .warmPrimaryButton()
                .accessibilityIdentifier("timer.button.resume")
                .accessibilityLabel("accessibility.resumeMeditation")
                .accessibilityHint("accessibility.resumeMeditation.hint")
            }

            // Reset Button
            if self.viewModel.canReset {
                Button(action: self.viewModel.resetTimer) {
                    Label(NSLocalizedString("button.reset", comment: ""), systemImage: "arrow.counterclockwise")
                }
                .warmSecondaryButton()
                .accessibilityIdentifier("timer.button.reset")
                .accessibilityLabel("accessibility.resetTimer")
                .accessibilityHint("accessibility.resetTimer.hint")
            }
        }
    }
}

// MARK: - Previews

// State Previews
#Preview("Idle") {
    NavigationStack {
        TimerView()
    }
}

#Preview("Countdown") {
    NavigationStack {
        TimerView(viewModel: TimerViewModel.preview(state: .countdown))
    }
}

#Preview("Running") {
    NavigationStack {
        TimerView(viewModel: TimerViewModel.preview(state: .running))
    }
}

#Preview("Paused") {
    NavigationStack {
        TimerView(viewModel: TimerViewModel.preview(state: .paused))
    }
}

#Preview("Completed") {
    NavigationStack {
        TimerView(viewModel: TimerViewModel.preview(state: .completed))
    }
}

// Device Size Previews
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    NavigationStack {
        TimerView()
    }
}

#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    NavigationStack {
        TimerView()
    }
}

#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    NavigationStack {
        TimerView()
    }
}
