# Implementierungsplan: shared-118 (iOS)

Ticket: [shared-118](../shared/shared-118-intervall-gong-editor-redesign.md)
Erstellt: 2026-06-17

## Annahmen

- **Layout-Struktur** (analog `GongSelectionView`, mit interval-spezifischer Ergänzung):
  1. Master-Toggle „Intervall-Gongs" als oberste Karte (eigene Karten-Zeile via `GongCardBackground`).
  2. Wenn aktiviert, darunter:
     - Eyebrow „INTERVALL" + Karte mit Minuten-Stepper-Zeile und Modus-Auswahl-Zeile.
     - Eyebrow „KLANG" + Karte mit `GongSoundRow`-Liste (`GongSound.allIntervalSounds`).
     - Wenn nicht Vibration: Eyebrow „LAUTSTÄRKE" + `GongVolumeCard`. Wenn Vibration: Helper-Text (analog `vibrationHelper`).
- **Lautstärke bleibt manueller Slider** (kein Auto-Level wie in der Handoff-Vorlage für gefuehrte Meditationen — beim stillen Timer existiert keine Stimme zur Ableitung).
- **Modus-Picker bleibt segmentierter Picker** (`.segmented`), nur in eine Karten-Zeile überführt. Kein Wechsel zu Menü/Liste.
- **Vibrations-Filter** über `UIDevice.current.userInterfaceIdiom == .phone` bleibt wie gehabt (`availableIntervalSounds`).
- Eigene Eyebrow-Lokalisierungs-Keys für den Intervall-Screen (z.B. `praxis.intervalGongs.section.interval`, `.sound`, `.volume`) statt Wiederverwendung der Start/Ende-Keys, weil die Sektion „INTERVALL" neu ist. „KLANG"/„LAUTSTÄRKE" können die bestehenden `praxis.gong.section.sound` / `praxis.gong.section.volume` wiederverwenden.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `Presentation/Views/Timer/IntervalGongsEditorView.swift` | Presentation | Umbau | `Form` → `ScrollView`+Karten; `intervalSoundPicker` (Menü) → `GongSoundRow`-Karten-Liste mit Preview/Ring; Stepper + Modus in eigene Karte; Lautstärke als `GongVolumeCard` statt `VolumeSliderRow` |
| `Presentation/Views/Timer/GongSelectionView.swift` | Presentation | Referenz | Vorlage für Aufbau (soundSection, soundCard, volumeSection, preview-Ring-Logik) |
| `Presentation/Views/Timer/Components/GongSoundRow.swift` | Presentation | Wiederverwenden | Klang-Zeile (Preview, Name, Wellenform, Häkchen) |
| `Presentation/Views/Timer/Components/GongCardBackground.swift` | Presentation | Wiederverwenden | Karten-Hintergrund für alle Karten |
| `Presentation/Views/Timer/Components/GongVolumeCard.swift` | Presentation | Wiederverwenden | Lautstärke-Karte |
| `Presentation/Views/Timer/Components/GongSelectionLogic.swift` | Presentation | Wiederverwenden | `isVolumeCardVisible(soundId:)` |
| `Application/ViewModels/PraxisSettingsViewModel.swift` | Application | Unverändert | `intervalGongsEnabled/Minutes/Mode/SoundId/Volume`, `playIntervalGongPreview`, `stopAllPreviews` bleiben |
| `Resources/*.lproj/Localizable.strings` (de/en) | Presentation | Ergänzen | Neue Eyebrow-Keys für „INTERVALL"-Sektion |
| `StillMomentTests/...IntervalGongs*`, UI-Tests | Tests | Prüfen/Anpassen | Selektoren: alter `picker.intervalSound` entfällt → Zeilen-/Preview-Selektoren analog Start/Ende |

## Design-Entscheidungen

### 1. Preview-Ring-Logik duplizieren vs. extrahieren
`GongSelectionView` hält `previewingSoundId` + `previewTask` lokal (1,5 s Ring). Der Intervall-Editor braucht dasselbe.
**Entscheidung:** Logik lokal im `IntervalGongsEditorView` spiegeln (kleiner, klarer State; keine verfrühte Abstraktion). Falls Review eine Extraktion bevorzugt → Follow-up. Preview ruft `playIntervalGongPreview` (nicht `playGongPreview`), damit Intervall-spezifisches Audio/Default greift.

### 2. Stepper/Modus-Karte
**Entscheidung:** Eine Karte (`GongCardBackground`) mit zwei Zeilen: Stepper-Zeile (Label + Wert + Stepper) und Modus-Zeile (segmentierter Picker, ggf. mit kleinem Label darüber). Divider zwischen den Zeilen analog `soundCard`.

## Fachliche Szenarien

### AK-1/AK-2: Klang-Auswahl als Karten-Liste
- Gegeben: Intervall-Gongs aktiviert. Wenn: Screen sichtbar. Dann: Karten-Liste mit Vorhör-Button, Name, Mini-Wellenform pro Klang; gewählte Zeile getönt + Häkchen — optisch identisch zum Start/Ende-Screen.

### AK-3: Auswahl + Vorschau-Interaktion
- Gegeben: „Tempelglocke" gewählt. Wenn: User tippt Zeile „Klassisch". Dann: „Klassisch" wird getönt/gehäkchent, Vorschau spielt, Ring ~1,5 s.
- Gegeben: „Tempelglocke" gewählt. Wenn: User tippt nur den Vorhör-Button von „Klassisch". Dann: nur Vorschau, Auswahl bleibt „Tempelglocke".

### AK-4: Interval-Controls erhalten
- Gegeben: Screen sichtbar. Wenn: User ändert Minuten via Stepper / Modus via Picker. Dann: Werte ändern sich, Haptik wie bisher, Auto-Save persistiert.

### AK-5/AK-6: Vibration
- Gegeben: „Vibration" gewählt. Dann: Lautstärke-Karte verschwindet, Helper-Text erscheint. Auf iPad ist „Vibration" nicht in der Liste.

### AK-7: Auto-Save
- Gegeben: Klang/Minuten/Modus/Lautstärke geändert. Wenn: Screen verlassen + erneut geöffnet. Dann: Werte erhalten.

## Reihenfolge der Akzeptanzkriterien

1. Grundgerüst: `Form` → `ScrollView`+Karten, Master-Toggle, INTERVALL-Karte (Stepper+Modus) — Verhalten der bestehenden Controls erhalten.
2. KLANG-Karte: `intervalSoundPicker` → `GongSoundRow`-Liste + Preview-Ring (AK-1/2/3).
3. LAUTSTÄRKE: `VolumeSliderRow` → `GongVolumeCard` + Vibration-Helper (AK-5/6).
4. Lokalisierung + Selektoren/Tests nachziehen (AK-4/7).

## Offene Fragen

- Keine — Ansatz folgt 1:1 dem etablierten Start/Ende-Gong-Screen.
