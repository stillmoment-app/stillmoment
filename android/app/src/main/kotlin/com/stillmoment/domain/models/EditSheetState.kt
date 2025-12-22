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
     *
     * Compares against the original teacher/name (not effective values),
     * since customTeacher/customName should only be set when different from original.
     */
    val hasChanges: Boolean
        get() = editedTeacher != originalMeditation.teacher ||
                editedName != originalMeditation.name

    /**
     * Whether the current values are valid for saving.
     *
     * Both teacher and name must be non-empty after trimming whitespace.
     */
    val isValid: Boolean
        get() = editedTeacher.trim().isNotEmpty() &&
                editedName.trim().isNotEmpty()

    /**
     * Creates an updated meditation with the edited values.
     *
     * Only sets customTeacher/customName if values differ from original.
     * If the edited value matches the original, custom fields are set to null.
     *
     * @return Updated meditation with applied changes
     */
    fun applyChanges(): GuidedMeditation {
        return originalMeditation.copy(
            customTeacher = editedTeacher.takeIf {
                it.isNotBlank() && it != originalMeditation.teacher
            },
            customName = editedName.takeIf {
                it.isNotBlank() && it != originalMeditation.name
            }
        )
    }

    companion object {
        /**
         * Creates an EditSheetState from a meditation.
         *
         * Initializes edited values with effective values (custom if set, otherwise original).
         *
         * @param meditation The meditation to edit
         * @return New EditSheetState initialized with the meditation's values
         */
        fun fromMeditation(meditation: GuidedMeditation): EditSheetState {
            return EditSheetState(
                originalMeditation = meditation,
                editedTeacher = meditation.effectiveTeacher,
                editedName = meditation.effectiveName
            )
        }
    }
}
