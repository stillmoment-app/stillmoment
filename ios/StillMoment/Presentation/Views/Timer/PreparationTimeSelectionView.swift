//
//  PreparationTimeSelectionView.swift
//  Still Moment
//
//  Presentation Layer - Preparation time editor (redesigned, shared-119).
//
//  Card-based layout aligned with `GongSelectionView` / `IntervalGongsEditorView`:
//  a master card with hourglass icon, title, purpose subtitle and a switch. When
//  enabled, an eyebrow-labelled "DAUER" section shows a large serif value hero
//  (chosen seconds + unit) above a slider card gridded to 5-second steps
//  (5...60s) with end labels. When disabled, a short helper text invites the user
//  to switch it on. Turning the switch off keeps the chosen duration, so
//  re-enabling restores it.
//
//  Selection is live — auto-save in PraxisSettingsViewModel persists every change.
//

import SwiftUI

/// Detail view for enabling and choosing the preparation time before a timer starts.
struct PreparationTimeSelectionView: View {
    // MARK: Lifecycle

    init(viewModel: PraxisSettingsViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    self.headerCard
                    if self.viewModel.preparationTimeEnabled {
                        self.durationSection
                    } else {
                        self.disabledHelper
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
        }
        .screenTitleBar("settings.preparationTime.title")
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme
    @ObservedObject private var viewModel: PraxisSettingsViewModel

    /// Fixed container diameter feeding `DisplayNumeral` (≈ 0.32 × 225 ≈ 72pt),
    /// matching the design's 72px serif value hero.
    private static let heroContainerDiameter: CGFloat = 225

    // MARK: Header card (toggle)

    private var headerCard: some View {
        HStack(spacing: 14) {
            self.headerIcon
            VStack(alignment: .leading, spacing: 3) {
                Text("settings.preparationTime.title", bundle: .main)
                    .textStyle(.body, color: \.textPrimary)
                Text(self.subtitleKey, bundle: .main)
                    .textStyle(.caption, color: \.textSecondary)
            }
            Spacer(minLength: 12)
            Toggle(isOn: self.$viewModel.preparationTimeEnabled) {
                EmptyView()
            }
            .labelsHidden()
            .themedToggle()
            .fixedSize()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .modifier(GongCardBackground())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("praxis.preparation.toggle")
        .accessibilityLabel(NSLocalizedString("accessibility.preparationTime", comment: ""))
        .accessibilityHint(NSLocalizedString("accessibility.preparationTime.hint", comment: ""))
    }

    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(self.theme.cardBackground)
                .overlay(Circle().strokeBorder(self.theme.cardBorder, lineWidth: 0.5))
            Image(systemName: "hourglass")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(self.theme.interactive)
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }

    private var subtitleKey: LocalizedStringKey {
        self.viewModel.preparationTimeEnabled
            ? "settings.preparationTime.subtitle.on"
            : "settings.preparationTime.subtitle.off"
    }

    // MARK: Duration section (enabled)

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("settings.preparationTime.duration")
                .textStyle(.eyebrow, color: \.textSecondary)
                .padding(.horizontal, 6)
                .padding(.top, 20)
            self.valueHero
            self.sliderCard
        }
    }

    private var valueHero: some View {
        VStack(spacing: 12) {
            DisplayNumeral(
                text: "\(self.viewModel.preparationTimeSeconds)",
                containerDiameter: Self.heroContainerDiameter
            )
            .foregroundColor(self.theme.textPrimary)
            Text("settings.preparationTime.unit.seconds", bundle: .main)
                .textStyle(.eyebrow, color: \.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .accessibilityHidden(true)
    }

    private var sliderCard: some View {
        VStack(spacing: 12) {
            ThemedSlider(
                value: self.sliderBinding,
                range: 5...60,
                step: 5
            )
            HStack {
                Text("settings.preparationTime.end.min", bundle: .main)
                    .textStyle(.caption, color: \.textSecondary)
                Spacer()
                Text("settings.preparationTime.end.max", bundle: .main)
                    .textStyle(.caption, color: \.textSecondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .modifier(GongCardBackground())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("praxis.preparation.slider")
        .accessibilityLabel(NSLocalizedString("accessibility.preparationTimeDuration", comment: ""))
        .accessibilityValue(String(
            format: NSLocalizedString("accessibility.preparation", comment: ""),
            self.viewModel.preparationTimeSeconds
        ))
        .accessibilityHint(NSLocalizedString("accessibility.preparationTimeDuration.hint", comment: ""))
    }

    /// Bridges the `Int` seconds field to the slider's `Double` value, snapping
    /// to the 5-second grid on write.
    private var sliderBinding: Binding<Double> {
        Binding(
            get: { Double(self.viewModel.preparationTimeSeconds) },
            set: { self.viewModel.preparationTimeSeconds = Int($0.rounded()) }
        )
    }

    // MARK: Disabled helper

    private var disabledHelper: some View {
        Text("settings.preparationTime.helper")
            .textStyle(.body, color: \.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Preparation Time Selection") {
    NavigationStack {
        PreparationTimeSelectionView(
            viewModel: PraxisSettingsViewModel(praxis: .default) { _ in }
        )
    }
}
#endif
