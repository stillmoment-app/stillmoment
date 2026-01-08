# Ticket shared-017: Background-Audio Preview in Settings

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~1h | Android ~1h
**Phase**: 3-Feature

---

## Was

Bei der Auswahl eines Background-Sounds in den Timer-Settings soll ein kurzer Preview (3 Sekunden) mit sanftem Fade-Out abgespielt werden - analog zur bestehenden Gong-Preview-Funktion.

## Warum

Konsistente User Experience: User koennen bereits Gong-Sounds vor der Auswahl anhoeren. Die gleiche Moeglichkeit fuer Background-Sounds verbessert die Entscheidungsfindung und reduziert "Trial and Error" waehrend der Meditation.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Bei Auswahl eines Background-Sounds startet automatisch ein Preview
- [x] Preview dauert ca. 3 Sekunden mit sanftem Fade-Out am Ende
- [x] Preview stoppt sofort wenn ein anderer Background-Sound ausgewaehlt wird
- [x] Preview stoppt sofort wenn ein Gong-Sound ausgewaehlt wird (gegenseitiges Stoppen)
- [x] Preview stoppt wenn die Settings geschlossen werden
- [x] Preview verwendet die konfigurierte Lautstaerke des jeweiligen Sounds

### Tests
- [x] Unit Tests iOS
- [x] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. Timer-Tab oeffnen, Settings oeffnen
2. Background-Sound Picker antippen
3. Verschiedene Sounds auswaehlen
4. Erwartung: Jeder Sound spielt ~3s Preview, dann Fade-Out
5. Schnell zwischen Sounds wechseln
6. Erwartung: Vorheriger Preview stoppt sofort
7. Background-Sound auswaehlen, dann Gong-Sound auswaehlen
8. Erwartung: Background-Preview stoppt bei Gong-Auswahl
9. Preview starten, Settings schliessen
10. Erwartung: Preview stoppt sofort

---

## Referenz

- iOS: Gong-Preview bereits implementiert in AudioService (`playGongPreview`/`stopGongPreview`)
- Android: Gong-Preview analog implementiert

---

## Hinweise

- iOS: `previewPlayer` bereits fuer Gong-Preview vorhanden - ggf. separater Player fuer Background-Preview
- Gegenseitiges Stoppen wichtig: Gong-Preview und Background-Preview duerfen nicht gleichzeitig laufen
