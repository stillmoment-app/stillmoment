package com.stillmoment.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.stillmoment.domain.models.AppTab
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.ColorTheme
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

// Extension property for DataStore
private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(
    name = "settings"
)

/**
 * DataStore for app-level settings (tab, theme, appearance).
 * Timer-related settings are persisted via PraxisDataStore.
 */
@Singleton
class SettingsDataStore
@Inject
constructor(
    @ApplicationContext private val context: Context
) {
    private object Keys {
        val SELECTED_TAB = stringPreferencesKey("selected_tab")
        val SELECTED_THEME = stringPreferencesKey("selected_theme")
        val APPEARANCE_MODE = stringPreferencesKey("appearance_mode")
    }

    /**
     * Flow for the selected tab.
     * Emits the saved tab or AppTab.DEFAULT for new installations.
     */
    val selectedTabFlow: Flow<AppTab> =
        context.dataStore.data
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
        context.dataStore.edit { preferences ->
            preferences[Keys.SELECTED_TAB] = tab.route
        }
    }

    /**
     * Flow for the selected color theme.
     * Emits the saved theme or ColorTheme.DEFAULT for new installations.
     */
    val selectedThemeFlow: Flow<ColorTheme> =
        context.dataStore.data
            .map { preferences ->
                ColorTheme.fromString(preferences[Keys.SELECTED_THEME])
            }

    /**
     * Get the selected color theme.
     */
    suspend fun getSelectedTheme(): ColorTheme {
        return selectedThemeFlow.first()
    }

    /**
     * Save the selected color theme.
     */
    suspend fun setSelectedTheme(theme: ColorTheme) {
        context.dataStore.edit { preferences ->
            preferences[Keys.SELECTED_THEME] = theme.name
        }
    }

    /**
     * Flow for the selected appearance mode.
     * Emits the saved mode or AppearanceMode.DEFAULT (SYSTEM) for new installations.
     */
    val appearanceModeFlow: Flow<AppearanceMode> =
        context.dataStore.data
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
        context.dataStore.edit { preferences ->
            preferences[Keys.APPEARANCE_MODE] = mode.name
        }
    }
}
