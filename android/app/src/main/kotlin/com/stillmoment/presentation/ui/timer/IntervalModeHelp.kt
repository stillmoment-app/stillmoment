package com.stillmoment.presentation.ui.timer

import androidx.annotation.PluralsRes
import com.stillmoment.R
import com.stillmoment.domain.models.IntervalMode

/**
 * The mode-help variant shown below the mode picker on the interval-gong editor
 * (shared-120). One variant per [IntervalMode]; each resolves to a plural-correct
 * string resource whose count (the interval minutes) drives the one/other form.
 */
enum class IntervalModeHelp {
    REPEATING,
    AFTER_START,
    BEFORE_END;

    /** The `<plurals>` resource carrying this variant's copy. */
    @get:PluralsRes
    val pluralsRes: Int
        get() = when (this) {
            REPEATING -> R.plurals.praxis_interval_gongs_mode_help_repeating
            AFTER_START -> R.plurals.praxis_interval_gongs_mode_help_after_start
            BEFORE_END -> R.plurals.praxis_interval_gongs_mode_help_before_end
        }
}

/**
 * Pure mapping from an [IntervalMode] to its [IntervalModeHelp] variant.
 *
 * Kept free of resource lookups so it is unit-testable without Android resources;
 * the resource id lives on [IntervalModeHelp.pluralsRes]. Mirrors iOS'
 * `IntervalMode.modeHelpKey`.
 */
fun IntervalMode.modeHelp(): IntervalModeHelp = when (this) {
    IntervalMode.REPEATING -> IntervalModeHelp.REPEATING
    IntervalMode.AFTER_START -> IntervalModeHelp.AFTER_START
    IntervalMode.BEFORE_END -> IntervalModeHelp.BEFORE_END
}
