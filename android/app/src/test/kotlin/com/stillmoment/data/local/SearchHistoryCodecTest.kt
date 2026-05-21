package com.stillmoment.data.local

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test

/**
 * Unit tests for [SearchHistoryCodec] — the JSON encode/decode logic
 * underlying [SearchHistoryDataStore] (shared-101).
 *
 * The DataStore-Roundtrip itself (Flow emit on edit) is covered by manual
 * testing on device, since instrumented tests require a real Context.
 */
class SearchHistoryCodecTest {
    @Nested
    inner class Encode {
        @Test
        fun `empty list encodes to empty JSON array`() {
            assertEquals("[]", SearchHistoryCodec.encode(emptyList()))
        }

        @Test
        fun `single entry round trips`() {
            val encoded = SearchHistoryCodec.encode(listOf("Atem"))
            assertEquals(listOf("Atem"), SearchHistoryCodec.decode(encoded))
        }

        @Test
        fun `multi entry preserves order`() {
            val items = listOf("Body", "Atem", "Tara")
            val encoded = SearchHistoryCodec.encode(items)
            assertEquals(items, SearchHistoryCodec.decode(encoded))
        }

        @Test
        fun `entries with unicode round trip`() {
            val items = listOf("Übung", "café", "あ")
            val encoded = SearchHistoryCodec.encode(items)
            assertEquals(items, SearchHistoryCodec.decode(encoded))
        }
    }

    @Nested
    inner class Decode {
        @Test
        fun `null input returns empty list`() {
            assertEquals(emptyList<String>(), SearchHistoryCodec.decode(null))
        }

        @Test
        fun `empty string returns empty list`() {
            assertEquals(emptyList<String>(), SearchHistoryCodec.decode(""))
        }

        @Test
        fun `garbage JSON returns empty list without crashing`() {
            assertEquals(emptyList<String>(), SearchHistoryCodec.decode("not-valid-json"))
        }

        @Test
        fun `mismatched JSON type returns empty list`() {
            // JSON object instead of array — should not crash.
            assertEquals(emptyList<String>(), SearchHistoryCodec.decode("""{"foo":"bar"}"""))
        }
    }
}
