package com.stillmoment

import android.content.Context
import android.content.res.Configuration
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.presentation.navigation.StillMomentNavHost
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import dagger.hilt.android.AndroidEntryPoint
import java.util.Locale
import javax.inject.Inject

/**
 * Main Activity for Still Moment.
 * Entry point for the Compose UI.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @Inject
    lateinit var settingsDataStore: SettingsDataStore

    /**
     * Applies Locale.getDefault() to the activity context.
     *
     * Used by screenshot tests: LocaleTestRule sets Locale.setDefault(),
     * then the test calls recreate() which triggers this method.
     * This ensures Compose stringResource() uses the correct locale.
     */
    override fun attachBaseContext(newBase: Context) {
        val locale = Locale.getDefault()
        val config = Configuration(newBase.resources.configuration)
        config.setLocale(locale)
        super.attachBaseContext(newBase.createConfigurationContext(config))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            StillMomentTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    StillMomentNavHost(settingsDataStore = settingsDataStore)
                }
            }
        }
    }
}
