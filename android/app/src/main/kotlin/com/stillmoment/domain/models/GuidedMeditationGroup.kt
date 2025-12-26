package com.stillmoment.domain.models

/**
 * Represents a group of guided meditations by the same teacher.
 *
 * Used for displaying meditations grouped by teacher in the library UI.
 */
data class GuidedMeditationGroup(
    /** Teacher name for this group */
    val teacher: String,
    /** List of meditations by this teacher */
    val meditations: List<GuidedMeditation>
) {
    /** Number of meditations in this group */
    val count: Int
        get() = meditations.size
}

/**
 * Groups a list of guided meditations by their effective teacher name.
 *
 * @return List of GuidedMeditationGroup sorted alphabetically by teacher name.
 *         Meditations within each group are sorted alphabetically by name.
 */
fun List<GuidedMeditation>.groupByTeacher(): List<GuidedMeditationGroup> {
    return groupBy { it.effectiveTeacher }
        .map { (teacher, meditations) ->
            GuidedMeditationGroup(
                teacher = teacher,
                meditations = meditations.sortedBy { it.effectiveName }
            )
        }
        .sortedBy { it.teacher }
}
