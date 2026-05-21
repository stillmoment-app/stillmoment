package com.stillmoment.presentation.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Still Moment Color Palette — Kerzenschein 2.0 (shared-094).
 *
 * All values taken 1:1 from iOS ThemeColors+Palettes.swift (shared-094 stand).
 * - Light: Sunrise Confident — saturated cream/peach/apricot, warm earthy ink.
 * - Dark: Lifted Warm — warmer card lift, warm border, no shadow.
 *
 * Cross-platform-ref: keep values in lock-step with iOS so the visual story
 * stays identical on both platforms.
 */

// region Light — Sunrise Confident (shared-094)

val SmLightTextPrimary = Color(0xFF3A2418) // warm ink, deeper than shared-093
val SmLightTextSecondary = Color(0xFF7A4E3C) // earth-brown
val SmLightTextOnInteractive = Color(0xFFFFF6E6) // warm cream on the play gradient
val SmLightInteractive = Color(0xFFA2503E) // deeper, earthier
val SmLightProgress = Color(0xFFA2503E) // = interactive
val SmLightControlTrack = Color(0xFF94806F) // unchanged hue family
val SmLightBgPrimary = Color(0xFFFBEEDB) // saturated cream
val SmLightBgSecondary = Color(0xFFF6CDA8) // true peach
val SmLightAccentBg = Color(0xFFE8A074) // warm apricot, deeper stop
val SmLightRingTrack = Color(0xFFC8A796)
val SmLightCardBackground = Color(0xFFFFF6E6) // lighter than bgPrimary — carries the lift
val SmLightCardBorder = Color(0x1C78371C) // rgba(120, 55, 28, 0.11) — warm hint
val SmLightError = Color(0xFFBA1A1A)
val SmLightDivider = Color(0x2478371C) // rgba(120, 55, 28, 0.14) — warm accent family
val SmLightPlayGradientTop = Color(0xFFB85F46)
val SmLightPlayGradientBot = Color(0xFF7E3A2D)
val SmLightCardShadow = Color(0x1478371C) // rgba(120, 55, 28, 0.08) — soft warm shadow

// endregion

// region Dark — Lifted Warm (shared-094)

val SmDarkTextPrimary = Color(0xFFE5DCCD)
val SmDarkTextSecondary = Color(0xFFA68A80)
val SmDarkTextOnInteractive = Color(0xFF1A100C)
val SmDarkInteractive = Color(0xFFC77D63)
val SmDarkProgress = Color(0xFFC77D63)
val SmDarkControlTrack = Color(0xFF826960)
val SmDarkBgPrimary = Color(0xFF1A100C)
val SmDarkBgSecondary = Color(0xFF321F19)
val SmDarkAccentBg = Color(0xFF5D3A2F)
val SmDarkRingTrack = Color(0xFFA1604E)
val SmDarkCardBackground = Color(0xFF2E211A) // warm lifted, replaces neutral #252322
val SmDarkCardBorder = Color(0xFF4E382C) // warm copper-brown, replaces neutral grey
val SmDarkError = Color(0xFFE06151)
val SmDarkDivider = Color(0x1AF2E4D3) // rgba(242, 228, 211, 0.10) — light cream tint
val SmDarkPlayGradientTop = Color(0xFFD68A6E)
val SmDarkPlayGradientBot = Color(0xFFB06A4F)
val SmDarkCardShadow = Color.Transparent // dark uses border strategy instead of shadow

// endregion
