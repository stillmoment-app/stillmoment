package com.stillmoment.presentation.ui.theme

import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotEquals
import org.junit.jupiter.api.Assertions.assertSame
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit-Tests fuer das Typografie 2.1 Token-System (10 Tokens).
 *
 * Pendant zu iOS' `TextStyleTests.swift`. Friert die Acceptance-Kriterien
 * "Anzahl Tokens", "Family-Mapping", "Bold-Text-Bump" und
 * "Tracking / Uppercase" ein.
 */
class TextStyleTest {

    @Nested
    inner class TokenCount {

        @Test
        fun `has exactly ten tokens`() {
            assertEquals(10, TextStyle.entries.size)
        }
    }

    @Nested
    inner class FontFamilyMapping {

        @Test
        fun `serif tokens use Newsreader`() {
            val serifTokens = listOf(
                TextStyle.display,
                TextStyle.title,
                TextStyle.screenTitle,
                TextStyle.section,
            )
            serifTokens.forEach { token ->
                assertSame(
                    NewsreaderFontFamily,
                    token.family,
                    "$token should use NewsreaderFontFamily"
                )
            }
        }

        @Test
        fun `sans tokens use Geist`() {
            val sansTokens = listOf(
                TextStyle.body,
                TextStyle.bodyEmphasis,
                TextStyle.caption,
                TextStyle.micro,
                TextStyle.eyebrow,
            )
            sansTokens.forEach { token ->
                assertSame(
                    GeistFontFamily,
                    token.family,
                    "$token should use GeistFontFamily"
                )
            }
        }

        @Test
        fun `bodyItalic uses Newsreader Italic family`() {
            assertSame(NewsreaderItalicFontFamily, TextStyle.bodyItalic.family)
        }
    }

    @Nested
    inner class WeightMapping {

        @Test
        fun `serif display tokens use Light weight`() {
            assertEquals(FontWeight.Light, TextStyle.display.weight)
            assertEquals(FontWeight.Light, TextStyle.title.weight)
            assertEquals(FontWeight.Light, TextStyle.screenTitle.weight)
            assertEquals(FontWeight.Light, TextStyle.section.weight)
        }

        @Test
        fun `body uses Regular weight`() {
            assertEquals(FontWeight.Normal, TextStyle.body.weight)
        }

        @Test
        fun `bodyEmphasis uses Geist Medium`() {
            assertEquals(FontWeight.Medium, TextStyle.bodyEmphasis.weight)
        }

        @Test
        fun `caption micro eyebrow use Regular weight`() {
            assertEquals(FontWeight.Normal, TextStyle.caption.weight)
            assertEquals(FontWeight.Normal, TextStyle.micro.weight)
            assertEquals(FontWeight.Normal, TextStyle.eyebrow.weight)
        }
    }

    @Nested
    inner class FontStyleMapping {

        @Test
        fun `only bodyItalic carries Italic style`() {
            TextStyle.entries.forEach { token ->
                if (token == TextStyle.bodyItalic) {
                    assertEquals(FontStyle.Italic, token.style)
                } else {
                    assertEquals(
                        FontStyle.Normal,
                        token.style,
                        "$token should be FontStyle.Normal"
                    )
                }
            }
        }
    }

    @Nested
    inner class BaseSize {

        @Test
        fun `base sizes match spec`() {
            assertEquals(88.sp, TextStyle.display.baseSize)
            assertEquals(30.sp, TextStyle.title.baseSize)
            assertEquals(26.sp, TextStyle.screenTitle.baseSize)
            assertEquals(20.sp, TextStyle.section.baseSize)
            assertEquals(17.sp, TextStyle.body.baseSize)
            assertEquals(17.sp, TextStyle.bodyEmphasis.baseSize)
            assertEquals(17.sp, TextStyle.bodyItalic.baseSize)
            assertEquals(14.sp, TextStyle.caption.baseSize)
            assertEquals(11.sp, TextStyle.micro.baseSize)
            assertEquals(11.sp, TextStyle.eyebrow.baseSize)
        }
    }

    @Nested
    inner class Tracking {

        @Test
        fun `eyebrow has positive tracked caps tracking`() {
            assertTrue(TextStyle.eyebrow.tracking.value > 0)
        }

        @Test
        fun `title and screenTitle use slightly negative tracking`() {
            assertTrue(TextStyle.title.tracking.value < 0)
            assertTrue(TextStyle.screenTitle.tracking.value < 0)
        }

        @Test
        fun `body and caption have no tracking`() {
            assertEquals(0f, TextStyle.body.tracking.value)
            assertEquals(0f, TextStyle.caption.tracking.value)
        }
    }

    @Nested
    inner class Uppercase {

        @Test
        fun `only eyebrow uses uppercase`() {
            TextStyle.entries.forEach { token ->
                assertEquals(
                    token == TextStyle.eyebrow,
                    token.uppercase,
                    "$token uppercase expectation"
                )
            }
        }

        @Test
        fun `applyCase uppercases text for eyebrow`() {
            assertEquals("HEUTE", TextStyle.eyebrow.applyCase("Heute"))
        }

        @Test
        fun `applyCase leaves text unchanged for non-uppercase tokens`() {
            TextStyle.entries
                .filter { it != TextStyle.eyebrow }
                .forEach { token ->
                    assertEquals(
                        "Heute",
                        token.applyCase("Heute"),
                        "$token should not transform text"
                    )
                }
        }
    }

    @Nested
    inner class BoldTextBump {

        @Test
        fun `regular legibility returns default family`() {
            TextStyle.entries.forEach { token ->
                assertSame(
                    token.family,
                    token.effectiveFamily(boldTextEnabled = false),
                    "$token: default family should be returned without bold"
                )
            }
        }

        @Test
        fun `regular legibility returns default weight`() {
            TextStyle.entries.forEach { token ->
                assertEquals(
                    token.weight,
                    token.effectiveWeight(boldTextEnabled = false),
                    "$token: default weight should be returned without bold"
                )
            }
        }

        @Test
        fun `bold bumps Geist Regular body to Medium`() {
            assertEquals(FontWeight.Medium, TextStyle.body.effectiveWeight(boldTextEnabled = true))
            assertEquals(FontWeight.Medium, TextStyle.caption.effectiveWeight(boldTextEnabled = true))
            assertEquals(FontWeight.Medium, TextStyle.micro.effectiveWeight(boldTextEnabled = true))
            assertEquals(FontWeight.Medium, TextStyle.eyebrow.effectiveWeight(boldTextEnabled = true))
        }

        @Test
        fun `bold bumps Geist Medium bodyEmphasis to SemiBold`() {
            assertEquals(
                FontWeight.SemiBold,
                TextStyle.bodyEmphasis.effectiveWeight(boldTextEnabled = true)
            )
        }

        @Test
        fun `bold bumps Newsreader Light to Regular`() {
            assertEquals(FontWeight.Normal, TextStyle.display.effectiveWeight(boldTextEnabled = true))
            assertEquals(FontWeight.Normal, TextStyle.title.effectiveWeight(boldTextEnabled = true))
            assertEquals(FontWeight.Normal, TextStyle.screenTitle.effectiveWeight(boldTextEnabled = true))
            assertEquals(FontWeight.Normal, TextStyle.section.effectiveWeight(boldTextEnabled = true))
        }

        @Test
        fun `bold keeps Italic Italic`() {
            assertEquals(FontStyle.Italic, TextStyle.bodyItalic.style)
            // Italic-Cut wechselt nicht das Style-Flag — die Familie bleibt Italic.
            assertSame(
                NewsreaderItalicFontFamily,
                TextStyle.bodyItalic.effectiveFamily(boldTextEnabled = true)
            )
        }

        @Test
        fun `bold differs from regular weight for affected tokens`() {
            val affected = listOf(
                TextStyle.body,
                TextStyle.bodyEmphasis,
                TextStyle.caption,
                TextStyle.micro,
                TextStyle.eyebrow,
                TextStyle.display,
                TextStyle.title,
                TextStyle.screenTitle,
                TextStyle.section,
            )
            affected.forEach { token ->
                assertNotEquals(
                    token.weight,
                    token.effectiveWeight(boldTextEnabled = true),
                    "$token weight should change with bold text"
                )
            }
        }
    }
}
