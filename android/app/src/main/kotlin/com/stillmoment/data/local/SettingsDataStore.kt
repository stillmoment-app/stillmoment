package com.stillmoment.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.stillmoment.domain.models.AppTab
import com.stillmoment.domain.models.AppearanceMode
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

// Extension property for the app-level "settings" DataStore.
//
// Visibility is `internal` (not `private`) so [com.stillmoment.data.migration.AttunementCleanupMigration]
// can share the SAME DataStore instance via this property delegate. Defining a second
// `preferencesDataStore(name = "settings")` in another file would create a second
// `DataStoreImpl` pointing at the same `settings.preferences_pb` file and crash with
// `IllegalStateException: There are multiple DataStores active for the same file` on first read.
internal val Context.appSettingsDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "settings"
)

/**
 * DataStore for app-level settings (tab, appearance).
 * Timer-related settings are persisted via PraxisDataStore.
 *
 * The legacy `selected_theme` preference (shared-093) is intentionally not read
 * anywhere — bytes remain in `settings.preferences_pb` for users who upgrade
 * from a multi-theme version and are silently ignored.
 */
@Singleton
class SettingsDataStore
@Inject
constructor(
    @ApplicationContext private val context: Context
) {
    private object Keys {
        val SELECTED_TAB = stringPreferencesKey("selected_tab")
        val APPEARANCE_MODE = stringPreferencesKey("appearance_mode")

        /**
         * shared-103: marks whether the one-shot migration that folds
         * `customTeacher` / `customName` into `teacher` / `name` has run for the
         * current install. Idempotent — subsequent app starts skip the sweep.
         */
        val GUIDED_OVERRIDES_MIGRATED_V1 = booleanPreferencesKey("guided_meditations_override_migrated_v1")
    }

    /**
     * Flow for the selected tab.
     * Emits the saved tab or AppTab.DEFAULT for new installations.
     */
    val selectedTabFlow: Flow<AppTab> =
        context.appSettingsDataStore.data
            .map { preferences ->
                AppTab.fromRoute(preferences[Keys.SELECTED_TAB])
            }

    /**
     * Get the selected tab.
     * Use only during app initialization.
     */
    suspend fun getSelectedTab(): AppTab {
        return selectedTabFlow.first()
    }

    /**
     * Save the selected tab.
     */
    suspend fun setSelectedTab(tab: AppTab) {
        context.appSettingsDataStore.edit { preferences ->
            preferences[Keys.SELECTED_TAB] = tab.route
        }
    }

    /**
     * Flow for the selected appearance mode.
     * Emits the saved mode or AppearanceMode.DEFAULT (SYSTEM) for new installations.
     */
    val appearanceModeFlow: Flow<AppearanceMode> =
        context.appSettingsDataStore.data
            .map { preferences ->
                AppearanceMode.fromString(preferences[Keys.APPEARANCE_MODE])
            }

    /**
     * Get the selected appearance mode.
     */
    suspend fun getAppearanceMode(): AppearanceMode {
        return appearanceModeFlow.first()
    }

    /**
     * Save the selected appearance mode.
     */
    suspend fun setAppearanceMode(mode: AppearanceMode) {
        context.appSettingsDataStore.edit { preferences ->
            preferences[Keys.APPEARANCE_MODE] = mode.name
        }
    }

    /**
     * Returns whether the shared-103 override-cleanup migration already ran for
     * this install.
     */
    suspend fun isGuidedOverridesMigrated(): Boolean {
        return context.appSettingsDataStore.data
            .first()[Keys.GUIDED_OVERRIDES_MIGRATED_V1] == true
    }

    /**
     * Marks the shared-103 override-cleanup migration as complete.
     */
    suspend fun markGuidedOverridesMigrated() {
        context.appSettingsDataStore.edit { preferences ->
            preferences[Keys.GUIDED_OVERRIDES_MIGRATED_V1] = true
        }
    }
}
