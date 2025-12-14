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
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.textOnInteractive)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: .buttonCornerRadiusPrimary)
                        .fill(Color.interactive)
                        .shadow(
                            color: Color.interactive.opacity(.opacityShadow),
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
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: .buttonCornerRadiusSecondary)
                        .fill(Color.backgroundSecondary.opacity(.opacitySecondary))
                )
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply warm primary button style
    func warmPrimaryButton() -> some View {
        buttonStyle(ButtonStyles.WarmPrimary())
    }

    /// Apply warm secondary button style
    func warmSecondaryButton() -> some View {
        buttonStyle(ButtonStyles.WarmSecondary())
    }
}
