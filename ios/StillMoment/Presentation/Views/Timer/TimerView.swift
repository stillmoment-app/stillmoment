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
        self.timerContent
            .sheet(isPresented: self.$showFocusMode) {
                TimerFocusView(viewModel: self.viewModel)
            }
    }

    private var timerContent: some View {
        GeometryReader { geometry in
            let isCompactHeight = geometry.size.height < 700

            VStack(spacing: 0) {
                Spacer(minLength: 8)
                    .frame(maxHeight: 40)

                // Title
                Text("welcome.title", bundle: .main)
                    .font(.system(size: isCompactHeight ? 24 : 28, weight: .light, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal)

                Spacer(minLength: 12)
                    .frame(maxHeight: 30)

                // Timer Display or Picker
                if self.viewModel.timerState == .idle {
                    self.minutePicker(geometry: geometry)
                } else {
                    self.timerDisplay(geometry: geometry)
                }

                Spacer(minLength: 24)
                    .frame(maxHeight: isCompactHeight ? 40 : 60)

                // Control Buttons
                self.controlButtons
                    .padding(.horizontal)

                Spacer(minLength: 16)

                // Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
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
                HStack(spacing: 8) {
                    if !self.hasSeenSettingsHint {
                        self.settingsHintTooltip
                    }

                    Button {
                        self.hasSeenSettingsHint = true
                        self.showSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityIdentifier("timer.button.settings")
                    .accessibilityLabel("accessibility.settings")
                    .accessibilityHint("accessibility.settings.hint")
                }
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
    @State private var showFocusMode = false
    @AppStorage("hasSeenSettingsHint")
    private var hasSeenSettingsHint = false

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
        case .preparation:
            NSLocalizedString("accessibility.timerState.preparation", comment: "")
        case .running:
            NSLocalizedString("accessibility.timerState.running", comment: "")
        case .paused:
            NSLocalizedString("accessibility.timerState.paused", comment: "")
        case .completed:
            NSLocalizedString("accessibility.timerState.completed", comment: "")
        }
    }

    // MARK: - View Components

    private var settingsHintTooltip: some View {
        Text("settings.hint.text", bundle: .main)
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.paleApricot)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .accessibilityLabel("accessibility.settings.hint.tooltip")
            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }

    private func minutePicker(geometry: GeometryProxy) -> some View {
        let isCompactHeight = geometry.size.height < 700
        let imageSize: CGFloat = isCompactHeight ? 100 : 150
        let pickerHeight: CGFloat = isCompactHeight ? 120 : 150
        let spacing: CGFloat = isCompactHeight ? 12 : 20

        return VStack(spacing: spacing) {
            Image("HandsHeart")
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .padding(.bottom, isCompactHeight ? 4 : 8)

            Text("duration.question", bundle: .main)
                .font(.system(size: isCompactHeight ? 18 : 20, weight: .light, design: .rounded))
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
            .frame(height: pickerHeight)
            .accessibilityIdentifier("timer.picker.minutes")
            .accessibilityLabel("accessibility.durationPicker")
            .accessibilityHint("accessibility.durationPicker.hint")

            Text("duration.footer", bundle: .main)
                .font(.system(size: isCompactHeight ? 14 : 15, weight: .light, design: .rounded))
                .foregroundColor(.textSecondary)
                .italic()
                .padding(.horizontal)
                .padding(.top, isCompactHeight ? 8 : 16)
        }
    }

    private func timerDisplay(geometry: GeometryProxy) -> some View {
        let isCompactHeight = geometry.size.height < 700
        let circleSize: CGFloat = isCompactHeight ? 200 : 250
        let spacing: CGFloat = isCompactHeight ? 12 : 20

        return VStack(spacing: spacing) {
            ZStack {
                if self.viewModel.isPreparation {
                    self.preparationCircle(size: circleSize, isCompact: isCompactHeight)
                } else {
                    self.progressCircle(size: circleSize, isCompact: isCompactHeight)
                }
            }

            Text(self.stateText)
                .font(.system(size: isCompactHeight ? 14 : 16, weight: .regular, design: .rounded))
                .foregroundColor(.textSecondary)
                .accessibilityIdentifier("timer.state.text")
                .accessibilityLabel(self.accessibilityStateLabel)
        }
    }

    private func preparationCircle(size: CGFloat, isCompact: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(Color.ringBackground, lineWidth: 8)
                .frame(width: size, height: size)

            Text(self.viewModel.formattedTime)
                .font(.system(size: isCompact ? 80 : 100, weight: .ultraLight, design: .rounded))
                .foregroundColor(.textPrimary)
                .monospacedDigit()
                .accessibilityIdentifier("timer.display.time")
                .accessibilityLabel(String(
                    format: NSLocalizedString("accessibility.preparation", comment: ""),
                    self.viewModel.remainingPreparationSeconds
                ))
        }
    }

    private func progressCircle(size: CGFloat, isCompact: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(Color.ringBackground, lineWidth: 8)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: self.viewModel.progress)
                .stroke(Color.progress, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: self.viewModel.progress)
                .shadow(color: Color.progress.opacity(.opacityShadow), radius: 8, x: 0, y: 0)

            Text(self.viewModel.formattedTime)
                .font(.system(size: isCompact ? 48 : 60, weight: .thin, design: .rounded))
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

    private var controlButtons: some View {
        HStack(spacing: 30) {
            // Start/Resume/Pause Button
            if self.viewModel.canStart {
                Button {
                    self.showFocusMode = true
                } label: {
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
        }
    }
}

// MARK: - Previews

// State Previews
@available(iOS 17.0, *)
#Preview("Idle") {
    NavigationStack {
        TimerView()
    }
}

@available(iOS 17.0, *)
#Preview("Preparation") {
    NavigationStack {
        TimerView(viewModel: TimerViewModel.preview(state: .preparation))
    }
}

@available(iOS 17.0, *)
#Preview("Running") {
    NavigationStack {
        TimerView(viewModel: TimerViewModel.preview(state: .running))
    }
}

@available(iOS 17.0, *)
#Preview("Paused") {
    NavigationStack {
        TimerView(viewModel: TimerViewModel.preview(state: .paused))
    }
}

@available(iOS 17.0, *)
#Preview("Completed") {
    NavigationStack {
        TimerView(viewModel: TimerViewModel.preview(state: .completed))
    }
}

// Device Size Previews
@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    NavigationStack {
        TimerView()
    }
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    NavigationStack {
        TimerView()
    }
}

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    NavigationStack {
        TimerView()
    }
}
