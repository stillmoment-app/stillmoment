//
//  TimerView.swift
//  Still Moment
//
//  Presentation Layer - Main Timer View
//

import SwiftUI

/// Main view for the meditation timer.
///
/// Idle screen shows the minute picker plus five tappable setting cards
/// (Vorbereitung · Einstimmung · Hintergrund · Gong · Intervall) that
/// push directly into the existing detail views — no Praxis-Editor index.
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
        NavigationStack(path: self.$settingPath) {
            self.content
                .navigationDestination(for: SettingDestination.self) { destination in
                    SettingDetailRoot(
                        destination: destination,
                        viewModel: self.viewModel.sessionEditor
                    )
                }
        }
        .onChange(of: self.fileOpenHandler.shouldStopMeditation) { shouldStop in
            guard shouldStop
            else { return }
            self.viewModel.resetTimer()
            self.fileOpenHandler.shouldStopMeditation = false
        }
        .onChange(of: self.fileOpenHandler.pendingCustomAudioImport) { pendingImport in
            guard let pending = pendingImport
            else { return }
            self.openDetail(for: pending.type == .soundscape ? .background : .attunement)
        }
    }

    private var content: some View {
        GeometryReader { geometry in
            let isCompactHeight = geometry.size.height < 700

            VStack(spacing: 0) {
                Spacer(minLength: 8)
                    .frame(maxHeight: self.viewModel.timerState == .idle ? 24 : 40)

                if self.viewModel.timerState != .idle {
                    Text("welcome.title", bundle: .main)
                        .themeFont(.screenTitle, size: isCompactHeight ? 24 : nil)
                        .padding(.horizontal)

                    Spacer(minLength: 12)
                        .frame(maxHeight: 30)
                }

                if self.viewModel.timerState == .idle {
                    self.idleScreen(geometry: geometry)
                } else {
                    self.timerDisplay(geometry: geometry)
                }

                Spacer(minLength: 16)

                self.controlButtons
                    .padding(.horizontal)

                Spacer(minLength: 16)

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
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @EnvironmentObject private var fileOpenHandler: FileOpenHandler
    @StateObject private var viewModel: TimerViewModel
    @State private var settingPath: [SettingDestination] = []

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

    // MARK: - Idle Screen

    private func idleScreen(geometry: GeometryProxy) -> some View {
        let isCompactHeight = geometry.size.height < 700
        // Dial-Durchmesser: 180 px auf SE, 220 px auf grossen Geraeten.
        let dialDiameter: CGFloat = isCompactHeight ? 180 : 220
        // Section-Spacing: kompakter auf kleinen Geraeten, atmend auf grossen.
        let headlineToDialSpacing: CGFloat = isCompactHeight ? 18 : 28
        let dialToSectionSpacing: CGFloat = isCompactHeight ? 28 : 44
        let sectionToCardsSpacing: CGFloat = isCompactHeight ? 12 : 18

        return VStack(spacing: 0) {
            Text("timer.idle.headline", bundle: .main)
                .themeFont(.sectionTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer(minLength: headlineToDialSpacing)
                .frame(maxHeight: headlineToDialSpacing)

            BreathDial(
                value: self.$viewModel.selectedMinutes,
                minimumValue: self.viewModel.minimumDurationMinutes,
                diameter: dialDiameter
            )

            Spacer(minLength: dialToSectionSpacing)
                .frame(maxHeight: dialToSectionSpacing)

            Text("timer.idle.sectionTitle", bundle: .main)
                .themeFont(.bodySecondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: sectionToCardsSpacing)
                .frame(maxHeight: sectionToCardsSpacing)

            self.settingCardsGrid
                .padding(.horizontal, 18)
        }
    }

    private var settingCardsGrid: some View {
        SettingCardsGrid(
            preparation: SettingCardsGridItem(
                label: NSLocalizedString("settings.card.label.preparation", comment: ""),
                icon: "hourglass",
                value: self.viewModel.preparationCardLabel,
                isOff: self.viewModel.preparationCardIsOff,
                identifier: "timer.card.preparation"
            ) { self.openDetail(for: .preparation) },
            attunement: SettingCardsGridItem(
                label: NSLocalizedString("settings.card.label.attunement", comment: ""),
                icon: "sparkles",
                value: self.viewModel.attunementCardLabel,
                isOff: self.viewModel.attunementCardIsOff,
                identifier: "timer.card.attunement"
            ) { self.openDetail(for: .attunement) },
            background: SettingCardsGridItem(
                label: NSLocalizedString("settings.card.label.background", comment: ""),
                icon: "wind",
                value: self.viewModel.backgroundCardLabel,
                isOff: self.viewModel.backgroundCardIsOff,
                identifier: "timer.card.background"
            ) { self.openDetail(for: .background) },
            gong: SettingCardsGridItem(
                label: NSLocalizedString("settings.card.label.gong", comment: ""),
                icon: "bell",
                value: self.viewModel.gongCardLabel,
                isOff: self.viewModel.gongCardIsOff,
                identifier: "timer.card.gong"
            ) { self.openDetail(for: .gong) },
            interval: SettingCardsGridItem(
                label: NSLocalizedString("settings.card.label.interval", comment: ""),
                icon: "arrow.clockwise",
                value: self.viewModel.intervalCardLabel,
                isOff: self.viewModel.intervalCardIsOff,
                identifier: "timer.card.interval"
            ) { self.openDetail(for: .interval) }
        )
    }

    // MARK: - Navigation

    private func openDetail(for destination: SettingDestination) {
        if self.settingPath.last != destination {
            self.settingPath.append(destination)
        }
    }

    // MARK: - Timer Display

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
@available(iOS 17.0, *)
#Preview("Idle") {
    TimerView()
}

@available(iOS 17.0, *)
#Preview("Preparation") {
    TimerView(viewModel: TimerViewModel.preview(state: .preparation))
}

@available(iOS 17.0, *)
#Preview("Running") {
    TimerView(viewModel: TimerViewModel.preview(state: .running))
}

@available(iOS 17.0, *)
#Preview("Completed") {
    TimerView(viewModel: TimerViewModel.preview(state: .completed))
}

@available(iOS 17.0, *)
#Preview("iPhone SE (small)", traits: .fixedLayout(width: 375, height: 667)) {
    TimerView()
}

@available(iOS 17.0, *)
#Preview("iPhone 15 (standard)", traits: .fixedLayout(width: 393, height: 852)) {
    TimerView()
}
#endif

@available(iOS 17.0, *)
#Preview("iPhone 15 Pro Max (large)", traits: .fixedLayout(width: 430, height: 932)) {
    TimerView()
}
