---
name: project_android_typography_system
description: Android Typografie 2.1 System (shared-099) — 10-Token-Enum, FontFamily-Konstanten, DisplayNumeral-Logik, Bold-Text-Handling
metadata:
  type: project
---

# Android Typografie 2.1 (shared-099)

Umgesetzt auf Branch `feature/shared-099-android`, gemergt 2026-05-21.

**Why:** Sync mit iOS (ios-048) — gleiche 10 Tokens, Newsreader + Geist statt Nunito.

**How to apply:** Bei zukünftigen Android-Typography-Änderungen diese Architektur referenzieren.

## Kern-Dateien

- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/TextStyle.kt` — `enum class TextStyle` (10 Cases) + `NewsreaderFontFamily`, `NewsreaderItalicFontFamily`, `GeistFontFamily`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/TextStyleModifier.kt` — `TextToken.toComposeTextStyle(monospacedDigits)`, `isBoldTextEnabled()`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/Typography.kt` — Material3-Slot-Bindung
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/DisplayNumeral.kt` — `DisplayNumeral.cappedSize()` pure Funktion + `DisplayNumeralText` Composable

## Architektur-Entscheidungen

- `enum class TextStyle` kollidiert mit Compose-`TextStyle` → Import-Alias `as TextToken` in Modifier/Typography/Debug
- `effectiveFamily(boldTextEnabled)` gibt immer `family` zurück — kein Familienwechsel beim Bold-Bump (Suppress UNUSED_PARAMETER ist korrekt)
- `DisplayNumeralText` hardcoded `FontWeight.Light` — Bold-Text-Setting greift dort nicht (iOS-parität: DisplayNumeral.swift macht dasselbe)
- `DisplayNumeral.cappedSize()`: Cap bei `fontScale >= 1.3` (Android-Schwelle, bewusst tiefer als iOS-AX2 ~1.8) — führt zur Diskontinuität bei fontScale 1.2→1.3

## Bold-Text-Mapping

- Geist Regular (body/caption/micro/eyebrow) → Medium
- Geist Medium (bodyEmphasis) → SemiBold
- Newsreader Light (display/title/screenTitle/section) → Regular (Normal)
- bodyItalic: Italic bleibt Italic
- API < 31: kein Bump (fontWeightAdjustment nicht verfügbar)

## Test-Marker-Pattern

FontFamily-Vergleich via `assertSame()` mit Singleton-Konstanten (`NewsreaderFontFamily`, `GeistFontFamily`, `NewsreaderItalicFontFamily`) — nicht via `equals()`.

## Debug-Screen

`DebugTypographyReferenceScreen.kt` hat hardcoded Strings ("Font Scale", "Bold Text", "Typography Reference", "Ab Android 12 verfuegbar") — bewusst, weil Debug-only.
