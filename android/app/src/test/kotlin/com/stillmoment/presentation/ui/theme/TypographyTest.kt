package com.stillmoment.presentation.ui.theme

import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

class TypographyTest {

    @Nested
    inner class DarkModeCompensation {

        @Test
        fun `light mode returns original weight`() {
            assertEquals(FontWeight.Thin, FontWeight.Thin.darkModeCompensated(false))
            assertEquals(FontWeight.ExtraLight, FontWeight.ExtraLight.darkModeCompensated(false))
            assertEquals(FontWeight.Light, FontWeight.Light.darkModeCompensated(false))
            assertEquals(FontWeight.Normal, FontWeight.Normal.darkModeCompensated(false))
            assertEquals(FontWeight.Medium, FontWeight.Medium.darkModeCompensated(false))
            assertEquals(FontWeight.SemiBold, FontWeight.SemiBold.darkModeCompensated(false))
        }

        @Test
        fun `dark mode Thin becomes ExtraLight`() {
            assertEquals(FontWeight.ExtraLight, FontWeight.Thin.darkModeCompensated(true))
        }

        @Test
        fun `dark mode ExtraLight becomes Light`() {
            assertEquals(FontWeight.Light, FontWeight.ExtraLight.darkModeCompensated(true))
        }

        @Test
        fun `dark mode Light becomes Normal`() {
            assertEquals(FontWeight.Normal, FontWeight.Light.darkModeCompensated(true))
        }

        @Test
        fun `dark mode Normal becomes Medium`() {
            assertEquals(FontWeight.Medium, FontWeight.Normal.darkModeCompensated(true))
        }

        @Test
        fun `dark mode Medium stays Medium`() {
            assertEquals(FontWeight.Medium, FontWeight.Medium.darkModeCompensated(true))
        }

        @Test
        fun `dark mode SemiBold stays SemiBold`() {
            assertEquals(FontWeight.SemiBold, FontWeight.SemiBold.darkModeCompensated(true))
        }

        @Test
        fun `dark mode Bold stays Bold`() {
            assertEquals(FontWeight.Bold, FontWeight.Bold.darkModeCompensated(true))
        }
    }

    @Nested
    inner class FontSpecExpectations {

        @Test
        fun `timerCountdown uses 100sp Thin`() {
            val spec = TypographyRole.TimerCountdown.fontSpec
            assertEquals(100.sp, spec.size)
            assertEquals(FontWeight.Thin, spec.weight)
        }

        @Test
        fun `timerRunning uses 60sp ExtraLight`() {
            val spec = TypographyRole.TimerRunning.fontSpec
            assertEquals(60.sp, spec.size)
            assertEquals(FontWeight.ExtraLight, spec.weight)
        }

        @Test
        fun `screenTitle uses 28sp Light`() {
            val spec = TypographyRole.ScreenTitle.fontSpec
            assertEquals(28.sp, spec.size)
            assertEquals(FontWeight.Light, spec.weight)
        }

        @Test
        fun `sectionTitle uses 20sp Light`() {
            val spec = TypographyRole.SectionTitle.fontSpec
            assertEquals(20.sp, spec.size)
            assertEquals(FontWeight.Light, spec.weight)
        }

        @Test
        fun `settingsLabel uses 17sp Normal`() {
            val spec = TypographyRole.SettingsLabel.fontSpec
            assertEquals(17.sp, spec.size)
            assertEquals(FontWeight.Normal, spec.weight)
        }

        @Test
        fun `settingsDescription uses 13sp Normal`() {
            val spec = TypographyRole.SettingsDescription.fontSpec
            assertEquals(13.sp, spec.size)
            assertEquals(FontWeight.Normal, spec.weight)
        }

        @Test
        fun `editLabel uses 14sp Medium`() {
            val spec = TypographyRole.EditLabel.fontSpec
            assertEquals(14.sp, spec.size)
            assertEquals(FontWeight.Medium, spec.weight)
        }

        @Test
        fun `editCaption uses 12sp Normal`() {
            val spec = TypographyRole.EditCaption.fontSpec
            assertEquals(12.sp, spec.size)
            assertEquals(FontWeight.Normal, spec.weight)
        }

        @Test
        fun `listTitle uses 16sp Medium`() {
            val spec = TypographyRole.ListTitle.fontSpec
            assertEquals(16.sp, spec.size)
            assertEquals(FontWeight.Medium, spec.weight)
        }
    }

    @Nested
    inner class TextColorMapping {

        @Test
        fun `primary text roles map to TextPrimary`() {
            val primaryRoles = listOf(
                TypographyRole.TimerCountdown,
                TypographyRole.TimerRunning,
                TypographyRole.ScreenTitle,
                TypographyRole.SectionTitle,
                TypographyRole.BodyPrimary,
                TypographyRole.SettingsLabel,
                TypographyRole.PlayerTitle,
                TypographyRole.PlayerCountdown,
                TypographyRole.ListTitle,
                TypographyRole.ListSectionTitle,
                TypographyRole.ListActionLabel,
                TypographyRole.EditLabel,
            )
            primaryRoles.forEach { role ->
                assertEquals(
                    ThemeColorRole.TextPrimary,
                    role.colorRole,
                    "$role should map to TextPrimary"
                )
            }
        }

        @Test
        fun `secondary text roles map to TextSecondary`() {
            val secondaryRoles = listOf(
                TypographyRole.BodySecondary,
                TypographyRole.Caption,
                TypographyRole.SettingsDescription,
                TypographyRole.PlayerTimestamp,
                TypographyRole.ListSubtitle,
                TypographyRole.ListBody,
                TypographyRole.EditCaption,
            )
            secondaryRoles.forEach { role ->
                assertEquals(
                    ThemeColorRole.TextSecondary,
                    role.colorRole,
                    "$role should map to TextSecondary"
                )
            }
        }

        @Test
        fun `playerTeacher maps to Interactive`() {
            assertEquals(ThemeColorRole.Interactive, TypographyRole.PlayerTeacher.colorRole)
        }

        @Test
        fun `every role has a color mapping`() {
            TypographyRole.entries.forEach { role ->
                val colorRole = role.colorRole
                assert(colorRole in ThemeColorRole.entries) {
                    "$role has no valid color mapping"
                }
            }
        }
    }

    @Nested
    inner class RoleUniqueness {

        @Test
        fun `all 20 roles are defined`() {
            assertEquals(20, TypographyRole.entries.size)
        }

        @Test
        fun `timer roles have unique font specs`() {
            val timerSpecs = listOf(
                TypographyRole.TimerCountdown,
                TypographyRole.TimerRunning,
            ).map { it.fontSpec }
            assertEquals(timerSpecs.size, timerSpecs.toSet().size)
        }

        @Test
        fun `heading roles have unique font specs`() {
            val headingSpecs = listOf(
                TypographyRole.ScreenTitle,
                TypographyRole.SectionTitle,
            ).map { it.fontSpec }
            assertEquals(headingSpecs.size, headingSpecs.toSet().size)
        }

        @Test
        fun `body roles have unique font specs`() {
            val bodySpecs = listOf(
                TypographyRole.BodyPrimary,
                TypographyRole.BodySecondary,
                TypographyRole.Caption,
            ).map { it.fontSpec }
            assertEquals(bodySpecs.size, bodySpecs.toSet().size)
        }

        @Test
        fun `settings roles have unique font specs`() {
            val settingsSpecs = listOf(
                TypographyRole.SettingsLabel,
                TypographyRole.SettingsDescription,
            ).map { it.fontSpec }
            assertEquals(settingsSpecs.size, settingsSpecs.toSet().size)
        }

        @Test
        fun `player roles have unique font specs`() {
            val playerSpecs = listOf(
                TypographyRole.PlayerTitle,
                TypographyRole.PlayerTeacher,
                TypographyRole.PlayerTimestamp,
                TypographyRole.PlayerCountdown,
            ).map { it.fontSpec }
            assertEquals(playerSpecs.size, playerSpecs.toSet().size)
        }

        @Test
        fun `edit roles have unique font specs`() {
            val editSpecs = listOf(
                TypographyRole.EditLabel,
                TypographyRole.EditCaption,
            ).map { it.fontSpec }
            assertEquals(editSpecs.size, editSpecs.toSet().size)
        }
    }

    @Nested
    inner class ThemeColorRoleResolution {

        @Test
        fun `TextPrimary resolves to onSurface`() {
            val scheme = resolveColorScheme(
                com.stillmoment.domain.models.ColorTheme.CANDLELIGHT,
                darkTheme = false
            )
            assertEquals(scheme.onSurface, ThemeColorRole.TextPrimary.resolve(scheme))
        }

        @Test
        fun `TextSecondary resolves to onSurfaceVariant`() {
            val scheme = resolveColorScheme(
                com.stillmoment.domain.models.ColorTheme.CANDLELIGHT,
                darkTheme = false
            )
            assertEquals(scheme.onSurfaceVariant, ThemeColorRole.TextSecondary.resolve(scheme))
        }

        @Test
        fun `Interactive resolves to primary`() {
            val scheme = resolveColorScheme(
                com.stillmoment.domain.models.ColorTheme.CANDLELIGHT,
                darkTheme = false
            )
            assertEquals(scheme.primary, ThemeColorRole.Interactive.resolve(scheme))
        }

        @Test
        fun `color resolution uses correct theme colors`() {
            val lightScheme = resolveColorScheme(
                com.stillmoment.domain.models.ColorTheme.CANDLELIGHT,
                darkTheme = false
            )
            val darkScheme = resolveColorScheme(
                com.stillmoment.domain.models.ColorTheme.CANDLELIGHT,
                darkTheme = true
            )

            assertNotEquals(
                ThemeColorRole.TextPrimary.resolve(lightScheme),
                ThemeColorRole.TextPrimary.resolve(darkScheme),
                "TextPrimary should differ between light and dark"
            )
        }
    }
}
