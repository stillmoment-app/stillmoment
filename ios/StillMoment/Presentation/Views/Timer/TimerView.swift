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
            let isCompactHeight = geometry.size.height < 700

            VStack(spacing: 0) {
                if self.viewModel.timerState == .idle {
                    Spacer(minLength: 8)
                        .frame(maxHeight: 40)
                } else {
                    Spacer(minLength: 8)
                }

                // Title
                Text("welcome.title", bundle: .main)
                    .themeFont(.screenTitle, size: isCompactHeight ? 24 : nil)
                    .padding(.horizontal)

                Spacer(minLength: 12)
                    .frame(maxHeight: 30)

                // Timer Display or Picker
                if self.viewModel.timerState == .idle {
                    self.minutePicker(geometry: geometry)
                } else {
                    self.timerDisplay(geometry: geometry)
                }

                Spacer(minLength: 16)

                // Control Buttons
                self.controlButtons
                    .padding(.horizontal)

                Spacer(minLength: 16)

                // Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .themeFont(.caption, color: \.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(
                self.theme.backgroundGradient
                    .ignoresSafeArea()
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if self.viewModel.timerState != .idle, self.viewModel.timerState != .completed {
                    Button {
                        self.viewModel.resetTimer()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(self.theme.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityIdentifier("timer.button.end")
                    .accessibilityLabel("accessibility.endMeditation")
                    .accessibilityHint("accessibility.endMeditation.hint")
                }
            }
        }
        .navigationDestination(isPresented: self.$navigateToEditor) {
            if let vm = self.editorViewModel {
                PraxisEditorView(viewModel: vm)
            }
        }
        .onChange(of: self.navigateToEditor) { isPresented in
            if !isPresented {
                self.editorViewModel?.save()
            }
        }
        .overlay {
            if self.viewModel.timerState == .completed {
                ZStack {
                    self.theme.backgroundGradient
                        .ignoresSafeArea()
                    MeditationCompletionView(
                        onBack: { self.viewModel.resetTimer() },
                        backAccessibilityLabel: NSLocalizedString("accessibility.backToTimer", comment: "")
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: self.viewModel.timerState == .completed)
        .toolbar(self.isZenMode ? .hidden : .visible, for: .tabBar)
        .animation(.easeInOut(duration: 0.35), value: self.isZenMode)
        .onChange(of: self.fileOpenHandler.shouldStopMeditation) { shouldStop in
            guard shouldStop
            else { return }
            self.viewModel.resetTimer()
            self.fileOpenHandler.shouldStopMeditation = false
        }
        .onChange(of: self.fileOpenHandler.pendingCustomAudioImport) { pendingImport in
            guard pendingImport != nil
            else { return }
            // Open PraxisEditor for navigation to the imported audio's selection screen
            let praxisForEditor = self.viewModel.currentPraxis
                .withDurationMinutes(self.viewModel.selectedMinutes)
            self.editorViewModel = self.viewModel.makePraxisEditorViewModel(praxis: praxisForEditor)
            self.navigateToEditor = true
        }
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @EnvironmentObject private var fileOpenHandler: FileOpenHandler
    @StateObject private var viewModel: TimerViewModel
    @State private var navigateToEditor = false
    @State private var editorViewModel: PraxisEditorViewModel?

    private var isZenMode: Bool {
        self.viewModel.isZenMode
    }

    private var stateText: String {
        switch self.viewModel.timerState {
        case .idle:
            NSLocalizedString("state.ready", comment: "")
        case .preparation:
            self.viewModel.currentPreparationAffirmation
        case .startGong,
             .attunement,
             .running,
             .endGong:
            self.viewModel.currentRunningAffirmation
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
        case .startGong,
             .attunement,
             .running,
             .endGong:
            NSLocalizedString("accessibility.timerState.running", comment: "")
        case .completed:
            NSLocalizedString("accessibility.timerState.completed", comment: "")
        }
    }

    // MARK: - View Components

    private func minutePicker(geometry: GeometryProxy) -> some View {
        let isCompactHeight = geometry.size.height < 700
        let imageSize: CGFloat = isCompactHeight ? 100 : 150
        let spacing: CGFloat = isCompactHeight ? 12 : 20

        return VStack(spacing: spacing) {
            Image("HandsHeart")
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .padding(.bottom, isCompactHeight ? 4 : 8)

            Text("duration.question", bundle: .main)
                .themeFont(.sectionTitle, size: isCompactHeight ? 18 : nil)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal)
                .accessibilityIdentifier("timer.duration.question")

            self.durationWheel(isCompact: isCompactHeight)

            self.configurationPillsRow
                .padding(.top, isCompactHeight ? 8 : 16)
        }
    }

    private func durationWheel(isCompact: Bool) -> some View {
        Picker(
            NSLocalizedString("accessibility.durationPicker.label", comment: ""),
            selection: self.$viewModel.selectedMinutes
        ) {
            ForEach(self.viewModel.minimumDurationMinutes...60, id: \.self) { minute in
                Text(String(format: NSLocalizedString("duration.minutes", comment: ""), minute))
                    .tag(minute)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: isCompact ? 120 : 150)
        .accessibilityIdentifier("timer.picker.minutes")
        .accessibilityLabel("accessibility.durationPicker")
        .accessibilityHint("accessibility.durationPicker.hint")
    }

    private var configurationPillsRow: some View {
        Button {
            // Capture current wheel selection into the praxis so the editor preserves it on save
            let praxisForEditor = self.viewModel.currentPraxis
                .withDurationMinutes(self.viewModel.selectedMinutes)
            self.editorViewModel = self.viewModel.makePraxisEditorViewModel(praxis: praxisForEditor)
            self.navigateToEditor = true
        } label: {
            VStack(spacing: 8) {
                // Row 1: always-visible base settings
                HStack(spacing: 8) {
                    if let label = self.viewModel.preparationPillLabel {
                        self.settingPill(icon: "hourglass", label: label)
                    }
                    self.settingPill(icon: "bell", label: self.viewModel.gongPillLabel)
                    self.settingPill(icon: "wind", label: self.viewModel.backgroundPillLabel)
                }

                // Row 2: optional settings (only when active)
                let hasExtras = self.viewModel.attunementPillLabel != nil
                    || self.viewModel.intervalPillLabel != nil
                if hasExtras {
                    HStack(spacing: 8) {
                        if let label = self.viewModel.attunementPillLabel {
                            self.settingPill(icon: "headphones", label: label)
                        }
                        if let label = self.viewModel.intervalPillLabel {
                            self.settingPill(icon: "arrow.clockwise", label: label)
                        }
                    }
                }
            }
        }
        .accessibilityLabel(NSLocalizedString("accessibility.timer.configuration.label", comment: ""))
        .accessibilityHint(NSLocalizedString("accessibility.timer.configuration.hint", comment: ""))
        .accessibilityIdentifier("timer.button.configuration")
    }

    private func settingPill(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .accessibilityHidden(true)
            Text(label)
                .themeFont(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(self.theme.accentBackground))
        .overlay(Capsule().strokeBorder(self.theme.textSecondary.opacity(0.2), lineWidth: 0.5))
        .foregroundColor(self.theme.textSecondary)
    }

    private func timerDisplay(geometry: GeometryProxy) -> some View {
        let isCompactHeight = geometry.size.height < 700
        let circleSize: CGFloat = min(geometry.size.width * (isCompactHeight ? 0.55 : 0.7), 320)
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
                .themeFont(.bodySecondary, size: isCompactHeight ? 14 : nil)
                .accessibilityIdentifier("timer.state.text")
                .accessibilityLabel(self.accessibilityStateLabel)
        }
    }

    private func preparationCircle(size: CGFloat, isCompact: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(self.theme.ringTrack, lineWidth: 8)
                .frame(width: size, height: size)

            Text(self.viewModel.formattedTime)
                .themeFont(.timerCountdown, size: isCompact ? 80 : nil)
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
                .stroke(self.theme.ringTrack, lineWidth: 8)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: self.viewModel.progress)
                .stroke(self.theme.progress, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: self.viewModel.progress)
                .shadow(color: self.theme.progress.opacity(.opacityShadow), radius: 8, x: 0, y: 0)

            Text(self.viewModel.formattedTime)
                .themeFont(.timerRunning, size: isCompact ? 48 : nil)
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
            // Start Button (only in idle state)
            if self.viewModel.canStart {
                Button(action: self.viewModel.startTimer) {
                    Label(NSLocalizedString("button.start", comment: ""), systemImage: "play.fill")
                }
                .warmPrimaryButton()
                .accessibilityIdentifier("timer.button.start")
                .accessibilityLabel("accessibility.startMeditation")
                .accessibilityHint("accessibility.startMeditation.hint")
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
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
#endif

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    NavigationStack {
        TimerView()
    }
}
