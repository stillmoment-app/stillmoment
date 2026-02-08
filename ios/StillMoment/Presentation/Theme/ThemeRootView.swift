//
//  ThemeRootView.swift
//  Still Moment
//
//  Presentation Layer - Root view that resolves and injects theme colors into the environment.
//

import SwiftUI
import UIKit

struct ThemeRootView<Content: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme)
    private var colorScheme

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var resolvedColors: ThemeColors {
        self.themeManager.resolvedColors(for: self.colorScheme)
    }

    var body: some View {
        self.content
            .environment(\.themeColors, self.resolvedColors)
            .tint(self.resolvedColors.interactive)
            .toolbarBackground(self.resolvedColors.backgroundSecondary, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .preferredColorScheme(self.themeManager.preferredColorScheme)
            .onAppear { self.configureUIKitAppearance() }
            .onChange(of: self.resolvedColors) { _ in
                self.configureUIKitAppearance()
            }
    }

    private func configureUIKitAppearance() {
        let normalColor = UIColor(self.resolvedColors.textPrimary)
        let selectedColor = UIColor(self.resolvedColors.textOnInteractive)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: normalColor],
            for: .normal
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: selectedColor],
            for: .selected
        )
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(self.resolvedColors.interactive)
        UISegmentedControl.appearance().backgroundColor = UIColor(self.resolvedColors.cardBackground)
        UISlider.appearance().maximumTrackTintColor = UIColor(self.resolvedColors.controlTrack)
    }
}
