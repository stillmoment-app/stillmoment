# Implementierungsplan: shared-112 (iOS)

Ticket: [shared-112](../shared/shared-112-trim-zurueck-dirtied-editor.md)
Erstellt: 2026-06-14

## Annahmen

- **Eine Closure statt zwei.** Da der Trim-Editor nur noch einen Weg zurück kennt (Auswahl
  übernehmen), wird die separate `onCancel`-Closure entfernt und `onDone` in `onBack`
  umbenannt. Begründung: Ein `onDone`, das vom Zurück-Chevron ausgelöst wird, wäre für
  Leser irreführend (es gibt kein „Fertig" mehr). Einziger Call-Site ist
  `GuidedMeditationEditSheet` plus drei Previews — der Rename ist lokal begrenzt.
- **`trim_editor.done` wird ungenutzt** und aus beiden `.strings`-Dateien entfernt (keine
  Karteileiche).
- **Kein neuer Test-Seam nötig.** Die „Übernahme in den Puffer" ist eine View-Closure-
  Zuweisung (`editState.editedTrimStart = start`). Die dahinterliegende Dirty-Semantik
  (`hasChanges` reagiert auf Trim-Änderung) ist Domain-Logik in `EditSheetState` und
  bereits getestet (`EditSheetStateTrimTests`). Der Plan ergänzt einen fachlichen Test,
  der das Zurück-Szenario explizit dokumentiert.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Presentation/.../TrimEditor/TrimEditorSheet.swift` | Presentation | Ändern | „Fertig"-Button entfernen; Zurück-Chevron ruft neue `onBack`-Closure mit `resultTrimStart/End`; `onCancel` entfernen; A11y-Label neutralisieren; Previews anpassen |
| `Presentation/.../GuidedMeditationEditSheet.swift` | Presentation | Ändern | `trimEditorSheet`: `onDone`/`onCancel` → ein `onBack` das die Werte in den Puffer schreibt und schließt |
| `Resources/de.lproj/Localizable.strings` | Resources | Ändern | `trim_editor.a11y.back` neutral; `trim_editor.done` entfernen |
| `Resources/en.lproj/Localizable.strings` | Resources | Ändern | dito |
| `StillMomentTests/EditSheetStateTrimTests.swift` | Tests | Erweitern | Test „Zurück übernimmt Auswahl → Editor verändert" auf State-Ebene |

## API-Recherche

Keine — reine SwiftUI-View-/Closure-Änderung, keine neuen Framework-APIs.

## Fachliche Szenarien

### AK: Nur ein „Zurück"-Button, kein „Fertig"/„Verwerfen"
- Gegeben: Trim-Editor ist offen
  Wenn: Nutzer betrachtet die Navigationszeile
  Dann: Es gibt genau einen Zurück-Chevron, keinen „Fertig"- und keinen „Verwerfen"-Button

### AK: „Zurück" übernimmt die Auswahl in den Puffer
- Gegeben: Editor ohne Schnitt, Trim geöffnet, Nutzer setzt Start auf 0:30
  Wenn: Nutzer tippt „Zurück"
  Dann: Wiedergabe-Bereich des Editors zeigt den Schnitt; Editor ist als verändert markiert

### AK: Geänderter Schnitt markiert den Editor als verändert (Dirty)
- Gegeben: Schnitt im Trim verändert, „Zurück" getippt
  Wenn: Nutzer verlässt den Editor mit X
  Dann: Discard-Rückfrage des Editors erscheint (§3) — keine zweite, eigene Trim-Rückfrage

### AK: Unveränderte Auswahl macht den Editor nicht dirty
- Gegeben: Editor ohne Schnitt, Trim geöffnet, nichts verändert
  Wenn: Nutzer tippt „Zurück"
  Dann: Editor bleibt unverändert (X schließt ohne Rückfrage)

### AK: „Ganze Datei verwenden" bleibt der Reset *innerhalb* von Trim
- Gegeben: getrimmte Meditation, Trim geöffnet
  Wenn: Nutzer tippt „Ganze Datei verwenden", dann „Zurück"
  Dann: Schnitt ist im Puffer entfernt (nil/nil); war original kein Schnitt gesetzt, ist der Editor wieder unverändert

### AK: A11y-Label neutral
- Gegeben: Trim-Editor offen
  Wenn: VoiceOver liest den Zurück-Button
  Dann: Label lautet „Zurück" (nicht „Zurück, Änderungen verwerfen")

## Reihenfolge der Akzeptanzkriterien

1. **State-Test** — Test dokumentiert „Zurück übernimmt Auswahl → hasChanges" (baut auf vorhandener `EditSheetState`-Logik, kein Produktionscode nötig — grün ab Start, dient als Regressionsanker).
2. **TrimEditorSheet umbauen** — Button-Logik, Closure-Rename, A11y-Label.
3. **GuidedMeditationEditSheet verdrahten** — `onBack` schreibt Puffer + schließt.
4. **Lokalisierung** — Key neutralisieren, ungenutzten Key entfernen.

## Offene Fragen

Keine.
