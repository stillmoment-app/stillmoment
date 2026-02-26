# Ticket android-065: Dauer-Picker aus PraxisEditor entfernen

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die `DurationSection` (Dauer-WheelPicker) im PraxisEditorScreen entfernen. Die Dauer ist bereits auf dem Timer-Hauptscreen einstellbar und soll dort als einzige Stelle bleiben.

## Warum

Die Dauer erscheint aktuell zweimal: einmal auf dem Timer-Hauptscreen (WheelPicker) und nochmals im PraxisEditor (ebenfalls WheelPicker). Das ist redundant und verwirrend. iOS zeigt die Dauer nur auf dem Hauptscreen — nicht im Settings/Editor-Flow. Das iOS-Muster ist eindeutiger: Der Hauptscreen ist der Ort fuer "Wie lang?", der Editor ist der Ort fuer "Wie konfiguriert?".

---

## Akzeptanzkriterien

### Feature
- [x] `DurationSection` Composable aus `PraxisEditorScreen.kt` entfernt
- [x] `onDurationChange`-Parameter aus `EditorContent` entfernt
- [x] `viewModel::setDurationMinutes`-Bindung aus `PraxisEditorScreen` entfernt
- [x] `PraxisEditorViewModel.setDurationMinutes()` entfernt; `durationMinutes` bleibt in UiState und init (fuer save())
- [x] Der Praxis-Editor speichert beim Speichern die im Hauptscreen gewaehlte Dauer weiterhin korrekt (nicht ueberschreiben)
- [x] Kein visueller Leerraum wo die Dauer war (Spacing anpassen)

### Tests
- [x] Bestehende PraxisEditor-Tests laufen durch
- [x] `make test` gruen

### Dokumentation
- [x] Keine

---

## Manueller Test

1. App starten, Timer-Tab oeffnen
2. Dauer auf z.B. 15 Minuten stellen
3. Pills antippen → PraxisEditor oeffnen
4. Erwartung: Kein Dauer-Picker sichtbar; Editor beginnt mit Vorbereitung
5. Speichern, zurueck zum Timer: Dauer ist noch 15 Minuten

---

## Referenz

- `android/app/src/main/kotlin/.../timer/PraxisEditorScreen.kt` Zeile 149 (`DurationSection`) und 229 (Composable-Definition)
- `android/app/src/main/kotlin/.../viewmodel/PraxisEditorViewModel.kt` Zeile 104 (`setDurationMinutes`)
- iOS: `PraxisEditorView.swift` — hat keinen Dauer-Picker
