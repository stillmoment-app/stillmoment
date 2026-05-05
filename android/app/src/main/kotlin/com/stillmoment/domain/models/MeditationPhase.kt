package com.stillmoment.domain.models

/**
 * Visuelle Phase einer Meditation (Timer oder Player).
 *
 * Layout-Phase, kein Audio-Zustand: Pause des Players oder Loading bleiben
 * [Playing], weil sich der Atemkreis visuell identisch verhaelt
 * (Bogen friert ein, Atem laeuft weiter). Nur die Pre-Roll-Phase
 * zeigt ein anderes Inneres.
 */
enum class MeditationPhase {
    PreRoll,
    Playing
}
