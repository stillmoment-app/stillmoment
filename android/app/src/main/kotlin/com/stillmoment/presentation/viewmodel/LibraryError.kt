package com.stillmoment.presentation.viewmodel

/**
 * UI-level error types emitted by [GuidedMeditationsListViewModel] for the
 * library/import flows. The composable layer resolves each case to a localized
 * string via `stringResource(...)`.
 *
 * Keeping these as a sealed class (instead of raw strings) means the ViewModel
 * never has to know about Android resources — the UI owns the translation.
 */
sealed class LibraryError {
    /** The selected file is already in the library (same filename present). */
    data object AlreadyImported : LibraryError()

    /** The selected file is not a supported audio format. */
    data object UnsupportedFormat : LibraryError()

    /** Import failed for any other reason (IO, corrupted metadata, copy failure). */
    data object ImportFailed : LibraryError()
}
