# Implementierungsplan: shared-116 (iOS)

Ticket: [shared-116](../shared/shared-116-meditation-editor-gong-klang-picker.md)
Erstellt: 2026-06-15
Plattform: iOS

## Ziel in einem Satz

Im `GuidedMeditationEditSheet` die Klang-Auswahl vom Text-mit-Häkchen auf die shared-115-Klang-Zeile
(`GongSoundRow`) umstellen und dem Editor echte Section-Überschriften im Newsreader-Stil geben.

## Annahmen

- **Editor bleibt ein `Form`** (Entscheidung des Users). Die Form-Sections sind durch
  `.scrollContentBackground(.hidden)` transparent; Karten zeichnen ihre Fläche selbst.
- **Klang-Liste erhält die PlaybackRangeCard-Kartenfläche** (`cardBackground @ .opacitySecondary`,
  Radius 24, 0.5pt `cardBorder`) — nicht den Timer-`GongCardBackground` (User-Entscheidung,
  Konsistenz mit dem restlichen Editor).
- **Alle drei Überschriften** werden gesetzt; das interne Eyebrow der PlaybackRangeCard entfällt
  (User-Entscheidung).
- Die **Gong-Schalter** (`startGongToggle`/`endGongToggle`) behalten ihr aktuelles Erscheinungsbild
  (transparente Form-Zeilen). Nur die Klang-Liste bekommt eine eigene Karte — analog zu
  PlaybackRangeCard, die heute schon als einzige Karte zwischen transparenten Feldern steht.
- Die **Lautstärke-Logik** bleibt unverändert: kein Slider; Preview spielt mit
  `praxisRepository.load().gongVolume`. Der Hinweistext steht bereits im `gongHint`-Footer.
- Die **Vibration** bleibt ausgeschlossen (`GongSound.allMeditationGongSounds`).

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `Presentation/Views/GuidedMeditations/MeditationGongSoundPicker.swift` | Presentation | Umbau | Rows auf `GongSoundRow` umstellen, Preview-Ring-State, eigene Kartenfläche, „Klang"-Eyebrow |
| `Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift` | Presentation | Umbau | Section-Struktur + Newsreader-Überschriften; Preview-Ring-State an Picker durchreichen |
| `Presentation/Views/Timer/Components/GongSoundRow.swift` | Presentation | Erweitern (additiv) | `identifierPrefix: String = "praxis.gong"`-Parameter, damit Editor eigene a11y-IDs bekommt |
| `Presentation/Views/GuidedMeditations/TrimEditor/PlaybackRangeCard.swift` | Presentation | Anpassen | Internes Eyebrow „Wiedergabe-Bereich" entfernen (Chevron bleibt als Affordance) |
| `Resources/de.lproj/Localizable.strings`, `en.lproj/...` | Resources | Ergänzen | Neue Keys für die drei Überschriften + „Klang"-Label |

## API-Recherche

Keine neuen Framework-APIs. Verwendete Bausteine sind im Projekt etabliert:

| Baustein | Quelle | Hinweis |
|----------|--------|---------|
| `Section { } header: { … }` mit `.textStyle(.section)` + `.textCase(nil)` | SwiftUI / Projekt-Token | Grouped-List-Header nicht uppercasen → `.textCase(nil)` setzen |
| Preview-Ring via `Task { try? await Task.sleep(...) }` | shared-115 `GongSelectionView.preview(soundId:)` | 1:1 übernehmen, respektiert Reduce Motion über `GongPreviewButton` |
| `GongWaveform` Hüllkurven | shared-115 (statische Spec) | unverändert wiederverwenden |

## Design-Entscheidungen

### 1. Kartenfläche der Klang-Liste: PlaybackRangeCard-Stil
**Trade-off:** Timer-`GongCardBackground` (Radius 22, voll, Schatten) wäre 1:1 zum Timer-Gong-Screen,
aber kräftiger als die übrigen Editor-Karten. **Entscheidung:** PlaybackRangeCard-Stil (subtil,
Radius 24) — der Editor bleibt in sich konsistent; die Klang-*Zeilen* sind durch `GongSoundRow`
trotzdem identisch zum Timer.

### 2. a11y-Identifier parametrisieren statt hartkodieren
`GongSoundRow` kodiert heute `praxis.gong.<id>` fest; dieser Präfix ist ein Screenshot-Anker des
Timer-Screens (`ScreenshotTests.swift:305`). **Entscheidung:** additiver Parameter
`identifierPrefix` (Default `"praxis.gong"`); der Editor übergibt `"editSheet.gong"`. Kein
bestehender Test referenziert die alten `editSheet.gongSound.<id>`-IDs — Umstellung ist gefahrlos.

### 3. Section-Struktur des Editors
Neue Gliederung (Form-Sections mit `.section`-Header):

1. **Informationen** — `teacherField` + `nameField` in *einer* Section (heute zwei), Footer = File-Info.
2. **Wiedergabebereich** (nur `mode == .edit`) — `PlaybackRangeCard` ohne internes Eyebrow, Footer = Help.
3. **Zusätzlicher Gong** — `startGongToggle` + `endGongToggle`, Footer = `gongHint`.
4. **Klang** (Eyebrow-Header, nur wenn ein Gong aktiv) — Klang-Liste als eigene Karte.

## Refactorings

1. **`PlaybackRangeCard`: internes Eyebrow entfernen** — Header-Zeile behält nur den Chevron
   (oder Chevron wandert in die Datei-Zeile). Blast Radius gering: Karte wird nur im Editor
   verwendet. Previews der Karte anpassen.
   - Risiko: Niedrig. Rein visuell, keine Logikänderung.
2. **`teacherField` + `nameField` in eine Section** zusammenführen.
   - Risiko: Niedrig. `CompactSectionSpacingModifier` bleibt zuständig fürs Spacing.

## Fachliche Szenarien

### AK: Klang-Liste erscheint nur bei aktivem Gong
- Gegeben: Editor offen, beide Gong-Schalter aus
  Wenn: Nutzer schaut auf den Abschnitt „Zusätzlicher Gong"
  Dann: Keine „Klang"-Überschrift, keine Klang-Liste
- Gegeben: „Gong am Anfang" aus, „Gong am Ende" aus
  Wenn: Nutzer aktiviert „Gong am Anfang"
  Dann: „Klang"-Überschrift + Klang-Liste erscheinen

### AK: Zeile antippen wählt aus und spielt Vorschau
- Gegeben: „Tempelglocke" ist gewählt
  Wenn: Nutzer tippt die Zeile „Klangschale" an
  Dann: Auswahl wechselt zu „Klangschale" (Häkchen + Hervorhebung wandern), kurze Vorschau spielt,
  Ring-Animation am Vorhör-Button läuft ~1,5s

### AK: Nur Vorhör-Button ändert die Auswahl nicht
- Gegeben: „Tempelglocke" ist gewählt
  Wenn: Nutzer tippt *nur* den Vorhör-Button von „Klangschale"
  Dann: Vorschau „Klangschale" spielt, Auswahl bleibt „Tempelglocke"

### AK: Vibration erscheint nicht
- Gegeben: Klang-Liste sichtbar
  Wenn: Nutzer scrollt die Liste durch
  Dann: nur hörbare Gongs, keine Vibrations-Option

### AK: Konsistenz mit dem Timer
- Gegeben: Editor-Klang-Liste und Timer-„Start & Ende"-Liste
  Dann: Vorhör-Button, Name, Mini-Wellenform, Häkchen sehen identisch aus (gleiche Komponente)

### AK: Section-Überschriften
- Gegeben: Editor offen (Bearbeiten-Modus)
  Dann: „Informationen", „Wiedergabebereich", „Zusätzlicher Gong" als Newsreader-Überschriften;
  die PlaybackRangeCard zeigt ihr „Wiedergabe-Bereich"-Wort nicht mehr doppelt

## Reihenfolge der Akzeptanzkriterien (TDD-tauglich)

1. **`GongSoundRow.identifierPrefix`** (additiv) — Grundlage für Wiederverwendung im Editor.
2. **`MeditationGongSoundPicker` umbauen** — `GongSoundRow` + Preview-Ring-State + eigene Karte +
   „Klang"-Eyebrow. Sichtbarkeits-Regel (start||end) bleibt im Editor.
3. **`PlaybackRangeCard`** internes Eyebrow entfernen + Previews.
4. **`GuidedMeditationEditSheet`** Section-Struktur + Newsreader-Überschriften + Ring-State-Verdrahtung.
5. **Lokalisierung** (DE + EN) für die neuen Keys.

## Tests

Der Großteil ist Presentation-Wiring mit bereits getesteten Komponenten (`GongSoundRow`,
`GongWaveform`, `GongPreviewButton`). TDD-relevante Logik ist dünn:

- **Sichtbarkeits-Regel** „Liste nur bei aktivem Gong" als pure, testbare Eigenschaft halten
  (z.B. kleines Helper/Computed auf Basis von `editedStartGongEnabled || editedEndGongEnabled`),
  damit ein Unit-Test sie abdeckt — analog zu `GongSelectionLogic` aus shared-115.
- **Bestehende `EditSheetState`-Tests** decken Auswahl/Change-Detection für `editedGongSoundId` ab;
  bei Bedarf erweitern.
- **Visuelle Verifikation** per Screenshot (Editor mit aktivem Gong) im Review — Layout/Karten/
  Überschriften sind nicht sinnvoll unit-testbar.

## Offene Fragen

- Keine. Karten-Stil, Überschriften-Scope, Plattform sind geklärt.
