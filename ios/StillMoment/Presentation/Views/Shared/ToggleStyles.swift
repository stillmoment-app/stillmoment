//
//  ToggleStyles.swift
//  Still Moment
//
//  Presentation Layer - Custom Toggle Styles
//
//  WCAG SC 1.4.11: System-grey off-track has only ~1.3:1 contrast against
//  cardBackground in light themes. This custom ToggleStyle uses the semantic
//  `controlTrack` color which guarantees >= 3:1 contrast.
//

import SwiftUI
import UIKit

/// Namespace for toggle styles
enum ToggleStyles {}

extension ToggleStyles {
    /// Themed toggle with `interactive` on-track and `controlTrack` off-track.
    struct Themed: ToggleStyle {
        let interactiveColor: Color
        let controlTrackColor: Color

        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label
                Spacer()
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(configuration.isOn ? self.interactiveColor : self.controlTrackColor)
                        .frame(width: 51, height: 31)
                    Circle()
                        .fill(.white)
                        .frame(width: 27, height: 27)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .padding(2)
                }
                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

// MARK: - ViewModifier Bridge

private struct ThemedToggleModifier: ViewModifier {
    @Environment(\.themeColors)
    private var theme

    func body(content: Content) -> some View {
        content.toggleStyle(
            ToggleStyles.Themed(
                interactiveColor: self.theme.interactive,
                controlTrackColor: self.theme.controlTrack
            )
        )
    }
}

// MARK: - View Extension

extension View {
    /// Apply themed toggle style with WCAG-compliant track colors
    func themedToggle() -> some View {
        modifier(ThemedToggleModifier())
    }
}
