# Ticket shared-038: Import-Reibung eliminieren

**Status**: [x] SPLIT → shared-043, shared-044, shared-045
**Prioritaet**: HOCH
**Aufwand**: iOS ~3d | Android ~3d
**Phase**: 3-Feature

---

## Was

Drei Massnahmen um das Importieren von Audio-Dateien drastisch zu vereinfachen:

1. **"Open in Still Moment"** - App als Ziel in Share Sheet und File Associations registrieren
2. **Batch Import** - Mehrere Dateien gleichzeitig importieren
3. **Import ohne sofortiges Edit Sheet** - Metadaten automatisch uebernehmen, spaeter bearbeiten

## Warum

Der MP3-Import ist das groesste Alleinstellungsmerkmal der App. Aktuell ist der Import-Prozess aber zu umstaendlich: Nutzer muessen die App oeffnen, "+" tippen, den Picker navigieren, und fuer jede einzelne Datei ein Edit Sheet bestaetigen. Bei 10 Retreat-Aufnahmen heisst das 10 einzelne Import-Zyklen. Das macht den USP theoretisch stark, aber praktisch schwach.

Kontext: [BYOM-Strategie](../../concepts/byom-strategy.md)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Share Sheet / File Association (beide Plattformen)

- [ ] Audio-Dateien (MP3, M4A) koennen ueber das System-Share-Sheet an Still Moment gesendet werden
- [ ] Audio-Dateien koennen aus der Files-App (iOS) / Dateimanager (Android) direkt mit Still Moment geoeffnet werden
- [ ] Import erfolgt automatisch (Datei kopieren, Metadaten extrahieren, Library aktualisieren)
- [ ] Erfolgs-Feedback nach Import (kurze Bestaetigung, kein modaler Dialog)
- [ ] Wenn App nicht laeuft, wird sie gestartet und Import durchgefuehrt
- [ ] Wenn App im Hintergrund, wird Import durchgefuehrt und Library aktualisiert

### Batch Import (beide Plattformen)

- [ ] Document Picker erlaubt Mehrfachauswahl
- [ ] Alle ausgewaehlten Dateien werden importiert (Metadaten automatisch aus ID3)
- [ ] Progress-Indikator bei mehr als 3 Dateien
- [ ] Edit Sheet wird NICHT fuer jede einzelne Datei geoeffnet
- [ ] Nach Batch-Import: Zusammenfassung ("X Meditationen importiert")
- [ ] Fehler bei einzelnen Dateien blockieren nicht den Rest des Imports

### Einzelimport-Verbesserung

- [ ] Edit Sheet nach Einzelimport bleibt optional bestehen (bestehendes Verhalten)
- [ ] Alternativ: Edit Sheet nur oeffnen wenn ID3-Tags leer/unvollstaendig sind

### Qualitaet

- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android
- [ ] Accessibility: Import-Fortschritt fuer VoiceOver/TalkBack angekuendigt

### Tests
- [ ] Unit Tests iOS (Import-Service mit mehreren Dateien)
- [ ] Unit Tests Android (Import-Service mit mehreren Dateien)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

### Share Sheet
1. Oeffne Safari/Chrome und lade eine MP3-Datei herunter
2. Tippe auf "Teilen" / "Oeffnen mit"
3. Waehle "Still Moment"
4. Erwartung: App oeffnet sich, Datei wird importiert, kurze Bestaetigung, Meditation erscheint in Library

### Batch Import
1. Oeffne Library in Still Moment, tippe "+"
2. Waehle 5 Audio-Dateien gleichzeitig
3. Erwartung: Progress-Anzeige, alle 5 werden importiert, Zusammenfassung

### Files App (iOS)
1. Oeffne Files App, navigiere zu einer MP3
2. Long-Press → "Oeffnen mit" → "Still Moment"
3. Erwartung: Still Moment oeffnet sich, Datei importiert

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Share Sheet Eintrag | UIActivity / App Extension | Intent Filter ACTION_SEND |
| File Association | CFBundleDocumentTypes + UTI | Intent Filter ACTION_VIEW |
| Batch Picker | UIDocumentPickerViewController (allowsMultipleSelection) | OpenMultipleDocuments() Contract |
| Drag & Drop (Bonus) | iPad: NSItemProvider | Nicht noetig |

---

## Referenz

- iOS Import: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift`
- iOS Info.plist: `ios/StillMoment/Info.plist` (aktuell keine Document Types)
- Android Import: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationsListScreen.kt`
- Android Manifest: `android/app/src/main/AndroidManifest.xml` (aktuell keine Intent Filter)

---

## Hinweise

- iOS: `allowsMultipleSelection` ist aktuell explizit `false` (Zeile 321)
- Android: Nutzt aktuell `OpenDocument()` - muss auf `OpenMultipleDocuments()` umgestellt werden
- Share Sheet auf iOS kann als App Extension oder ueber Scene-Handling umgesetzt werden. Scene-Handling ist einfacher und reicht fuer den Use Case.
- Batch Import sollte das Edit Sheet ueberspringen - Nutzer koennen Metadaten spaeter ueber das Overflow-Menue bearbeiten.
