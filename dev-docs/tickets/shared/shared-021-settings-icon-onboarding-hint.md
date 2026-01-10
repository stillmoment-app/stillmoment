# Ticket shared-021: Settings-Icon und Onboarding-Hint

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~1h | Android ~1h
**Phase**: 4-Polish

---

## Was

Das Settings-Icon im Timer von Kebab-Menue (drei Punkte) zu Slider-Icon aendern und einen einmaligen Onboarding-Hint hinzufuegen, der beim ersten App-Start auf die Einstellungen hinweist.

## Warum

Das Kebab-Menue (drei vertikale Punkte) ist mehrdeutig - Nutzer assoziieren es mit "Mehr Optionen" statt "Einstellungen". Das Slider-Icon (`slider.horizontal.3` / Material `Tune`) ist selbsterklaerend fuer Konfiguration. Der einmalige Hint macht das Feature fuer Erstnutzer discoverable, ohne dauerhaft Platz zu verschwenden.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Settings-Icon ist ein Slider/Regler-Symbol statt drei Punkte
- [x] Beim ersten App-Start erscheint ein Tooltip/Hint links neben dem Icon (Fade-in Animation)
- [x] Hint-Text erklaert kurz die Funktion (z.B. "Passe Klaenge & Gongs an")
- [x] Hint bleibt sichtbar bis User auf Settings-Icon tippt (Fade-out bei Dismiss)
- [x] Hint erscheint nur einmal (persistiert via UserDefaults/SharedPreferences)
- [x] Lokalisiert (DE + EN)
- [x] Visuell konsistent zwischen iOS und Android
- [x] Farben aus bestehendem Design System (keine hardcoded Werte)

### Accessibility (beide Plattformen)
- [x] Settings-Icon hat korrektes Accessibility Label ("Einstellungen" / "Settings")
- [x] Hint ist fuer VoiceOver (iOS) / TalkBack (Android) zugaenglich
- [x] Hint-Text wird als Accessibility-Announcement vorgelesen

### Tests
- [x] Unit Tests iOS (Hint-State Persistenz)
- [x] Unit Tests Android (Hint-State Persistenz)

### Dokumentation
- [x] CHANGELOG.md (nicht noetig fuer Polish-Ticket)

---

## Manueller Test

### Erststart-Szenario
1. App-Daten loeschen / Fresh Install
2. App oeffnen
3. Erwartung: Slider-Icon oben rechts, Tooltip erscheint mit Hint-Text
4. Auf Icon tippen
5. Erwartung: Settings oeffnen sich, Hint verschwindet

### Wiederholter Start
1. App schliessen und neu oeffnen
2. Erwartung: Slider-Icon sichtbar, KEIN Hint mehr

### Persistenz-Szenario
1. Fresh Install, App oeffnen
2. Hint erscheint, App schliessen (ohne Settings zu oeffnen)
3. App neu starten
4. Erwartung: Hint erscheint erneut (da Settings noch nie geoeffnet wurden)

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Icon | `slider.horizontal.3` (SF Symbol) | `Icons.Default.Tune` (Material) |
| Hint-Style | Popover/Tooltip | Tooltip/Snackbar |
| Animation | Fade out | Fade out |

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Timer/TimerView.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/timer/`

---

## Hinweise

- iOS: `@AppStorage("hasSeenSettingsHint")` fuer Persistenz
- Android: `SharedPreferences` oder DataStore
- Hint-Position: Tooltip zeigt auf das Icon, Pfeil nach oben/rechts
