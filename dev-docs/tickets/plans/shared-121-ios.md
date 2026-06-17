# Implementierungsplan: shared-121 (iOS)

Ticket: [shared-121](../shared/shared-121-hintergrundklang-screen-redesign.md)
Erstellt: 2026-06-17

> **Nachtrag 2026-06-17:** Die Mini-Wellenform (`ScapeWaveform`, SWAVE, Equalizer, flache Linie) wurde auf User-Wunsch **gestrichen** und ist NICHT umgesetzt. Wiedergabe-Indikator ist allein der Play/Stop-Vorhör-Button mit atmendem Glow. Eigene Dateien behalten Umbenennen + Entfernen via Kebab-Menü (⋮). Die folgenden Wellenform-Abschnitte sind historisch.

## Annahmen

- **Nur Nacht-Theme** wird gestaltet/getestet (wie Handoff). Light-Pfad nicht brechen, aber nicht eigens optimieren.
- **Eigene Klänge:** Vorlage 1:1 — nur **Entfernen** (Papierkorb) mit Bestätigungsdialog. **Umbenennen entfällt** auf diesem Screen (User hat Handoff entsprechend aktualisiert). Die bestehende Lösch-Sicherheit (Nutzungs-Warnung via `usageCount`, Reset auf Default falls in Verwendung) bleibt erhalten.
- **Lautstärke-Default** bleibt unverändert (bestehende `Praxis.backgroundSoundVolume`-Logik). Der Slider spiegelt nur den gespeicherten Wert; kein neuer Default aus dem Prototyp (60) übernommen.
- **Wellenform für eigene Dateien:** Es gibt keine SWAVE-Hüllkurve für importierte Dateien → neutrale Default-Hüllkurve (ruhiges Loop-Muster), gleich für alle Custom-Dateien. Keine echte Audio-Analyse (out of scope, „No theater").
- **Loop-Vorschau läuft bis zum expliziten Stopp** (Toggle / Silence / Verlassen des Screens) — nicht mehr der bisherige 3-Sekunden-Auto-Fade-out.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Presentation/Views/Timer/BackgroundSoundSelectionView.swift` | Presentation | Refactoring | Von `List`/`cardRowBackground` auf `ScrollView` + Karten-Sections (Eyebrows KLANG/MEINE KLÄNGE/LAUTSTÄRKE), Intro-Text, neue Row-Komponenten. Overflow-Menü (Rename) entfernen, durch Entfernen-Symbol ersetzen. |
| `Presentation/Views/Timer/Components/ScapeSoundRow.swift` | Presentation | **Neu** | Soundscape-Zeile: Vorhör-Button + Name + Wellenform + Häkchen; optional Entfernen-Aktion (Custom). Analog `GongSoundRow`, aber Loop-Verhalten. |
| `Presentation/Views/Timer/Components/ScapePreviewButton.swift` | Presentation | **Neu** | Play/Stop-Toggle; atmender Glow (dauerhaft ~1.6s) statt expandierendem Ring; Mute-Glyph für „Stille". Reduce-Motion: Glow steht still. |
| `Presentation/Views/Timer/Components/ScapeWaveform.swift` | Presentation | **Neu** | 13 Balken, SWAVE-Hüllkurven (Loop-Muster); Equalizer-Animation beim Abspielen; flache Linie für „Stille"; neutrale Default-Hüllkurve für Custom. |
| `Presentation/Views/Timer/Components/GongCardBackground.swift` | Presentation | Wiederverwenden | Karten-Chrome (Radius 22, Border im Dark Mode) — rein visuell, unverändert nutzen. |
| `Presentation/Views/Timer/Components/GongVolumeCard.swift` | Presentation | Wiederverwenden | LAUTSTÄRKE-Karte. Eigener `accessibilityIdentifier` für Background ggf. parametrisieren (sonst kollidiert „gongVolume"). |
| `Presentation/Views/Shared/ImportAudioButton.swift` | Presentation | Prüfen/Anpassen | Pill-Stil laut Handoff (`surface-2`, 1px border, accent, Plus). Falls bereits passend: nur Platzierung unter MEINE KLÄNGE. |
| `Application/ViewModels/PraxisSettingsViewModel.swift` | Application | Erweitern | Toggle-Logik der Loop-Vorschau; Live-Lautstärke an laufende Vorschau; `availableBackgroundSounds` bleibt. |
| `Domain/Services/AudioServiceProtocol.swift` | Domain | Erweitern | `setBackgroundPreviewVolume(_:)` (Live-Pegel). `playBackgroundPreview` ohne 3s-Auto-Stop (Loop bis Stop). |
| `Infrastructure/Services/AudioService.swift` | Infrastructure | Refactoring | Background-Preview loopt ohne Auto-Fade-out-Timer; Live-Volume-Setter. Bestehende `stopBackgroundPreview` bleibt. |
| `Infrastructure/Services/MockAudioService` (Tests) | Test | Erweitern | Neue Protocol-Methode mocken. |
| `Resources/*.strings` / `*.stringsdict` | Resources | Erweitern | Intro-Text, Eyebrows, Hinweis „Stille", Empty-Card-Text, Accessibility-Labels (Play/Stop/Mute/Entfernen) DE+EN. |

## Design-Entscheidungen

### 1. Soundscape-eigene Komponenten statt Erweiterung der Gong-Komponenten

**Trade-off:** Wiederverwendung von `GongSoundRow`/`GongPreviewButton`/`GongWaveform` spart Code, würde sie aber mit Loop-Flags (Toggle, Dauer-Glow, Equalizer, 13 statt 11 Balken, Mute/flache Linie, Entfernen-Aktion) überladen und die fertigen Screens shared-115/118/120 gefährden.
**Entscheidung:** Neue `Scape*`-Komponenten. Geteilt wird nur die rein **visuelle** Chrome (`GongCardBackground`, `GongVolumeCard`, Eyebrow-Textstyle, `ImportAudioButton`). Niedrigeres Regressionsrisiko, klare Trennung Einmal-Gong vs. Loop-Soundscape. Entspricht „simplest solution / ergänzen statt umbauen".

### 2. Loop-Vorschau ohne Auto-Stop + Live-Lautstärke

**Trade-off:** Bisher fadet die Background-Vorschau nach 3s aus. Das passt nicht zum Play/Stop-Toggle (Button zeigt „Stop", solange es spielt).
**Entscheidung:** `playBackgroundPreview` loopt bis explizitem Stop (Toggle, „Stille", `onDisappear`). Slider ändert den Pegel der laufenden Vorschau live über `setBackgroundPreviewVolume(_:)` statt Neustart (kein hörbarer Glitch). Einziger Aufrufer ist dieser Screen → Risiko gering.

### 3. Preview-State in der View (wie GongSelectionView)

**Entscheidung:** `@State previewingSoundscapeId: String?` in der View, kein neues `@Published` im ViewModel — spiegelt das etablierte Gong-Muster. Unterschied: kein Auto-Reset-Task; der State bleibt gesetzt, bis gestoppt wird.

## API-Recherche

Keine neuen Framework-APIs. SwiftUI-Bordmittel: `Animation.repeatForever` (atmender Glow), `@Environment(\.accessibilityReduceMotion)` (bereits in `GongPreviewButton` verwendet). `AVAudioPlayer.numberOfLoops = -1` (bereits genutzt). `AVAudioPlayer.setVolume(_:fadeDuration:)` für Live-Pegel.

## Fachliche Szenarien

### AK: Karten-Picker & Auswahl
- Gegeben: Hintergrundklang-Screen offen, „Waldatmosphäre" ausgewählt. Wenn: nichts. Dann: Zeile getönt, Häkchen sichtbar, Name hervorgehoben, Mini-Wellenform rechts.
- Gegeben: „Regen" nicht ausgewählt. Wenn: Zeile antippen. Dann: „Regen" wird ausgewählt, Loop-Vorschau startet, Wellenform animiert als Equalizer, Vorhör-Button zeigt Stop + atmenden Glow.

### AK: Vorhör-Toggle (ohne Auswahländerung)
- Gegeben: „Regen" ausgewählt, keine Vorschau läuft. Wenn: Vorhör-Button von „Waldatmosphäre" antippen. Dann: Waldatmosphäre-Loop spielt, „Regen" bleibt ausgewählt (Häkchen wandert nicht).
- Gegeben: Eine Vorschau läuft. Wenn: deren Vorhör-Button erneut antippen. Dann: Vorschau stoppt, Button zurück auf Play, Glow/Equalizer aus.
- Gegeben: Vorschau A läuft. Wenn: Vorhör-Button B antippen. Dann: A stoppt, B spielt (immer nur einer).

### AK: „Stille"
- Gegeben: beliebiger Klang spielt Vorschau. Wenn: „Stille" antippen. Dann: jede Wiedergabe stoppt, „Stille" ausgewählt, Lautstärke-Karte verschwindet, Hinweistext erscheint.
- Gegeben: „Stille"-Zeile. Wenn: nichts. Dann: Mute-Glyph statt Play, flache Linie statt Wellenform; Vorhör-Button spielt nichts ab.

### AK: Lautstärke
- Gegeben: „Regen"-Vorschau läuft. Wenn: Slider ziehen. Dann: Pegel der laufenden Vorschau ändert sich sofort (kein Neustart).
- Gegeben: „Stille" ausgewählt. Wenn: nichts. Dann: keine Lautstärke-Karte, stattdessen Hinweis.

### AK: Eigene Klänge
- Gegeben: keine eigenen Dateien. Wenn: nichts. Dann: gestrichelte Leer-Karte mit Hinweistext; darunter Import-Button.
- Gegeben: Import-Button tippen. Dann: Document-Picker öffnet; nach Import erscheint die Datei unter MEINE KLÄNGE als Karten-Zeile (Vorhören + Wellenform + Häkchen, automatisch ausgewählt).
- Gegeben: eigene, nicht ausgewählte Datei. Wenn: Entfernen-Symbol antippen. Dann: Bestätigungsdialog „Datei entfernen?" (inkl. Nutzungs-Warnung falls verwendet); bestätigt → Datei weg, ggf. Reset auf Default.

### AK: Reduce Motion
- Gegeben: Reduce Motion an, Vorschau läuft. Dann: Glow und Equalizer stehen still (Balken statisch, Button-Glow aus); Funktion bleibt.

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **Audio-Layer:** `AudioServiceProtocol`/`AudioService` — Loop-Vorschau ohne Auto-Stop + `setBackgroundPreviewVolume`; Mock erweitern. (Grundlage, gut isoliert testbar.)
2. **ViewModel:** Toggle-Logik (welcher Klang spielt) + Live-Lautstärke + Auswahl/Stille-Verhalten. Unit-Tests gegen MockAudioService.
3. **Komponenten:** `ScapeWaveform` (Hüllkurven/Equalizer/flache Linie) → `ScapePreviewButton` (Toggle/Glow/Mute) → `ScapeSoundRow`. Logik (Hüllkurven-Mapping, Balkenhöhe) als reine Funktionen unit-testbar.
4. **View:** `BackgroundSoundSelectionView` neu zusammensetzen (Sections, Intro, Empty-Card, Import, Entfernen-Dialog).
5. **Lokalisierung & Accessibility:** Strings DE+EN, Labels.

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Änderung an `playBackgroundPreview` bricht anderen Aufrufer | Vor Änderung alle Aufrufer per Grep prüfen; nur dieser Screen erwartet. Bestehende `startBackgroundAudio` (Timer-Loop) NICHT anfassen. |
| `GongVolumeCard` accessibilityIdentifier kollidiert (`gongVolume`) | Identifier/Title parametrisieren oder dedizierte Background-Variante. |
| Dauer-Loop-Vorschau läuft beim Verlassen weiter | `onDisappear` ruft `stopAllPreviews()` (bereits vorhanden) + State zurücksetzen. |
| Lock-Screen-Lifecycle | Reiner Vordergrund-Einstellungs-Screen; Tab-Wechsel/Verlassen stoppt Vorschau. Kein Lock-Screen-Pfad betroffen. |

## Offene Fragen

- Keine. (Eigene-Klänge-Verhalten durch Handoff-Update geklärt.)
