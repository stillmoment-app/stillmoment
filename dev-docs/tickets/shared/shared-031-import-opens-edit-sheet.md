# Ticket shared-031: Edit Sheet nach Import oeffnen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~15min | Android ~15min
**Phase**: 4-Polish

---

## Was

Nach dem Import einer gefuehrten Meditation soll sich automatisch das Edit Sheet oeffnen, damit der User Titel und Lehrer*in direkt anpassen kann.

## Warum

ID3-Tags in Audio-Dateien sind oft unvollstaendig, falsch oder generisch ("Track 01", "Unknown Artist"). Der User muss die Meditation nach dem Import muehsam in der Liste suchen und ueber das Overflow-Menue bearbeiten. Mit dem direkten Oeffnen des Edit Sheets kann er die Metadaten sofort korrigieren.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Nach erfolgreichem Import oeffnet sich automatisch das Edit Sheet
- [ ] Edit Sheet zeigt die importierte Meditation mit ihren ID3-Metadaten
- [ ] User kann Titel und Lehrer*in anpassen und speichern
- [ ] Bei Abbruch (Cancel) wird die Meditation trotzdem in der Library angezeigt
- [ ] Bei Import-Fehler wird kein Edit Sheet geoeffnet (nur Fehlermeldung)

### Tests
- [ ] Unit Test iOS: Import oeffnet Edit Sheet
- [ ] Unit Test Android: Import oeffnet Edit Sheet

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. App starten, zu "Gefuehrte Meditationen" navigieren
2. Plus-Button antippen, Audio-Datei auswaehlen
3. Erwartung: Edit Sheet oeffnet sich automatisch mit Titel und Lehrer aus ID3-Tags
4. Titel oder Lehrer aendern, "Speichern" antippen
5. Erwartung: Meditation erscheint in Library mit geaenderten Daten

---

## Hinweise

- Edit Sheet Infrastruktur existiert bereits auf beiden Plattformen
- Die importierte Meditation wird vom Service/Repository zurueckgegeben und kann direkt verwendet werden
