package com.stillmoment

import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import com.stillmoment.data.FileOpenHandler
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.ColorTheme
import com.stillmoment.domain.repositories.CustomAudioRepository
import com.stillmoment.presentation.navigation.StillMomentNavHost
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import dagger.hilt.android.AndroidEntryPoint
import java.util.Locale
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Main Activity for Still Moment.
 * Entry point for the Compose UI.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @Inject
    lateinit var settingsDataStore: SettingsDataStore

    @Inject
    lateinit var fileOpenHandler: FileOpenHandler

    @Inject
    lateinit var customAudioRepository: CustomAudioRepository

    private val _pendingFileUri = MutableStateFlow<Uri?>(null)
    val pendingFileUri = _pendingFileUri.asStateFlow()

    /** Consume the pending file URI after processing */
    fun consumePendingFileUri() {
        _pendingFileUri.value = null
    }

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
        handleIncomingIntent(intent)

        setContent {
            val colorTheme by settingsDataStore.selectedThemeFlow
                .collectAsState(initial = ColorTheme.DEFAULT)
            val appearanceMode by settingsDataStore.appearanceModeFlow
                .collectAsState(initial = AppearanceMode.DEFAULT)
            val systemDarkTheme = isSystemInDarkTheme()
            val darkTheme = when (appearanceMode.isDark) {
                true -> true
                false -> false
                null -> systemDarkTheme
            }

            StillMomentTheme(colorTheme = colorTheme, darkTheme = darkTheme) {
                Box(modifier = Modifier.fillMaxSize()) {
                    WarmGradientBackground()
                    StillMomentNavHost(
                        settingsDataStore = settingsDataStore,
                        fileOpenHandler = fileOpenHandler,
                        customAudioRepository = customAudioRepository,
                        pendingFileUri = pendingFileUri,
                        onClearFileUri = ::consumePendingFileUri
                    )
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIncomingIntent(intent)
    }

    private fun handleIncomingIntent(intent: Intent?) {
        val uri: Uri? = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            else -> null
        }
        uri?.let { _pendingFileUri.value = it }
    }
}
