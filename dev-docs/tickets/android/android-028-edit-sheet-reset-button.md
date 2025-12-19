# Ticket android-028: Edit Sheet Reset-Button

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Reset-Button im MeditationEditSheet hinzufuegen, der Felder auf Original-Werte zuruecksetzt.

## Warum

iOS hat dieses Feature, Android nicht. User erwarten konsistentes Verhalten auf beiden Plattformen. Der Reset-Button ermoeglicht schnelles Zuruecksetzen ohne manuelles Loeschen.

---

## Akzeptanzkriterien

- [x] Reset-Button unterhalb der Eingabefelder
- [x] Button ist disabled wenn keine Aenderungen vorliegen
- [x] Klick setzt Teacher und Name auf Original-Werte zurueck
- [x] Button hat destructive Styling (rot/warning)
- [x] Lokalisiert (DE + EN)

---

## Manueller Test

1. Meditation importieren
2. Edit Sheet oeffnen
3. Teacher und Name aendern
4. Reset-Button antippen
5. Erwartung: Felder zeigen wieder Original-Werte

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift` - Zeilen 119-126

---

<!-- Erstellt via View Quality Review -->
