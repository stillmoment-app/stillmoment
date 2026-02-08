//
//  ThemedSlider.swift
//  Still Moment
//
//  Presentation Layer - Pure SwiftUI slider with full theme color control.
//
//  Replaces UIKit-bridged Slider to avoid UIAppearance refresh issues
//  on theme or appearance changes. Both active and inactive track colors
//  respond to @Environment(\.themeColors) reactively.
//

import SwiftUI
import UIKit

/// A slider built entirely in SwiftUI, themed via `@Environment(\.themeColors)`.
///
/// Drop-in replacement for `Slider` that avoids UIKit's `UIAppearance` proxy,
/// which only applies to newly created instances and causes stale colors
/// after theme or light/dark mode changes.
struct ThemedSlider: View {
    @Environment(\.themeColors)
    private var theme

    @State private var isDragging = false
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double?
    var onEditingChanged: ((Bool) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - Self.thumbSize
            let fraction = self.clampedFraction
            let thumbCenterX = Self.thumbSize / 2 + trackWidth * fraction

            ZStack(alignment: .leading) {
                // Inactive track (full width)
                Capsule()
                    .fill(self.theme.controlTrack)
                    .frame(height: Self.trackHeight)

                // Active track (filled portion)
                Capsule()
                    .fill(self.theme.interactive)
                    .frame(width: max(thumbCenterX, Self.trackHeight), height: Self.trackHeight)

                // Thumb
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(.opacityShadow), radius: 2, y: 1)
                    .frame(width: Self.thumbSize, height: Self.thumbSize)
                    .offset(x: thumbCenterX - Self.thumbSize / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !self.isDragging {
                            self.isDragging = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        self.onEditingChanged?(true)
                        let newFraction = (gesture.location.x - Self.thumbSize / 2) / trackWidth
                        self.updateValue(fraction: Double(newFraction))
                    }
                    .onEnded { _ in
                        self.isDragging = false
                        self.onEditingChanged?(false)
                    }
            )
        }
        .frame(height: Self.touchTarget)
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { direction in
            let increment = self.step ?? (self.range.upperBound - self.range.lowerBound) / 10
            switch direction {
            case .increment:
                self.value = min(self.value + increment, self.range.upperBound)
            case .decrement:
                self.value = max(self.value - increment, self.range.lowerBound)
            @unknown default:
                break
            }
        }
    }

    // MARK: - Private

    private static let trackHeight: CGFloat = 4
    private static let thumbSize: CGFloat = 22
    private static let touchTarget: CGFloat = 44

    private var clampedFraction: CGFloat {
        guard self.range.upperBound > self.range.lowerBound
        else { return 0 }
        let raw = (self.value - self.range.lowerBound) / (self.range.upperBound - self.range.lowerBound)
        return CGFloat(min(max(raw, 0), 1))
    }

    private func updateValue(fraction: Double) {
        let clamped = min(max(fraction, 0), 1)
        var newValue = self.range.lowerBound + clamped * (self.range.upperBound - self.range.lowerBound)
        if let step {
            newValue = (newValue / step).rounded() * step
        }
        self.value = min(max(newValue, self.range.lowerBound), self.range.upperBound)
    }
}
