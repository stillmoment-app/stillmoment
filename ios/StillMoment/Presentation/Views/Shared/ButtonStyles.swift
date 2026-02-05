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
    /// Primary button style with terracotta background and shadow
    struct WarmPrimary: ButtonStyle {
        let colors: ThemeColors

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(self.colors.textOnInteractive)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: .buttonCornerRadiusPrimary)
                        .fill(self.colors.interactive)
                        .shadow(
                            color: self.colors.interactive.opacity(.opacityShadow),
                            radius: 20,
                            x: 0,
                            y: 8
                        )
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
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(self.colors.textPrimary)
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
}
