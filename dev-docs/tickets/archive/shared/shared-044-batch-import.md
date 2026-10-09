---
id: shared-044
title: Batch Import (Mehrfachauswahl)
status:
  ios: wontfix
  android: wontfix
phase: 3-Feature
priority: hoch
depends_on: [shared-043]
---

# Ticket shared-044: Batch Import

**Aufwand**: iOS ~1d | Android ~1d

---

## WONTFIX

Das Ticket setzte einen stillen Import ohne Edit Sheet voraus (shared-043): Mehrere Dateien
sollten in einem Vorgang importiert werden, der Dateiname dient als Titel. Der Import wurde
inzwischen bewusst anders gebaut (ios-042/043/044, shared-103): Das Edit Sheet oeffnet sich
bei jedem Import, vorbefuellt aus ID3-Tags und Dateiname (`ImportPrefill`), Lehrer:in und
Titel sind Pflicht, gespeichert wird erst beim Sichern. Ein Batch Import ohne Bestaetigung
pro Datei passt nicht zu dieser Entscheidung.

---

## Was

Mehrere Audio-Dateien gleichzeitig importieren. Der Document Picker erlaubt Mehrfachauswahl, alle Dateien werden mit automatischer Metadaten-Uebernahme importiert.

## Warum

Bei 10 Retreat-Aufnahmen bedeutet der aktuelle Import 10 einzelne Zyklen (Picker oeffnen, Datei waehlen, Sheet bestaetigen). Das macht den USP "Bring Your Own Meditation" praktisch schwach. Batch Import reduziert das auf einen einzigen Vorgang.

Kontext: [BYOM-Strategie](../../../concepts/byom-strategy.md)

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] Document Picker erlaubt Mehrfachauswahl
- [ ] Alle ausgewaehlten Dateien werden importiert (Metadaten automatisch aus ID3, kein Edit Sheet pro Datei - gemaess shared-043)
- [ ] Progress-Indikator bei mehr als 3 Dateien
- [ ] Nach Batch-Import: Zusammenfassung ("X Meditationen importiert")
- [ ] Fehler bei einzelnen Dateien blockieren nicht den Rest des Imports
- [ ] Bei Fehlern: Zusammenfassung nennt erfolgreiche und fehlgeschlagene Dateien
- [ ] Einzelimport (1 Datei) verhaelt sich wie bisher (gemaess shared-043)
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (Import-Service mit mehreren Dateien, Teilerfolg)
- [ ] Unit Tests Android (Import-Service mit mehreren Dateien, Teilerfolg)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

### Batch Import
1. Oeffne Library, tippe "+"
2. Waehle 5 Audio-Dateien gleichzeitig im Picker
3. Erwartung: Progress-Anzeige, alle 5 werden importiert, Zusammenfassung "5 Meditationen importiert"

### Teilerfolg
1. Waehle 3 Dateien, davon eine korrupte/nicht-unterstuetzte
2. Erwartung: 2 erfolgreich importiert, Fehlermeldung fuer die dritte, kein Abbruch

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Picker | UIDocumentPickerViewController (allowsMultipleSelection = true) | OpenMultipleDocuments() Contract |
| Progress | ProgressView in Library | LinearProgressIndicator |
| Zusammenfassung | Temporaerer Banner wie shared-043 | Snackbar wie shared-043 |

---

## Referenz

- iOS Picker: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- Android Picker: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationsListScreen.kt`

---

## Hinweise

- iOS: `allowsMultipleSelection` ist aktuell explizit `false` - muss auf `true` gesetzt werden.
- Android: Nutzt aktuell `OpenDocument()` - muss auf `OpenMultipleDocuments()` umgestellt werden.
- Batch Import ueberspringt immer das Edit Sheet - auch wenn einzelne Dateien keinen ID3-Titel haben. In dem Fall wird der Dateiname als Titel verwendet.
