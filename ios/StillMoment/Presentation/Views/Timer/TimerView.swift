//
//  TimerView.swift
//  Still Moment
//
//  Presentation Layer - Main Timer View
//

import SwiftUI

/// Main view for the meditation timer.
///
/// Idle screen shows the minute picker plus four tappable setting cards
/// (Vorbereitung · Hintergrund · Gong · Intervall) that
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
            guard pendingImport != nil
            else { return }
            self.openDetail(for: .background)
        }
    }

    private var content: some View {
        GeometryReader { geometry in
            let isCompactHeight = geometry.size.height < 700

            VStack(spacing: 0) {
                if self.viewModel.timerState == .idle {
                    self.idleLayout(geometry: geometry, isCompactHeight: isCompactHeight)
                } else {
                    self.sessionLayout(geometry: geometry)
                }

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
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @EnvironmentObject private var fileOpenHandler: FileOpenHandler
    @StateObject private var viewModel: TimerViewModel
    @State private var settingPath: [SettingDestination] = []

    private var isZenMode: Bool {
        self.viewModel.isZenMode
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

    // MARK: - Layouts

    private func idleLayout(geometry: GeometryProxy, isCompactHeight: Bool) -> some View {
        // Im idle-Zustand verteilt sich der Restraum so:
        // Top und unter Beginnen wachsen, der Spalt Liste→Beginnen
        // bleibt klein. Beginnen ist dadurch optisch der Liste
        // zugehoerig, der Inhalt rueckt vertikal zur Mitte.
        VStack(spacing: 0) {
            Spacer(minLength: 8)
                .frame(maxHeight: .infinity)

            self.idleScreen(geometry: geometry)

            Spacer(minLength: 16)
                .frame(maxHeight: isCompactHeight ? 24 : 36)

            self.controlButtons
                .padding(.horizontal)

            Spacer(minLength: 16)
                .frame(maxHeight: .infinity)
        }
    }

    private func sessionLayout(geometry: GeometryProxy) -> some View {
        // Session-Modus: BreathingCircle + Restzeit-Label vertikal zentriert.
        // Kein Begruessungs-Headline, kein Begin-Button.
        VStack(spacing: 0) {
            Spacer(minLength: 16)
                .frame(maxHeight: .infinity)

            self.timerDisplay(geometry: geometry)

            Spacer(minLength: 16)
                .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Idle Screen

    private func idleScreen(geometry: GeometryProxy) -> some View {
        let isCompactHeight = geometry.size.height < 700
        // Dial-Durchmesser: 180 px auf SE, 220 px auf grossen Geraeten.
        let dialDiameter: CGFloat = isCompactHeight ? 180 : 220
        // Section-Spacing: kompakter auf kleinen Geraeten, atmend auf grossen.
        // Atemkreis-zur-Liste bekommt deutlich mehr Atem als Headline-zum-Atemkreis,
        // damit Atemkreis und Liste sich visuell als getrennte Bloecke lesen.
        let headlineToDialSpacing: CGFloat = isCompactHeight ? 18 : 28
        let dialToListSpacing: CGFloat = isCompactHeight ? 32 : 72

        return VStack(spacing: 0) {
            Text("timer.idle.headline", bundle: .main)
                .themeFont(.sectionTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer(minLength: headlineToDialSpacing)
                .frame(maxHeight: headlineToDialSpacing)

            BreathDial(
                value: self.$viewModel.selectedMinutes,
                diameter: dialDiameter
            )

            Spacer(minLength: dialToListSpacing)
                .frame(maxHeight: dialToListSpacing)

            self.idleSettingsList(isCompactHeight: isCompactHeight)
                .padding(.horizontal, 24)
        }
    }

    private func idleSettingsList(isCompactHeight: Bool) -> some View {
        IdleSettingsList(
            preparation: self.idleListItem(
                labelKey: "settings.card.label.preparation",
                value: self.viewModel.preparationCardLabel,
                isOff: self.viewModel.preparationCardIsOff,
                identifier: "timer.row.preparation"
            ) { self.openDetail(for: .preparation) },
            gong: self.idleListItem(
                labelKey: "settings.card.label.gong",
                value: self.viewModel.gongCardLabel,
                isOff: self.viewModel.gongCardIsOff,
                identifier: "timer.row.gong"
            ) { self.openDetail(for: .gong) },
            interval: self.idleListItem(
                labelKey: "settings.card.label.interval",
                value: self.viewModel.intervalCardLabel,
                isOff: self.viewModel.intervalCardIsOff,
                identifier: "timer.row.interval"
            ) { self.openDetail(for: .interval) },
            background: self.idleListItem(
                labelKey: "settings.card.label.background",
                value: self.viewModel.backgroundCardLabel,
                isOff: self.viewModel.backgroundCardIsOff,
                identifier: "timer.row.background"
            ) { self.openDetail(for: .background) },
            isCompactHeight: isCompactHeight
        )
    }

    private func idleListItem(
        labelKey: String,
        value: String,
        isOff: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> IdleSettingsListItem {
        let label = NSLocalizedString(labelKey, comment: "")
        let accessibilityLabel = String(
            format: NSLocalizedString("accessibility.idleSettings.row", comment: ""),
            label,
            value
        )
        return IdleSettingsListItem(
            label: label,
            value: value,
            isOff: isOff,
            identifier: identifier,
            accessibilityLabel: accessibilityLabel,
            action: action
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
        let circleSize: CGFloat = isCompactHeight ? 240 : 280

        return VStack(spacing: 12) {
            BreathingCircleView(
                phase: self.viewModel.phase,
                progress: self.viewModel.progress,
                reduceMotion: self.reduceMotion,
                outerSize: circleSize
            ) {
                self.circleContent
            }

            self.bottomLabel
        }
        .animation(.easeInOut(duration: 0.4), value: self.viewModel.phase)
    }

    @ViewBuilder private var circleContent: some View {
        switch self.viewModel.phase {
        case .preRoll:
            VStack(spacing: 6) {
                Text("\(self.viewModel.remainingPreparationSeconds)")
                    .themeFont(.playerCountdown, size: 72)
                    .monospacedDigit()
                    .accessibilityIdentifier("timer.display.time")
                    .accessibilityLabel(String(
                        format: NSLocalizedString("accessibility.preparation", comment: ""),
                        self.viewModel.remainingPreparationSeconds
                    ))

                Text("guided_meditations.player.preroll.label")
                    .themeFont(.playerTimestamp)
                    .foregroundColor(self.theme.textSecondary)
            }
            .transition(.opacity)
        case .playing:
            EmptyView()
        }
    }

    @ViewBuilder private var bottomLabel: some View {
        switch self.viewModel.phase {
        case .preRoll:
            Text("guided_meditations.player.preroll.hint")
                .themeFont(.playerTimestamp)
                .foregroundColor(self.theme.textSecondary)
                .textCase(.uppercase)
                .transition(.opacity)
        case .playing:
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
            .accessibilityIdentifier("timer.display.time")
            .accessibilityLabel("guided_meditations.player.remainingTime")
            .accessibilityValue(self.accessibilityTimeValue)
            .transition(.opacity)
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
