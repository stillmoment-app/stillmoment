package com.stillmoment.presentation.viewmodel

/**
 * UI-level error types emitted by [TimerViewModel]. The composable layer resolves
 * each case to a localized string via `stringResource(...)` (same pattern as
 * [LibraryError]), so the ViewModel never has to know about Android resources.
 */
sealed class TimerError {
    /**
     * A sound of the timer session (audio session, background sound, start, interval
     * or end gong) could not be played. One calm message for every sound: the user
     * cannot act differently per sound, and technical details stay in the log.
     */
    data object SoundFailed : TimerError()
}
