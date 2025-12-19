# Ticket android-034: Edit Sheet vollstaendige Previews

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

Vollstaendige Previews fuer MeditationEditSheet erstellen.

## Warum

Aktuelle Preview zeigt nur eine Column, nicht das echte ModalBottomSheet. iOS hat 4 Previews (Default + 3 Geraetegroessen). Gute Previews erleichtern UI-Entwicklung.

---

## Akzeptanzkriterien

- [x] Preview zeigt den echten Sheet-Inhalt (nicht ModalBottomSheet wrapper)
- [x] Mehrere Previews: Default, mit Aenderungen, verschiedene Daten
- [x] Previews sind in Android Studio sichtbar und nuetzlich

---

## Manueller Test

1. MeditationEditSheet.kt in Android Studio oeffnen
2. Preview-Bereich anzeigen
3. Erwartung: Mehrere aussagekraeftige Previews sichtbar

---

## Referenz

- iOS: `GuidedMeditationEditSheet.swift` - Zeilen 181-227

---

## Hinweise

ModalBottomSheet kann nicht direkt in Preview angezeigt werden. Stattdessen den Inhalt (Column) in eine separate Composable extrahieren und diese previewen.

---

<!-- Erstellt via View Quality Review -->
