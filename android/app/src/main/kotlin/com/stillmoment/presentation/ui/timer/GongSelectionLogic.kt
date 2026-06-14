package com.stillmoment.presentation.ui.timer

import com.stillmoment.domain.models.GongSound

/**
 * Reine, testbare Layout-Entscheidungen fuer den Gong-Auswahl-Screen (shared-115).
 *
 * Frei von Compose, damit die Regeln ohne Rendering unit-getestet werden koennen.
 * 1:1 Pendant zu iOS' `GongSelectionLogic`.
 */
object GongSelectionLogic {
    /**
     * Die Lautstaerke-Karte erscheint fuer hoerbare Gongs und entfaellt bei der
     * Vibration (die keine Lautstaerke kennt und stattdessen einen Helper-Text zeigt).
     */
    fun isVolumeCardVisible(soundId: String): Boolean = soundId != GongSound.VIBRATION_ID
}
