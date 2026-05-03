package com.stillmoment.presentation.ui.common

import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import com.stillmoment.domain.models.ColorTheme
import com.stillmoment.presentation.ui.theme.StillMomentTheme

/**
 * IDE-only previews of [DownloadProgressModal] across all themes and modes.
 *
 * Each preview is wrapped with the corresponding [ColorTheme] and dark/light flag
 * so the constellation accent and card surface match production output. Useful for
 * eyeballing the theme matrix without booting the app.
 */
@Preview(name = "Candlelight – Light", showBackground = true)
@Composable
private fun CandlelightLightPreview() {
    StillMomentTheme(colorTheme = ColorTheme.CANDLELIGHT, darkTheme = false) {
        DownloadProgressModal(onCancel = {})
    }
}

@Preview(name = "Candlelight – Dark", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun CandlelightDarkPreview() {
    StillMomentTheme(colorTheme = ColorTheme.CANDLELIGHT, darkTheme = true) {
        DownloadProgressModal(onCancel = {})
    }
}

@Preview(name = "Forest – Light", showBackground = true)
@Composable
private fun ForestLightPreview() {
    StillMomentTheme(colorTheme = ColorTheme.FOREST, darkTheme = false) {
        DownloadProgressModal(onCancel = {})
    }
}

@Preview(name = "Forest – Dark", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun ForestDarkPreview() {
    StillMomentTheme(colorTheme = ColorTheme.FOREST, darkTheme = true) {
        DownloadProgressModal(onCancel = {})
    }
}

@Preview(name = "Moon – Light", showBackground = true)
@Composable
private fun MoonLightPreview() {
    StillMomentTheme(colorTheme = ColorTheme.MOON, darkTheme = false) {
        DownloadProgressModal(onCancel = {})
    }
}

@Preview(name = "Moon – Dark", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MoonDarkPreview() {
    StillMomentTheme(colorTheme = ColorTheme.MOON, darkTheme = true) {
        DownloadProgressModal(onCancel = {})
    }
}
