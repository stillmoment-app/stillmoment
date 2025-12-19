# Ticket android-021: Player zeigt nicht effectiveName/effectiveTeacher

**Status**: [ ] TODO
**Prioritaet**: KRITISCH
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 1-Quick Fix

---

## Was

Im Player-Screen werden `meditation.teacher` und `meditation.name` direkt angezeigt statt `meditation.effectiveTeacher` und `meditation.effectiveName`. Dadurch werden benutzerdefinierte Anpassungen (customTeacher/customName) ignoriert.

## Warum

Wenn ein User eine Meditation umbenennt oder den Lehrer aendert, erwartet er, dass diese Aenderungen ueberall angezeigt werden - auch im Player. Das ist ein Usability-Bug der die Edit-Funktion teilweise nutzlos macht.

---

## Akzeptanzkriterien

- [ ] Player zeigt `meditation.effectiveTeacher` statt `meditation.teacher`
- [ ] Player zeigt `meditation.effectiveName` statt `meditation.name`
- [ ] Accessibility-Labels nutzen ebenfalls effectiveTeacher/effectiveName
- [ ] Unit Tests fuer effectiveTeacher/effectiveName-Logik (falls nicht vorhanden)

---

## Manueller Test

1. Meditation importieren (z.B. "meditation.mp3" von "Unbekannt")
2. Meditation bearbeiten: Teacher = "Tara Brach", Name = "Loving Kindness"
3. Meditation antippen -> Player oeffnen
4. Erwartung: Header zeigt "Tara Brach" und "Loving Kindness" (nicht "Unbekannt" und "meditation")

---

## Referenz

- Problem: `GuidedMeditationPlayerScreen.kt` Zeilen 225-251
- iOS-Referenz: `GuidedMeditationPlayerView.swift` Zeilen 40-54 (korrekte Verwendung)
- Model: `GuidedMeditation.kt` - `effectiveTeacher` und `effectiveName` Properties

---

## Hinweise

Die Properties `effectiveTeacher` und `effectiveName` existieren bereits im GuidedMeditation-Model und geben customTeacher/customName zurueck falls gesetzt, sonst die Original-Werte.
