package com.stillmoment.domain.models

/**
 * Represents the main navigation tabs in the app.
 * Single source of truth for tab routes used by both navigation and persistence.
 *
 * @property route The navigation route string for this tab
 */
enum class AppTab(val route: String) {
    TIMER("timerGraph"),
    LIBRARY("library");

    companion object {
        /** Default tab shown on first app launch */
        val DEFAULT = TIMER

        /**
         * Parse a route string to AppTab, returning DEFAULT for unknown routes.
         */
        fun fromRoute(route: String?): AppTab =
            entries.find { it.route == route } ?: DEFAULT
    }
}
