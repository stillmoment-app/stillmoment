package com.stillmoment.screenshots

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.test.platform.app.InstrumentationRegistry
import com.stillmoment.data.local.GuidedMeditationDataStore
import com.stillmoment.domain.models.GuidedMeditation
import java.io.File
import java.util.UUID
import kotlinx.coroutines.runBlocking

/**
 * Test fixture definition matching iOS TestFixtureSeeder.
 */
private data class TestFixture(
    val assetName: String,
    val fileName: String,
    val duration: Long,
    val teacher: String,
    val name: String
)

/**
 * Seeds the meditation library with test fixtures for screenshot automation.
 *
 * This seeder provides pre-defined meditation entries that match the iOS
 * screenshot fixtures, ensuring consistent screenshots across platforms.
 *
 * Test fixtures are copied from androidTest assets to app-internal storage,
 * creating GuidedMeditation entries with valid file:// URIs.
 *
 * Usage in tests:
 * ```
 * @Inject lateinit var dataStore: GuidedMeditationDataStore
 *
 * @Before
 * fun setup() {
 *     hiltRule.inject()
 *     TestFixtureSeeder.seed(dataStore)
 *     // ... launch activity
 * }
 * ```
 */
object TestFixtureSeeder {
    private const val TAG = "TestFixtureSeeder"
    private const val MEDITATIONS_DIR = "meditations"

    /**
     * Test fixtures matching iOS TestFixtureSeeder for consistent screenshots.
     *
     * Each fixture maps to an MP3 file in androidTest/assets/testfixtures/
     */
    private val fixtures = listOf(
        TestFixture(
            assetName = "testfixtures/test-mindful-breathing.mp3",
            fileName = "mindful-breathing.mp3",
            duration = 453_000L, // 7:33 in milliseconds
            teacher = "Sarah Kornfield",
            name = "Mindful Breathing"
        ),
        TestFixture(
            assetName = "testfixtures/test-body-scan.mp3",
            fileName = "body-scan.mp3",
            duration = 942_000L, // 15:42
            teacher = "Sarah Kornfield",
            name = "Body Scan for Beginners"
        ),
        TestFixture(
            assetName = "testfixtures/test-loving-kindness.mp3",
            fileName = "loving-kindness.mp3",
            duration = 737_000L, // 12:17
            teacher = "Tara Goldstein",
            name = "Loving Kindness"
        ),
        TestFixture(
            assetName = "testfixtures/test-evening-wind-down.mp3",
            fileName = "evening-wind-down.mp3",
            duration = 1_145_000L, // 19:05
            teacher = "Tara Goldstein",
            name = "Evening Wind Down"
        ),
        TestFixture(
            assetName = "testfixtures/test-present-moment.mp3",
            fileName = "present-moment.mp3",
            duration = 1_548_000L, // 25:48
            teacher = "Jon Salzberg",
            name = "Present Moment Awareness"
        )
    )

    /**
     * Seeds test fixtures into the app's meditation library.
     *
     * Uses the app's DataStore instance (injected via Hilt) to avoid
     * multiple DataStore instances for the same file.
     *
     * @param dataStore The app's GuidedMeditationDataStore instance
     */
    fun seed(dataStore: GuidedMeditationDataStore) {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val testContext = instrumentation.context // Test APK context (for assets)
        val appContext = instrumentation.targetContext // App context (for storage)

        runBlocking {
            try {
                // Clear existing data first
                dataStore.clearAll()

                // Create and save meditations
                val meditations = createMeditations(testContext, appContext)
                for (meditation in meditations) {
                    dataStore.addMeditation(meditation)
                }
                Log.i(TAG, "Seeded ${meditations.size} test meditations for screenshots")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to seed test fixtures", e)
                throw e
            }
        }
    }

    /**
     * Clears all seeded test fixtures from the app's library.
     *
     * @param dataStore The app's GuidedMeditationDataStore instance
     */
    fun clear(dataStore: GuidedMeditationDataStore) {
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext

        runBlocking {
            try {
                // Clear DataStore
                dataStore.clearAll()

                // Delete copied files
                val meditationsDir = File(appContext.filesDir, MEDITATIONS_DIR)
                if (meditationsDir.exists()) {
                    meditationsDir.listFiles()?.forEach { file ->
                        file.delete()
                    }
                }

                Log.i(TAG, "Cleared test fixtures")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to clear test fixtures", e)
            }
        }
    }

    /**
     * Creates GuidedMeditation objects by copying assets to internal storage.
     */
    private fun createMeditations(testContext: Context, appContext: Context): List<GuidedMeditation> {
        val meditations = mutableListOf<GuidedMeditation>()

        // Create meditations directory
        val meditationsDir = File(appContext.filesDir, MEDITATIONS_DIR)
        if (!meditationsDir.exists()) {
            meditationsDir.mkdirs()
        }

        for (fixture in fixtures) {
            try {
                // Copy asset to internal storage
                val meditationId = UUID.randomUUID().toString()
                val localFileName = "$meditationId.mp3"
                val destFile = File(meditationsDir, localFileName)

                testContext.assets.open(fixture.assetName).use { input ->
                    destFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }

                // Create meditation with file:// URI
                val fileUri = Uri.fromFile(destFile).toString()
                val meditation = GuidedMeditation(
                    id = meditationId,
                    fileUri = fileUri,
                    fileName = fixture.fileName,
                    duration = fixture.duration,
                    teacher = fixture.teacher,
                    name = fixture.name
                )

                meditations.add(meditation)
                Log.d(TAG, "Created fixture: ${fixture.name} -> $fileUri")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to create fixture: ${fixture.name}", e)
            }
        }

        return meditations
    }
}
