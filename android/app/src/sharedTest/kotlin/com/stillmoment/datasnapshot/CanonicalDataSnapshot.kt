package com.stillmoment.datasnapshot

import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.domain.models.IntervalMode
import com.stillmoment.domain.models.Praxis

/**
 * The fixed data a release writes for the upgrade test (shared-144).
 *
 * [DataSnapshotGenerator] (androidTest) stores exactly these values through the app's
 * real DataStores; the raw files land in `src/test/resources/data-snapshots/<version>/`.
 * [DataSnapshotUpgradeTest] (unit test) reads every stored version with the current
 * code and expects these values back. Both source sets share this file, so the values
 * are defined only here.
 *
 * The values are the same on iOS (teacher, title, playback range, gongs, Praxis, own
 * sound, appearance, guided preparation time). Only add values, never change existing
 * ones: older snapshots were written with them.
 */
object CanonicalDataSnapshot {
    private const val DATE_ADDED_MS = 1_767_225_600_000L // 2026-01-01T00:00:00Z

    val meditation =
        GuidedMeditation(
            id = "6f1c2a52-0b5e-4c51-9a77-1e44a0b1c144",
            fileUri = "file:///data/user/0/com.stillmoment/files/meditations/upgrade-test-meditation.mp3",
            fileName = "upgrade-test-meditation.mp3",
            duration = 900_000L,
            teacher = "Tara Brach",
            name = "Upgrade Test Meditation",
            dateAdded = DATE_ADDED_MS,
            trimStartMs = 30_000L,
            trimEndMs = 600_000L,
            startGongEnabled = true,
            endGongEnabled = true,
            gongSoundId = "clear-strike"
        )

    val praxis =
        Praxis.create(
            id = "0d7f3e1a-6c2b-4f8e-8a59-3b2e7c90f144",
            durationMinutes = 20,
            preparationTimeEnabled = true,
            preparationTimeSeconds = 15,
            gongSoundId = "deep-resonance",
            gongVolume = 0.8f,
            intervalGongsEnabled = true,
            intervalMinutes = 7,
            intervalMode = IntervalMode.BEFORE_END,
            intervalSoundId = "temple-bell",
            intervalGongVolume = 0.5f,
            backgroundSoundId = "forest",
            backgroundSoundVolume = 0.3f
        )

    val ownSound =
        CustomAudioFile(
            id = "a3e5b7c9-1d2f-4a6b-8c0e-5f7a9b1c3144",
            name = "Rain Upgrade Test",
            filename = "a3e5b7c9-1d2f-4a6b-8c0e-5f7a9b1c3144.mp3",
            durationMs = 180_000L,
            type = CustomAudioType.SOUNDSCAPE,
            dateAdded = DATE_ADDED_MS
        )

    val appearanceMode = AppearanceMode.LIGHT

    val guidedMeditationSettings =
        GuidedMeditationSettings(
            preparationTimeEnabled = true,
            preparationTimeSeconds = 10
        )
}
