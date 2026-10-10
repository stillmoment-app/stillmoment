package com.stillmoment

import android.content.Context
import android.content.res.Configuration
import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalResources
import androidx.test.platform.app.InstrumentationRegistry
import java.util.Locale

/**
 * The languages the app ships (`values/` = English, `values-de/` = German).
 *
 * UI tests that check user-visible text run once per language, so a stale or missing
 * translation fails in either language — independent of the emulator's system language.
 */
val SUPPORTED_TEST_LANGUAGES: List<String> = listOf("en", "de")

/**
 * App resources resolved for [languageTag], so expected texts come from the string
 * resources instead of hardcoded literals that silently drift from the UI.
 */
class LocalizedTestResources(languageTag: String) {
    val context: Context = run {
        val base = InstrumentationRegistry.getInstrumentation().targetContext
        val configuration = Configuration(base.resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(languageTag))
        base.createConfigurationContext(configuration)
    }

    fun string(@StringRes id: Int): String = context.getString(id)
}

/**
 * Renders [content] with [resources] as the composition's context, configuration and
 * resources, so `stringResource(...)` resolves in the test language.
 */
@Composable
fun LocalizedTestContent(resources: LocalizedTestResources, content: @Composable () -> Unit) {
    CompositionLocalProvider(
        LocalContext provides resources.context,
        LocalConfiguration provides resources.context.resources.configuration,
        LocalResources provides resources.context.resources,
        content = content
    )
}
