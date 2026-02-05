# Ticket shared-033: Theme-Paletten finalisieren

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 4-Polish

---

## Was

Die 3 Placeholder-Farbpaletten (Warm Desert Dark, Kerzenschein Light, Kerzenschein Dark) sollen iterativ mit MCP-Screenshots zu echten, stimmigen Paletten ueberarbeitet werden. Insbesondere muss sich Kerzenschein Light deutlich von Warm Desert Light unterscheiden - aktuell sind die beiden Paletten fast identisch.

## Warum

User mit System Dark Mode sehen aktuell Placeholder-Farben, die nicht bewusst gestaltet wurden. Ausserdem ist der Kerzenschein-Light-Modus kaum vom Default-Theme unterscheidbar - ein Theme-Wechsel muss einen sichtbaren Unterschied machen, sonst ist die Funktion wertlos.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-032    |
| Android   | [ ]    | shared-032    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Warm Desert Dark: Stimmige dunkle Variante mit warmen Erdtoenen
- [ ] Kerzenschein Light: Deutlich unterscheidbar von Warm Desert Light (nicht nur minimal andere Akzentfarbe)
- [ ] Kerzenschein Dark: Tiefes Dunkel mit warmem Akzent - wie Meditation bei Kerzenschein
- [ ] Alle 4 Paletten sind visuell unterscheidbar
- [ ] Gradient, Buttons, Text, TabBar, Timer-Ring sehen in jeder Palette stimmig aus
- [ ] Kontrast-Verhaeltnisse fuer Lesbarkeit eingehalten (WCAG AA)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Bestehende Tests bleiben gruen (Paletten-Uniqueness-Test)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. System Dark Mode aktivieren
2. App starten mit Warm Desert Theme
3. Erwartung: Dunkle Variante sieht durchdacht und stimmig aus
4. Zu Kerzenschein wechseln
5. Erwartung: Deutlich andere Farbstimmung, bernsteinfarbener Akzent
6. System Dark Mode deaktivieren
7. Erwartung: Kerzenschein Light ist warm und unterscheidbar von Warm Desert Light
8. Alle Screens pruefen: Timer, Focus Mode, Settings, Library, Player, Edit Sheet

---

## Hinweise

- Iterativer Design-Prozess: Farbwerte mit MCP-Screenshots testen und anpassen
- Warm Desert Light (Default) bleibt unveraendert - nur die 3 anderen Paletten werden ueberarbeitet
- Farbwerte liegen zentral an einer Stelle, Aenderungen betreffen nur diese Datei

---
