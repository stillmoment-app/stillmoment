# Implementierungsplan: shared-121 (Android)

Ticket: [shared-121](../shared/shared-121-hintergrundklang-screen-redesign.md)
Erstellt: 2026-06-17

> **Nachtrag 2026-06-17:** Die Mini-Wellenform (`ScapeWaveform`, SWAVE, Equalizer, flache Linie) wurde auf User-Wunsch **gestrichen** und ist NICHT umgesetzt. Wiedergabe-Indikator ist allein der Play/Stop-Vorhör-Button mit atmendem Glow. Eigene Dateien behalten Umbenennen + Entfernen via Kebab-Menü (⋮). Die folgenden Wellenform-Abschnitte sind historisch.

> Android wird als **Port der iOS-Implementierung** umgesetzt (iOS zuerst). Verhalten, Layout, Hüllkurven und Animationszeiten identisch. Dieser Plan spiegelt [shared-121-ios.md](shared-121-ios.md) und nennt die Android-Entsprechungen.

## Annahmen

Identisch zu iOS:
- Nur Nacht-Theme gestaltet/getestet.
- Eigene Klänge: nur **Entfernen** (Bestätigungsdialog), **kein Umbenennen** auf diesem Screen. Bestehende Lösch-Sicherheit (Reset auf Default falls verwendet) bleibt.
- Lautstärke-Default unverändert (bestehende `Praxis.backgroundSoundVolume`).
- Neutrale Default-Hüllkurve für eigene Dateien (keine Audio-Analyse).
- Loop-Vorschau läuft bis zum expliziten Stopp.
- **Cross-Platform-Spezifikation:** SWAVE-Hüllkurven (13 Werte) und Animationszeiten (Glow 1.6s, Equalizer 0.9s) müssen identisch zu iOS sein (gleiche `Map`/Konstanten), analog zur bestehenden `GongWaveform.WAVE`-Parität.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `presentation/ui/timer/SelectBackgroundSoundScreen.kt` | Presentation | Refactoring | Von einfachen `BackgroundSoundRow`-Listen auf Karten-Sections (Eyebrows) + Intro-Text + neue Row-Composables. Overflow-Menü (Rename) entfernen → Entfernen-Symbol + Confirm-Dialog. |
| `presentation/ui/timer/components/ScapeSoundCard.kt` | Presentation | **Neu** | `ScapeSoundCard` (Wrapper, analog `GongSoundCard`) + `ScapeSoundRow` (Vorhör-Button + Name + Wellenform + Häkchen + optional Entfernen). |
| `presentation/ui/timer/components/ScapePreviewButton.kt` | Presentation | **Neu** | Play/Stop-Toggle; dauerhafter atmender Glow (1.6s) statt einmaligem Ring; Mute-Icon für „Stille". Reduced-Motion-Support (wie `GongPreviewButton`). |
| `presentation/ui/timer/components/ScapeWaveform.kt` | Presentation | **Neu** | 13 Balken, SWAVE-Map (identisch iOS); Equalizer-Animation beim Abspielen; flache Linie für „Stille"; neutrale Default-Hüllkurve für Custom. |
| `presentation/ui/timer/components/GongCard.kt` | Presentation | Wiederverwenden | Karten-Chrome (22dp, 0.5dp Border) — unverändert. |
| `presentation/ui/timer/components/GongVolumeCard.kt` | Presentation | Wiederverwenden | LAUTSTÄRKE-Karte; Test-Tag für Background parametrisieren. |
| `presentation/ui/timer/components/GongSectionLabel.kt` | Presentation | Wiederverwenden | `EyebrowLabel`. |
| `presentation/viewmodel/PraxisSettingsViewModel.kt` | Presentation | Erweitern | `previewingSoundscapeId` in `PraxisSettingsUiState`; Toggle-Methode; Live-Lautstärke; Auswahl/Stille-Verhalten. |
| `domain/services/AudioServiceProtocol.kt` | Domain | Erweitern | `setBackgroundPreviewVolume(volume)`; `playBackgroundPreview` ohne Auto-Stop (Loop bis Stop). |
| `infrastructure/audio/AudioService.kt` | Infrastructure | Refactoring | Background-Preview loopt ohne Fade-out-Timer; Live-Volume-Setter über `backgroundPreviewPlayer`. |
| `MockAudioService` (Test) | Test | Erweitern | Neue Methode mocken. |
| `res/values/strings.xml` + `values-de/strings.xml` | Resources | Erweitern | Intro, Eyebrows, „Stille"-Hinweis, Empty-Card-Text, Accessibility (Play/Stop/Mute/Entfernen). |

## Design-Entscheidungen

Identisch zu iOS (siehe [shared-121-ios.md](shared-121-ios.md)):
1. Neue `Scape*`-Composables statt Überladen der `Gong*`-Composables; geteilt nur visuelle Chrome (`GongCard`, `GongVolumeCard`, `EyebrowLabel`).
2. Loop-Vorschau ohne Auto-Stop + Live-Lautstärke (`setBackgroundPreviewVolume`).
3. Preview-State: `previewingSoundscapeId` im `PraxisSettingsUiState` (Compose hat kein lokales View-`@State`-Äquivalent für ViewModel-getriebenes Verhalten; Single Source of Truth = UiState). Kein Auto-Reset.

## API-Recherche

Keine neuen Frameworks. Jetpack Compose Bordmittel: `rememberInfiniteTransition` (atmender Glow / Equalizer), `Canvas`/`DrawScope` (Wellenform, wie `GongWaveform`), `LocalAccessibilityManager`/Reduced-Motion-Check (wie in `GongPreviewButton`). `MediaPlayer.isLooping = true` (bereits genutzt). Live-Volume über `MediaPlayer.setVolume`.

**Detekt-Vorsicht** (aus Projekt-Memory): `LongMethod` (60 Zeilen) und `MultipleEmitters` — Composables proaktiv in kleine Teile splitten (`ScapeSoundRow`, `StepperButton`-Stil), Top-Level-Emitter in `Column`/`Row` wrappen.

## Fachliche Szenarien

Identisch zu iOS — siehe [shared-121-ios.md](shared-121-ios.md), Abschnitt „Fachliche Szenarien". Alle Szenarien (Auswahl, Vorhör-Toggle, Stille, Lautstärke live, Eigene Klänge inkl. Entfernen-Dialog, Reduced Motion) müssen auf Android identisch beobachtbar sein.

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **Audio-Layer:** `AudioServiceProtocol`/`AudioService` — Loop-Vorschau ohne Auto-Stop + `setBackgroundPreviewVolume`; Mock erweitern.
2. **ViewModel:** Toggle/Live-Lautstärke/Stille in `PraxisSettingsViewModel` + `UiState`; Unit-Tests.
3. **Composables:** `ScapeWaveform` (Hüllkurven/Equalizer/flache Linie, reine Logik testbar) → `ScapePreviewButton` → `ScapeSoundCard`/`ScapeSoundRow`.
4. **Screen:** `SelectBackgroundSoundScreen` neu zusammensetzen (Sections, Intro, Empty-Card, Import, Entfernen-Dialog).
5. **Lokalisierung & Accessibility.**

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `playBackgroundPreview`-Änderung bricht anderen Aufrufer | Aufrufer per Grep prüfen; Timer-Background-Loop (`startBackgroundAudio`) nicht anfassen. |
| Kotlin Int-Overflow bei Balkenhöhen-Berechnung (Projekt-Memory) | Hüllkurven-Mapping mit Float; keine großen Int-Multiplikationen. |
| Hüllkurven-/Timing-Drift zu iOS | Werte als geteilte Konstanten-Map; im Review gegen iOS abgleichen. |
| Detekt LongMethod/MultipleEmitters | Komponenten klein halten, Emitter wrappen. |

## Offene Fragen

- Keine.
