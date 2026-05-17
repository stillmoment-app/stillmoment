//
//  ButtonStyles.swift
//  Still Moment
//
//  Presentation Layer - Custom Button Styles
//

import SwiftUI

// MARK: - Design System Constants

extension CGFloat {
    /// Corner radius for primary buttons (pill-shaped)
    static let buttonCornerRadiusPrimary: CGFloat = 28

    /// Corner radius for secondary buttons and inline actions
    static let buttonCornerRadiusSecondary: CGFloat = 20
}

/// Namespace for button styles
enum ButtonStyles {}

extension ButtonStyles {
    /// Primary button style — plastic capsule with vertical gradient + inner
    /// highlight rim + warm drop shadow (shared-094 Kerzenschein 2.0).
    struct WarmPrimary: ButtonStyle {
        let colors: ThemeColors

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .textStyle(.bodyEmphasis, color: \.textOnInteractive)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    self.colors.playGradientTop,
                                    self.colors.playGradientBot
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            // Inner highlight rim — 1pt linear gradient at top
                            // edge, fading downward.
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.22),
                                            Color.white.opacity(0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: self.colors.playGradientBot.opacity(0.35),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                )
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }

    /// Glas-Pille im KS-2.0-Vokabular (shared-097). Halbtransparenter
    /// `ultraThinMaterial`-Hintergrund mit warm-getoentem Overlay, dezenter
    /// Akzent-Border, Akzent-Schrift. Selbe Behandlung wie der Pause-Button
    /// im Player (`GlassPauseButton`) — Background-Alpha gleich, Border-Alpha
    /// einen Tick hoeher (0.50 statt 0.40) damit die Pille als Tap-Target liest.
    struct WarmGlass: ButtonStyle {
        let colors: ThemeColors
        let colorScheme: ColorScheme

        func makeBody(configuration: Configuration) -> some View {
            let isDark = self.colorScheme == .dark
            let tint = isDark
                ? Color(red: 15 / 255, green: 8 / 255, blue: 5 / 255).opacity(0.55)
                : Color(red: 255 / 255, green: 246 / 255, blue: 230 / 255).opacity(0.55)
            let borderOpacity = isDark ? 0.50 : 0.55

            return configuration.label
                .textStyle(.bodyEmphasis, color: \.interactive)
                .padding(.horizontal, 44)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .background(
                    Capsule()
                        .fill(tint)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(self.colors.interactive.opacity(borderOpacity), lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }

    /// Secondary button style with soft sand background
    struct WarmSecondary: ButtonStyle {
        let colors: ThemeColors

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .textStyle(.body, color: \.textPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: .buttonCornerRadiusSecondary)
                        .fill(self.colors.backgroundSecondary.opacity(.opacitySecondary))
                )
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}

// MARK: - ViewModifier Bridge

private struct WarmPrimaryButtonModifier: ViewModifier {
    @Environment(\.themeColors)
    private var theme

    func body(content: Content) -> some View {
        content.buttonStyle(ButtonStyles.WarmPrimary(colors: self.theme))
    }
}

private struct WarmSecondaryButtonModifier: ViewModifier {
    @Environment(\.themeColors)
    private var theme

    func body(content: Content) -> some View {
        content.buttonStyle(ButtonStyles.WarmSecondary(colors: self.theme))
    }
}

private struct WarmGlassButtonModifier: ViewModifier {
    @Environment(\.themeColors)
    private var theme

    @Environment(\.colorScheme)
    private var colorScheme

    func body(content: Content) -> some View {
        content.buttonStyle(ButtonStyles.WarmGlass(
            colors: self.theme,
            colorScheme: self.colorScheme
        ))
    }
}

// MARK: - View Extensions

extension View {
    /// Apply warm primary button style
    func warmPrimaryButton() -> some View {
        modifier(WarmPrimaryButtonModifier())
    }

    /// Apply warm secondary button style
    func warmSecondaryButton() -> some View {
        modifier(WarmSecondaryButtonModifier())
    }

    /// Apply warm glass pill button style (KS 2.0)
    func warmGlassButton() -> some View {
        modifier(WarmGlassButtonModifier())
    }
}
