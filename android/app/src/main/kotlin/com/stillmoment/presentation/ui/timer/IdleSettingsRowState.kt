package com.stillmoment.presentation.ui.timer

import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.Praxis

/**
 * Pure helpers describing whether a row in the idle settings list (shared-089)
 * should render in the dimmed "off" state. The label-Strings live in the
 * Composable layer (`stringResource`); these flags can be tested without
 * Compose.
 *
 * Pendant zu iOS `TimerViewModel+ConfigurationDescription.swift`.
 */
object IdleSettingsRowState {
    /** Preparation row dims when preparation is disabled. */
    fun preparationIsOff(praxis: Praxis): Boolean = !praxis.preparationTimeEnabled

    /**
     * Gong row never dims — a gong is always selected. Exposed as a
     * [Praxis]-shaped function (instead of a constant) for symmetry with the
     * other `*IsOff` helpers, so the call-site doesn't need to special-case
     * gong rows.
     */
    @Suppress("UNUSED_PARAMETER", "FunctionOnlyReturningConstant")
    fun gongIsOff(praxis: Praxis): Boolean = false

    /** Interval row dims when interval gongs are disabled. */
    fun intervalIsOff(praxis: Praxis): Boolean = !praxis.intervalGongsEnabled

    /** Background row dims when "Stille" (silent) is selected. */
    fun backgroundIsOff(praxis: Praxis): Boolean = praxis.backgroundSoundId == BackgroundSound.SILENT_ID
}
