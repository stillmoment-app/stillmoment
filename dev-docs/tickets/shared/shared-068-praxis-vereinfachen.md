# Ticket shared-068: Praxis vereinfachen – Einzelkonfiguration

**Status**: [~] IN PROGRESS
**Prioritaet**: HOCH
**Aufwand**: iOS ~3 | Android ~4
**Phase**: 2-Architektur
**Abhaengigkeit**: shared-062, shared-064, shared-065

---

## Was

Die Praxis-Architektur auf eine einzige, benennungslose Konfiguration vereinfachen. Kein Pill-Button, kein Auswahl-Sheet, keine Presets. Stattdessen zeigt der Timer Screen unter dem Duration-Picker eine tappbare Beschreibung der aktuellen Konfiguration, die direkt in den Editor fuehrt.

## Warum

Mehrere benannte Presets erhoehen die Komplexitaet ohne klaren Mehrwert fuer eine Meditations-App. Eine einzige Konfiguration reicht fuer den typischen Use Case. Die Vereinfachung reduziert Codebase und mentale Last fuer User.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-062, shared-064 |
| Android   | [ ]    | shared-062            |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Kein Pill-Button auf dem Timer Screen (iOS)
- [x] Kein Praxis-Auswahl-Sheet (iOS)
- [x] Unter dem Duration-Picker: tappbare Konfigurationspills (iOS)
- [x] Konfigurationspills zeigen: Vorbereitung, Start-Gong, Einstimmung (falls aktiv), Hintergrundklang, Intervallgong-Status (iOS)
- [x] Duration wird NICHT in den Pills gezeigt (iOS)
- [x] Chevron-Icon rechts zeigt Tappbarkeit (iOS)
- [x] Tippen oeffnet PraxisEditorView direkt (Push-Navigation, kein Sheet) (iOS)
- [x] PraxisEditorView ohne Name-Feld (iOS)
- [x] PraxisEditorView ohne Loeschen-Button (iOS)
- [x] Navigation-Title im Editor: "Konfiguration" (DE) / "Configuration" (EN) (iOS)
- [x] Aenderungen im Editor werden sofort in der Beschreibungszeile sichtbar (iOS)
- [x] Domain-Modell Praxis ohne name-Feld (iOS)
- [x] PraxisRepository vereinfacht auf load()/save() – kein CRUD fuer mehrere Presets (iOS)
- [x] Lokalisiert (DE + EN) (iOS)
- [ ] Visuell konsistent zwischen iOS und Android (ausstehend Android)

### Tests
- [x] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. Timer Screen oeffnen → kein Pill-Button sichtbar
2. Konfigurationspills direkt unter dem Picker sichtbar (ersetzen bisherige Affirmation)
3. Beschreibung antippen → PraxisEditorView wird gepusht (kein Sheet)
4. Im Editor: kein Name-Feld, kein Loeschen-Button
5. Hintergrundklang aendern → Fertig → Beschreibung auf Timer Screen aktualisiert sich
6. App neu starten → geaenderte Konfiguration bleibt erhalten

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Editor oeffnen | NavigationLink (Push) | NavHost navigateTo |
| Beschreibungszeile | Button + .navigationDestination | Clickable Composable + NavController |

---

## iOS-Refactoring (bestehende Implementierung)

- `PraxisPillButton.swift` loeschen
- `PraxisSelectionSheet.swift` loeschen
- `PraxisSelectionViewModel.swift` loeschen
- `Praxis.swift`: name-Feld entfernen
- `PraxisRepository`: vereinfachen auf load() / save()
- `UserDefaultsPraxisRepository`: Migration aus altem Format erhalten
- `PraxisEditorViewModel`: Name-Logik + Delete-Logik entfernen
- `PraxisEditorView`: Name-Section + Delete-Section entfernen
- `TimerViewModel`: activePraxisName/displayPraxisName -> configurationDescription
- `TimerView`: PraxisPillButton ersetzen durch tappbare Konfigurationspills direkt unter dem Duration-Picker (Affirmation `duration.footer` entfernen)

## Android-Erstimplementierung (direkt vereinfacht)

- Praxis Domain-Model (ohne name-Feld)
- PraxisRepository Interface (single config: load/save)
- PraxisEditorViewModel (ohne Name, ohne Loeschen)
- PraxisEditorScreen (Compose, ohne Name-Feld, ohne Loeschen)
- Timer Screen: Beschreibungszeile unter Duration-Picker

---

## Referenz

- iOS: `ios/StillMoment/Domain/Models/Praxis.swift`
- iOS: `ios/StillMoment/Presentation/Views/Timer/`
- Android: `android/app/src/main/kotlin/com/stillmoment/`
