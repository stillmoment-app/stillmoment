//
//  MeditationPhase.swift
//  Still Moment
//
//  Application Layer — visuelle Phase einer Meditation, geteilt zwischen
//  Timer (`TimerViewModel`) und Player (`GuidedMeditationPlayerViewModel`).
//

import Foundation

/// Visuelle Phase einer Meditation (Timer oder Player).
///
/// Layout-Phase, kein Audio-Zustand: Pause des Players oder Loading bleiben
/// `.playing`, weil sich der Atemkreis visuell identisch verhaelt
/// (Bogen friert ein, Atem laeuft weiter). Nur die Pre-Roll-Phase
/// zeigt ein anderes Inneres.
enum MeditationPhase: Equatable {
    case preRoll
    case playing
}
