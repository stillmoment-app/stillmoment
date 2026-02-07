# Ticket shared-043: Import Auto-Metadaten (kein Edit Sheet)

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~1d | Android ~1d
**Phase**: 3-Feature

---

## Was

Beim Import einer Audio-Datei werden Metadaten automatisch aus ID3-Tags uebernommen. Das Edit Sheet wird nur geoeffnet wenn Pflichtfelder (Titel) leer oder unvollstaendig sind. Bei vollstaendigen ID3-Tags erfolgt ein stiller Import mit kurzer Bestaetigungs-Anzeige.

## Warum

Aktuell muss bei jedem Import ein Edit Sheet bestaetigt werden, selbst wenn alle Metadaten korrekt aus ID3 erkannt wurden. Bei Dateien mit guten Tags ist das unnoetige Reibung. Diese Aenderung ist ausserdem Voraussetzung fuer Batch Import (shared-044) und Share Sheet Import (shared-045).

Kontext: [BYOM-Strategie](../../concepts/byom-strategy.md)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] Wenn ID3-Titel vorhanden: Datei wird importiert ohne Edit Sheet
- [ ] Wenn ID3-Titel leer/fehlend: Edit Sheet wird geoeffnet (bestehendes Verhalten)
- [ ] Nach stillem Import: kurze Bestaetigungs-Anzeige (temporaerer Banner/Overlay, kein modaler Dialog, verschwindet nach ~2 Sekunden)
- [ ] Bestaetigungs-Anzeige zeigt den importierten Titel
- [ ] Meditation erscheint sofort in der Library
- [ ] Metadaten koennen spaeter ueber das Overflow-Menue bearbeitet werden (bestehendes Verhalten)
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (Import-Service: Verhalten mit/ohne ID3-Titel)
- [ ] Unit Tests Android (Import-Service: Verhalten mit/ohne ID3-Titel)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

### Import mit vollstaendigen ID3-Tags
1. Importiere eine MP3 mit Titel + Kuenstler in ID3-Tags
2. Erwartung: Kein Edit Sheet, kurze Bestaetigung, Meditation in Library

### Import mit fehlenden ID3-Tags
1. Importiere eine MP3 ohne ID3-Titel (oder mit leerem Titel)
2. Erwartung: Edit Sheet oeffnet sich wie bisher

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Bestaetigungs-Anzeige | Temporaerer Banner-Overlay (aehnlich AirDrop-Bestaetigung) | Snackbar |
| Dauer | ~2 Sekunden | ~2 Sekunden |

---

## Referenz

- iOS Import: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- Android Import: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationsListScreen.kt`

---

## Hinweise

- Das Edit Sheet nach Import wurde erst in shared-031 eingefuehrt. Diese Aenderung macht es bedingt: nur noch bei fehlenden Pflichtfeldern.
- ID3-Auswertung existiert bereits auf beiden Plattformen (wird beim Import verwendet). Hier geht es nur um die Entscheidungslogik "Sheet zeigen ja/nein".
- Dieses Ticket ist Voraussetzung fuer shared-044 (Batch Import) und shared-045 (Share Sheet).
