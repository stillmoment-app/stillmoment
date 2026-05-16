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
            .toolbarBackground(self.tabBarTint, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .preferredColorScheme(self.themeManager.preferredColorScheme)
            .id(self.resolvedColors)
            .onChange(of: self.resolvedColors) { colors in
                Self.applyTabBarAppearance(colors)
            }
            .onAppear {
                Self.applyTabBarAppearance(self.resolvedColors)
            }
    }

    /// Tabbar-Hintergrund: warmer Tint nach Handover (shared-094).
    ///
    /// Durchgehende, opake Bar (kein iOS-26-Pill) — passend zur App-Philosophie
    /// und vermeidet den iOS-26-Scroll-Edge-Effekt, bei dem Content unter
    /// transparenten Bars durchschimmern wuerde.
    private var tabBarTint: Color {
        Color(Self.tabBarTintColor(for: self.resolvedColors))
    }

    // MARK: - Tab Bar Appearance

    /// Setzt nur `tintColor` + `unselectedItemTintColor` (Handover-Fallback).
    /// `UIAppearance` wirkt auf neue Instanzen; `.id(resolvedColors)` erzwingt
    /// den Neuaufbau bei Theme-Wechsel.
    private static func applyTabBarAppearance(_ colors: ThemeColors) {
        let interactive = UIColor(colors.interactive)
        let textSecondary = UIColor(colors.textSecondary).withAlphaComponent(0.6)
        UITabBar.appearance().tintColor = interactive
        UITabBar.appearance().unselectedItemTintColor = textSecondary
    }

    private static func tabBarTintColor(for colors: ThemeColors) -> UIColor {
        // Werte direkt aus dem Handover (shared-094) — bewusst hardcoded und
        // nicht ueber Theme-Tokens, weil die Tabbar-Material-Werte vom Theme
        // entkoppelt sind (sie sind eine Material-Logik, keine Farbrolle).
        if self.isEffectivelyDark(colors) {
            UIColor(red: 46 / 255, green: 33 / 255, blue: 26 / 255, alpha: 1.0)
        } else {
            UIColor(red: 255 / 255, green: 246 / 255, blue: 230 / 255, alpha: 1.0)
        }
    }

    private static func isEffectivelyDark(_ colors: ThemeColors) -> Bool {
        let uiColor = UIColor(colors.backgroundPrimary)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red + green + blue) / 3.0 < 0.3
    }
}
