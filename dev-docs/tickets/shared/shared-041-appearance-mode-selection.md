# Ticket shared-041: Appearance Mode Selection

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 3-Feature

---

## Was

User sollen in den Settings waehlen koennen, ob die App dem System-Erscheinungsbild folgt oder immer im hellen bzw. dunklen Modus erscheint. Die Auswahl soll als Segmented Control in derselben Section wie der Theme-Picker angezeigt werden.

## Warum

Manche User bevorzugen einen festen Modus unabhaengig vom System-Setting — z.B. immer Dark Mode fuer abendliche Meditation oder immer Light Mode fuer bessere Lesbarkeit. Aktuell folgt die App ausschliesslich dem System-Setting, was keine individuelle Kontrolle erlaubt.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-032    |
| Android   | [x]    | shared-032    |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [x] Settings zeigt Segmented Control mit drei Optionen: System / Light / Dark
- [x] Segmented Control befindet sich in derselben Section wie der Theme-Picker
- [x] Default-Auswahl ist "System" (bisheriges Verhalten bleibt erhalten)
- [x] Bei "System": App folgt dem Geraete-Erscheinungsbild (wie bisher)
- [x] Bei "Light": App zeigt immer die helle Variante des gewaehlten Themes
- [x] Bei "Dark": App zeigt immer die dunkle Variante des gewaehlten Themes
- [x] Auswahl wird persistent gespeichert und bleibt nach App-Neustart erhalten
- [x] Aenderung wird sofort wirksam (ohne App-Neustart)
- [x] Lokalisiert (DE + EN)
- [x] Visuell konsistent zwischen iOS und Android

### Tests
- [x] Unit Tests iOS
- [x] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md
- [ ] GLOSSARY.md (falls neuer Domain-Begriff)

---

## Manueller Test

1. Settings oeffnen
2. Theme-Section finden
3. Segmented Control auf "Dark" setzen
4. Erwartung: App wechselt sofort in den dunklen Modus, unabhaengig vom System-Setting
5. Segmented Control auf "Light" setzen
6. Erwartung: App wechselt sofort in den hellen Modus
7. Segmented Control auf "System" setzen
8. Erwartung: App folgt wieder dem System-Erscheinungsbild
9. App beenden und neu starten
10. Erwartung: Letzte Auswahl ist weiterhin aktiv

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Settings/`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/settings/`
- Bestehendes Theme-System: shared-032

---

## Hinweise

- iOS: `preferredColorScheme(_:)` kann pro Window/Scene gesetzt werden
- Android: Compose `isSystemInDarkTheme()` und `AppCompatDelegate.setDefaultNightMode()`
- Die drei gewaehlten Farbthemen (Candlelight, Forest, Moon) haben jeweils bereits Light/Dark-Varianten

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine separaten iOS/Android Subtasks mit Code
- Keine Dateilisten (Claude Code findet die Dateien)

Claude Code arbeitet shared-Tickets so ab:
1. Liest Ticket fuer Kontext
2. Implementiert iOS (oder Android) komplett
3. Portiert auf andere Plattform mit Referenz
-->
