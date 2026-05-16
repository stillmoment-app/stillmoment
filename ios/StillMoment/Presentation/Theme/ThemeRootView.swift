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
            .preferredColorScheme(self.themeManager.preferredColorScheme)
            .id(self.resolvedColors)
            .onChange(of: self.resolvedColors) { colors in
                Self.applyTabBarAppearance(colors)
            }
            .onAppear {
                Self.applyTabBarAppearance(self.resolvedColors)
            }
    }

    // MARK: - Tab Bar Appearance

    /// iOS-26-vertraegliche Tabbar-Konfiguration nach dem Handover-Fallback
    /// (shared-094): nur `tintColor` + `unselectedItemTintColor` setzen. Keine
    /// `selectionIndicatorImage`-Pille, kein eigener `backgroundEffect`, keine
    /// `toolbarBackground`-Ueberschreibung — das laesst die System-Pill-Geometrie
    /// in iOS 26 unbeschadet und die System-Animation greift wie vorgesehen.
    ///
    /// `UIAppearance` wirkt nur auf neue `UITabBar`-Instanzen. `ThemeRootView`
    /// erzwingt ueber `.id(resolvedColors)` einen Neuaufbau bei Theme-Wechsel.
    private static func applyTabBarAppearance(_ colors: ThemeColors) {
        let interactive = UIColor(colors.interactive)
        let textSecondary = UIColor(colors.textSecondary).withAlphaComponent(0.6)
        UITabBar.appearance().tintColor = interactive
        UITabBar.appearance().unselectedItemTintColor = textSecondary
    }
}
