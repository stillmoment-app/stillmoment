package com.stillmoment.domain.models

/**
 * Mode for the meditation edit sheet (shared-103).
 *
 * The sheet is structurally identical in both modes; only the save-button
 * label and the autofocus rule differ. Persistence (Add vs. Update) is
 * handled by the caller via the `onSave` closure.
 */
enum class EditSheetMode {
    /** Import flow — the meditation is a draft and has not been persisted yet. */
    IMPORT,

    /** Edit flow — the meditation already exists in the library. */
    EDIT
}
