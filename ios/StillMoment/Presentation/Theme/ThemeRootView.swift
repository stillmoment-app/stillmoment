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

    /// Tabbar-Hintergrund nach Handover (shared-094).
    ///
    /// Durchgehende, opake Bar (kein iOS-26-Pill) — passend zur App-Philosophie
    /// und vermeidet den iOS-26-Scroll-Edge-Effekt, bei dem Content unter
    /// transparenten Bars durchschimmern wuerde.
    private var tabBarTint: Color {
        self.resolvedColors.tabBarBackground
    }

    // MARK: - Tab Bar Appearance

    /// Konfiguriert `UITabBarAppearance` mit opakem Hintergrund in unserem
    /// warmen Tint und setzt die Item-Tints (aktiv = Akzent, inaktiv =
    /// textSecondary). Sowohl `standardAppearance` als auch `scrollEdgeAppearance`
    /// werden gesetzt — auf iOS 18 wechselt das System sonst auf das hellgrau-
    /// weisse Standard-Material, sobald Content die Tabbar beruehrt.
    /// `UIAppearance` wirkt auf neue Instanzen; `.id(resolvedColors)` erzwingt
    /// den Neuaufbau bei Theme-Wechsel.
    private static func applyTabBarAppearance(_ colors: ThemeColors) {
        let interactive = UIColor(colors.interactive)
        let textSecondary = UIColor(colors.textSecondary).withAlphaComponent(0.6)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(colors.tabBarBackground)

        for itemAppearance in [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ] {
            itemAppearance.normal.iconColor = textSecondary
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: textSecondary]
            itemAppearance.selected.iconColor = interactive
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: interactive]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = interactive
        UITabBar.appearance().unselectedItemTintColor = textSecondary
    }
}
