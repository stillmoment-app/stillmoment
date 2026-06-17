# Implementierungsplan: shared-118 (Android)

Ticket: [shared-118](../shared/shared-118-intervall-gong-editor-redesign.md)
Erstellt: 2026-06-17

## Annahmen

- **Layout-Struktur** (analog `SelectGongScreen`, mit interval-spezifischer Ergänzung):
  1. Master-Toggle „Interval Gongs" als oberste Karte (`GongCard`-Zeile).
  2. Wenn aktiviert, darunter (in einer `LazyColumn`):
     - Eyebrow „INTERVALL" + Karte mit Minuten-Stepper-Zeile und Modus-Auswahl-Zeile (`SegmentedButtonRow`).
     - Eyebrow „KLANG" + `GongSoundCard` (`GongSound.allIntervalSounds`, `testTagPrefix = "intervalEditor"`).
     - Wenn nicht Vibration: Eyebrow „LAUTSTÄRKE" + `GongVolumeCard`. Wenn Vibration: `VibrationHelper`-Text.
- **Lautstärke bleibt manueller Slider** (kein Auto-Level — beim stillen Timer keine Stimme zur Ableitung).
- **Modus-Auswahl bleibt** die bestehende `SegmentedButtonRow` (3 Modi), nur in eine Karten-Zeile überführt.
- **Vibrations-Filter** über `smallestScreenWidthDp < 600` (`PHONE_MAX_WIDTH_DP`) wie in `SelectGongScreen`.
- `GongSoundCard` ist bereits parametrisiert (`testTagPrefix`) und enthält `GongWaveform` → direkte Wiederverwendung, **kein** eigenes `IntervalSoundRow` mehr nötig.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `presentation/ui/timer/IntervalGongsEditorScreen.kt` | Presentation | Umbau | `IntervalSoundsList`/`IntervalSoundRow` (ohne Wellenform) → `GongSoundCard`; Layout auf Eyebrow-Karten analog `SelectGongScreen`; Stepper+Modus in eigene Karte; Lautstärke → `GongVolumeCard` |
| `presentation/ui/timer/SelectGongScreen.kt` | Presentation | Referenz/ggf. Extraktion | `EyebrowLabel`, `VibrationHelper` sind dort `private` — siehe Design-Entscheidung |
| `presentation/ui/timer/components/GongSoundPicker.kt` (`GongSoundCard`) | Presentation | Wiederverwenden | Karten-Klang-Picker inkl. Wellenform/Preview/Häkchen |
| `presentation/ui/timer/components/GongVolumeCard.kt` | Presentation | Wiederverwenden | Lautstärke-Karte |
| `presentation/ui/timer/GongSelectionLogic.kt` (`isVolumeCardVisible`) | Presentation | Wiederverwenden | Sichtbarkeit Lautstärke-Karte |
| `presentation/ui/timer/components/GongCard.kt` | Presentation | Wiederverwenden | Karten-Hintergrund für INTERVALL-/Toggle-Karte |
| `presentation/viewmodel/PraxisSettingsViewModel.kt` | Presentation | Unverändert | `setIntervalSoundId`, `playIntervalGongPreview`, `stopPreviews` etc. bleiben |
| `res/values*/strings.xml` (de/en) | Presentation | Ergänzen | Neue Eyebrow-Keys für „INTERVALL" |
| Tests (`IntervalGongsEditorScreen`-bezogen) | Tests | Prüfen/Anpassen | Preview-testTag bleibt `intervalEditor.preview.<id>` (von `GongSoundCard` via Prefix erzeugt) — Selektoren prüfen |

## Design-Entscheidungen

### 1. `EyebrowLabel` / `VibrationHelper` — extrahieren vs. duplizieren
Beide sind in `SelectGongScreen.kt` `private`. Der Intervall-Screen braucht dieselben.
**Entscheidung:** In eine geteilte Datei extrahieren (z.B. `components/GongSectionLabel.kt`) und in beiden Screens nutzen — vermeidet Duplikat und Drift. `EyebrowLabel` ist trivial, aber zweimal identisch gepflegt zu werden lädt zu Inkonsistenz ein. Falls Extraktion im Review als Overkill gilt → Duplizieren akzeptabel.

### 2. Preview-Ring-State
`SelectGongScreen` hält `previewingSoundId` + `previewTick` + `LaunchedEffect`.
**Entscheidung:** Gleiches Muster im `IntervalGongsEditorScreen` spiegeln; Preview ruft `viewModel.playIntervalGongPreview(soundId)`.

## Fachliche Szenarien

### AK-1/AK-2: Klang-Auswahl als Karten-Liste
- Gegeben: Interval-Gongs aktiviert. Wenn: Screen sichtbar. Dann: `GongSoundCard` mit Vorhör-Button, Name, Mini-Wellenform pro Klang; gewählte Zeile getönt + Häkchen — identisch zum Start/Ende-Screen.

### AK-3: Auswahl + Vorschau-Interaktion
- Gegeben: ein Klang gewählt. Wenn: andere Zeile getippt. Dann: Auswahl wechselt + Vorschau + Ring ~1,5 s.
- Wenn: nur Vorhör-Button getippt. Dann: nur Vorschau, Auswahl unverändert.

### AK-4: Interval-Controls erhalten
- Stepper (1–60) + Modus-Auswahl funktionieren wie bisher, Auto-Save bleibt.

### AK-5/AK-6: Vibration
- „Vibration" gewählt → keine Lautstärke-Karte, Helper-Text; auf Tablets keine Vibrations-Option.

### AK-7: Auto-Save
- Werte überleben Verlassen/Wiederöffnen des Screens.

## Reihenfolge der Akzeptanzkriterien

1. (Optional) `EyebrowLabel`/`VibrationHelper` extrahieren.
2. Grundgerüst: Layout auf Eyebrow-Karten umstellen, Master-Toggle + INTERVALL-Karte (Stepper+Modus), Verhalten erhalten.
3. KLANG: `IntervalSoundsList`/`IntervalSoundRow` → `GongSoundCard` + Preview-Ring (AK-1/2/3).
4. LAUTSTÄRKE: → `GongVolumeCard` + `VibrationHelper` (AK-5/6).
5. Lokalisierung + Tests/Selektoren nachziehen.

## Offene Fragen

- Keine — Ansatz folgt dem etablierten `SelectGongScreen`.
