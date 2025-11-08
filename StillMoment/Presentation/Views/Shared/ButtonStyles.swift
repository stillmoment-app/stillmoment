//
//  ButtonStyles.swift
//  Still Moment
//
//  Presentation Layer - Custom Button Styles
//

import SwiftUI

/// Namespace for button styles
enum ButtonStyles {}

extension ButtonStyles {
    /// Primary button style with terracotta background and shadow
    struct WarmPrimary: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.terracotta)
                        .shadow(
                            color: Color.terracotta.opacity(0.3),
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
                .foregroundColor(.warmBlack)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.warmSand.opacity(0.5))
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
