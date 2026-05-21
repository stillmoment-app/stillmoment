package com.stillmoment.presentation.ui.common

import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import com.stillmoment.presentation.ui.theme.StillMomentTheme

/**
 * IDE-only previews of [DownloadProgressModal] in Light and Dark mode.
 *
 * Each preview is wrapped with the corresponding darkTheme flag so the
 * constellation accent and card surface match production output.
 */
@Preview(name = "Light", showBackground = true)
@Composable
private fun LightPreview() {
    StillMomentTheme(darkTheme = false) {
        DownloadProgressModal(onCancel = {})
    }
}

@Preview(name = "Dark", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun DarkPreview() {
    StillMomentTheme(darkTheme = true) {
        DownloadProgressModal(onCancel = {})
    }
}
