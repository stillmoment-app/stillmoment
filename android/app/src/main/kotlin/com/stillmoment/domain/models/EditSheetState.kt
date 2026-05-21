package com.stillmoment.domain.models

/**
 * Manages state and validation logic for editing guided meditation metadata.
 *
 * This data class extracts testable business logic from the UI layer,
 * enabling unit testing without Compose dependencies.
 *
 * Usage:
 * ```kotlin
 * var state = EditSheetState.fromMeditation(meditation)
 * state = state.copy(editedTeacher = "New Teacher")
 * if (state.isValid && state.hasChanges) {
 *     val updated = state.applyChanges()
 * }
 * ```
 */
data class EditSheetState(
    /** The original meditation being edited */
    val originalMeditation: GuidedMeditation,
    /** Current edited teacher value */
    val editedTeacher: String,
    /** Current edited name value */
    val editedName: String
) {
    /**
     * Whether changes have been made compared to original values.
     */
    val hasChanges: Boolean
        get() =
            editedTeacher != originalMeditation.teacher ||
                editedName != originalMeditation.name

    /**
     * Whether the current values are valid for saving.
     *
     * Both teacher and name must be non-empty after trimming whitespace.
     */
    val isValid: Boolean
        get() =
            editedTeacher.trim().isNotEmpty() &&
                editedName.trim().isNotEmpty()

    /**
     * Creates an updated meditation with the edited values.
     *
     * Values are trimmed; the result is written directly to `teacher` / `name`.
     *
     * @return Updated meditation with applied changes
     */
    fun applyChanges(): GuidedMeditation {
        return originalMeditation.copy(
            teacher = editedTeacher.trim(),
            name = editedName.trim()
        )
    }

    companion object {
        /**
         * Creates an EditSheetState from a meditation.
         *
         * @param meditation The meditation to edit
         * @return New EditSheetState initialized with the meditation's values
         */
        fun fromMeditation(meditation: GuidedMeditation): EditSheetState {
            return EditSheetState(
                originalMeditation = meditation,
                editedTeacher = meditation.teacher,
                editedName = meditation.name
            )
        }
    }
}
