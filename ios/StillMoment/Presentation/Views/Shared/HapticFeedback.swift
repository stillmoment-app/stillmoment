//
//  HapticFeedback.swift
//  Still Moment
//
//  Presentation Layer — haptic feedback helpers
//

import UIKit

enum HapticFeedback {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
