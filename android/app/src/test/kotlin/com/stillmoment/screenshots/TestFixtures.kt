package com.stillmoment.screenshots

import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup

/**
 * Test fixtures for screenshot automation.
 * Matches iOS TestFixtureSeeder.swift for cross-platform consistency.
 */
object TestFixtures {
    val meditations =
        listOf(
            GuidedMeditation(
                id = "1",
                fileUri = "content://test/mindful-breathing.mp3",
                fileName = "mindful-breathing.mp3",
                duration = 453_000L, // 7:33
                teacher = "Sarah Kornfield",
                name = "Mindful Breathing"
            ),
            GuidedMeditation(
                id = "2",
                fileUri = "content://test/body-scan.mp3",
                fileName = "body-scan.mp3",
                duration = 942_000L, // 15:42
                teacher = "Sarah Kornfield",
                name = "Body Scan for Beginners"
            ),
            GuidedMeditation(
                id = "3",
                fileUri = "content://test/loving-kindness.mp3",
                fileName = "loving-kindness.mp3",
                duration = 737_000L, // 12:17
                teacher = "Tara Goldstein",
                name = "Loving Kindness"
            ),
            GuidedMeditation(
                id = "4",
                fileUri = "content://test/evening-wind-down.mp3",
                fileName = "evening-wind-down.mp3",
                duration = 1_145_000L, // 19:05
                teacher = "Tara Goldstein",
                name = "Evening Wind Down"
            ),
            GuidedMeditation(
                id = "5",
                fileUri = "content://test/present-moment.mp3",
                fileName = "present-moment.mp3",
                duration = 1_548_000L, // 25:48
                teacher = "Jon Salzberg",
                name = "Present Moment Awareness"
            )
        )

    val meditationGroups: List<GuidedMeditationGroup>
        get() =
            meditations
                .groupBy { it.effectiveTeacher }
                .map { (teacher, meds) ->
                    GuidedMeditationGroup(teacher = teacher, meditations = meds)
                }
                .sortedBy { it.teacher }
}
