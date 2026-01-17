package com.stillmoment.screenshots

import android.graphics.Bitmap
import androidx.test.platform.app.InstrumentationRegistry
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import tools.fastlane.screengrab.ScreenshotCallback

/**
 * Custom ScreenshotCallback that writes screenshots without timestamps.
 *
 * Writes to: /data/data/<package>/files/<package>/screengrab/<locale>/images/screenshots/<name>.png
 *
 * Screengrab pulls these to: fastlane/metadata/android/<locale>/images/screenshots/
 * Fastfile then renames to: fastlane/metadata/android/<locale>/images/phoneScreenshots/
 * (Supply expects phoneScreenshots/ for Play Store upload)
 *
 * Key difference from default Screengrab behavior:
 * - No timestamp suffix (01_TimerIdle.png instead of 01_TimerIdle_1234567890.png)
 */
class PlayStoreScreenshotCallback : ScreenshotCallback {

    override fun screenshotCaptured(screenshotName: String, screenshot: Bitmap) {
        val context = InstrumentationRegistry.getInstrumentation().targetContext

        // Get locale from Screengrab's instrumentation argument (not system default)
        // Screengrab passes: -e testLocale en-US (or de-DE)
        val arguments = InstrumentationRegistry.getArguments()
        val locale = arguments.getString("testLocale") ?: "en-US"

        // Write to Screengrab's expected internal storage location
        // Screengrab pulls from: <filesDir>/<packageName>/screengrab/<locale>/images/screenshots/
        val packageName = context.packageName
        val screenshotsDir = File(
            context.filesDir,
            "$packageName/screengrab/$locale/images/screenshots"
        )
        screenshotsDir.mkdirs()

        // Write without timestamp - Supply expects clean filenames
        val file = File(screenshotsDir, "$screenshotName.png")
        BufferedOutputStream(FileOutputStream(file)).use { outputStream ->
            screenshot.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        }
    }
}
