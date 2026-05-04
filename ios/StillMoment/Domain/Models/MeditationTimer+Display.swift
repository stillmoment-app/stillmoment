//
//  MeditationTimer+Display.swift
//  Still Moment
//
//  Domain Model - Display computed properties for MeditationTimer
//

import Foundation

extension MeditationTimer {
    /// Whether currently in preparation phase
    var isPreparation: Bool {
        self.state == .preparation
    }

    /// Whether the timer is actively running (for UI display)
    /// Returns true during start gong, silent meditation and endGong phases
    /// (no visual difference between these phases per design — ring full, 00:00 during endGong)
    var isRunning: Bool {
        self.state == .running
            || self.state == .startGong || self.state == .endGong
    }

    /// Formatted time string (MM:SS or preparation seconds)
    var formattedTime: String {
        if self.isPreparation {
            return "\(self.remainingPreparationSeconds)"
        }
        let minutes = self.remainingSeconds / 60
        let seconds = self.remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
