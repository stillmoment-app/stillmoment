package com.stillmoment.presentation.ui.theme

import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit-Tests fuer die pure Berechnungsfunktion hinter [DisplayNumeral].
 *
 * Pendant zu iOS' `DisplayNumeralTests.swift`. Friert die Plan-Akzeptanz fuer
 * container-relative Numerik ein: Floor 56sp, Ceiling 120sp, Faktor 0.32,
 * Cap bei System-Font-Scale >= 1.3.
 */
class DisplayNumeralTest {

    private fun cap(diameter: Float, fontScale: Float): TextUnit =
        DisplayNumeral.cappedSize(containerDiameter = diameter.dp, fontScale = fontScale)

    @Nested
    inner class StandardSize {

        @Test
        fun `220dp container at scale 1_0 returns 70_4sp`() {
            val result = cap(diameter = 220f, fontScale = 1.0f)
            assertEquals(70.4f.sp, result)
        }

        @Test
        fun `280dp container at scale 1_0 returns 89_6sp`() {
            val result = cap(diameter = 280f, fontScale = 1.0f)
            assertEquals(89.6f.sp, result)
        }

        @Test
        fun `300dp container at scale 1_0 returns 96sp`() {
            val result = cap(diameter = 300f, fontScale = 1.0f)
            assertEquals(96f.sp, result)
        }
    }

    @Nested
    inner class Floor {

        @Test
        fun `tiny container floors at 56sp`() {
            // 100dp * 0.32 = 32sp → would be < 56sp, so floor kicks in.
            val result = cap(diameter = 100f, fontScale = 1.0f)
            assertEquals(56f.sp, result)
        }

        @Test
        fun `170dp container floors at 56sp`() {
            // 170dp * 0.32 = 54.4sp < 56sp → floored.
            val result = cap(diameter = 170f, fontScale = 1.0f)
            assertEquals(56f.sp, result)
        }
    }

    @Nested
    inner class Ceiling {

        @Test
        fun `oversized container ceilings at 120sp`() {
            // 400dp * 0.32 = 128sp → would be > 120sp, so ceiling kicks in.
            val result = cap(diameter = 400f, fontScale = 1.0f)
            assertEquals(120f.sp, result)
        }
    }

    @Nested
    inner class FontScale {

        @Test
        fun `scale 0_85 reduces base size proportionally`() {
            val result = cap(diameter = 280f, fontScale = 0.85f)
            // 280dp * 0.32 = 89.6 ; capped (still inside 56-120) ; * 0.85 = 76.16
            assertEquals(76.16f.sp, result)
        }

        @Test
        fun `scale 1_3 caps at base size (no scaling)`() {
            val baseAtOne = cap(diameter = 280f, fontScale = 1.0f)
            val capped = cap(diameter = 280f, fontScale = 1.3f)
            assertEquals(baseAtOne, capped)
        }

        @Test
        fun `scale 2_0 caps at base size (no scaling)`() {
            val baseAtOne = cap(diameter = 280f, fontScale = 1.0f)
            val capped = cap(diameter = 280f, fontScale = 2.0f)
            assertEquals(baseAtOne, capped)
        }

        @Test
        fun `scale below 1_3 still scales`() {
            val baseAtOne = cap(diameter = 280f, fontScale = 1.0f)
            val scaled = cap(diameter = 280f, fontScale = 1.2f)
            assertTrue(
                scaled.value > baseAtOne.value,
                "1.2x should scale beyond 1.0x baseline"
            )
        }
    }
}
