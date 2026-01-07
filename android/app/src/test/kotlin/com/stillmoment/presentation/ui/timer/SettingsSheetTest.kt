package com.stillmoment.presentation.ui.timer

import app.cash.paparazzi.DeviceConfig
import app.cash.paparazzi.Paparazzi
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import org.junit.Rule
import org.junit.Test

/**
 * Paparazzi screenshot tests for SettingsSheet.
 * Verifies the Card-based layout renders correctly.
 *
 * Run: ./gradlew :app:recordPaparazziDebug --tests "*.SettingsSheetTest"
 * Verify: ./gradlew :app:verifyPaparazziDebug --tests "*.SettingsSheetTest"
 */
class SettingsSheetTest {
    @get:Rule
    val paparazzi = Paparazzi(
        deviceConfig = DeviceConfig.PIXEL_6_PRO.copy(locale = "en"),
        theme = "android:Theme.Material.Light.NoActionBar"
    )

    // MARK: - Default State

    @Test
    fun settingsSheet_defaultState() {
        paparazzi.snapshot(name = "settings-default") {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChange = {},
                    onDismiss = {}
                )
            }
        }
    }

    // MARK: - Preparation Time Enabled

    @Test
    fun settingsSheet_preparationTimeEnabled() {
        paparazzi.snapshot(name = "settings-preparation-enabled") {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.create(
                        preparationTimeEnabled = true,
                        preparationTimeSeconds = 10
                    ),
                    onSettingsChange = {},
                    onDismiss = {}
                )
            }
        }
    }

    // MARK: - Interval Gongs Enabled

    @Test
    fun settingsSheet_intervalGongsEnabled() {
        paparazzi.snapshot(name = "settings-intervals-enabled") {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.create(
                        intervalGongsEnabled = true,
                        intervalMinutes = 5
                    ),
                    onSettingsChange = {},
                    onDismiss = {}
                )
            }
        }
    }

    // MARK: - All Options Enabled

    @Test
    fun settingsSheet_allOptionsEnabled() {
        paparazzi.snapshot(name = "settings-all-enabled") {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.create(
                        preparationTimeEnabled = true,
                        preparationTimeSeconds = 15,
                        intervalGongsEnabled = true,
                        intervalMinutes = 5,
                        backgroundSoundId = "forest"
                    ),
                    onSettingsChange = {},
                    onDismiss = {}
                )
            }
        }
    }

    // MARK: - German Locale

    @Test
    fun settingsSheet_germanLocale() {
        paparazzi.unsafeUpdateConfig(
            deviceConfig = DeviceConfig.PIXEL_6_PRO.copy(locale = "de")
        )
        paparazzi.snapshot(name = "settings-german") {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.create(
                        preparationTimeEnabled = true,
                        preparationTimeSeconds = 10,
                        intervalGongsEnabled = true,
                        intervalMinutes = 5
                    ),
                    onSettingsChange = {},
                    onDismiss = {}
                )
            }
        }
    }
}
