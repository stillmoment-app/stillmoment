//
//  ThemeRootView.swift
//  Still Moment
//
//  Presentation Layer - Root view that resolves and injects theme colors into the environment.
//

import SwiftUI

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
    }
}
