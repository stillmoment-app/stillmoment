# Ticket android-073: PraxisEditor Auto-Save beim Zurücknavigieren

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Der PraxisEditor soll Änderungen automatisch beim Zurücknavigieren speichern, statt explizite "Abbrechen"- und "Fertig"-Buttons im TopAppBar zu verwenden.

## Warum

iOS speichert die Konfiguration implizit beim Verlassen des Screens (Settings-Style). Android hingegen erfordert aktuell einen expliziten "Fertig"-Tap. Dieses unterschiedliche Mental Model verwirrt User, die beide Plattformen nutzen. Der einheitliche Ansatz – Zurück = Speichern – ist konsistenter und reduziert die kognitive Last.

---

## Akzeptanzkriterien

### Feature
- [ ] Der TopAppBar des PraxisEditors zeigt einen Zurück-Pfeil statt "Abbrechen"/"Fertig"-Buttons
- [ ] Beim Zurücknavigieren (System-Back oder Zurück-Pfeil) werden Änderungen automatisch gespeichert
- [ ] Das Verhalten entspricht dem iOS-PraxisEditor (Zurück = Speichern)

### Tests
- [ ] Unit Tests prüfen, dass Save beim Verlassen des Screens ausgelöst wird

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. PraxisEditor öffnen, eine Einstellung ändern (z.B. Gong-Sound)
2. System-Back-Button drücken (ohne explizites "Fertig")
3. Erwartung: Änderung ist gespeichert und beim erneuten Öffnen sichtbar

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Timer/PraxisEditorView.swift` (auto-save via `onChange(of: navigateToEditor)`)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/PraxisEditorScreen.kt`

---
