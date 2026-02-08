# Ticket shared-047: Meditation exportieren / teilen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~0.5d | Android ~0.5d
**Phase**: 3-Feature

---

## Was

Nutzer koennen eine importierte Meditation aus der App heraus teilen oder exportieren (z.B. in die Dateien-App, per AirDrop, per Messenger).

## Warum

Die Audiodateien gehoeren dem Nutzer. Export/Teilen ermoeglicht Backups, Weitergabe an andere Geraete und staerkt das Vertrauen, dass kein Lock-in besteht. Ausserdem ermoeglicht es den Round-Trip-Test fuer den Import-Flow (shared-045): Meditation exportieren, in Dateien-App oeffnen, "Oeffnen mit" zurueck in Still Moment.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] In der Meditationsliste gibt es eine Option zum Teilen/Exportieren einer Meditation
- [ ] Das System-Share-Sheet oeffnet sich mit der Audio-Datei (MP3/M4A)
- [ ] Nutzer kann Ziel frei waehlen (Dateien-App, AirDrop, Messenger, etc.)
- [ ] Dateiname im Share-Sheet entspricht dem Original-Dateinamen
- [ ] Funktioniert fuer alle unterstuetzten Formate (MP3, M4A)
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Fehlerfaelle

- [ ] Datei nicht mehr vorhanden (z.B. geloescht ausserhalb der App): Fehlermeldung statt Crash

### Tests

- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation

- [ ] CHANGELOG.md

---

## Manueller Test

### Export in Dateien-App

1. Oeffne die Meditationsliste
2. Waehle "Teilen" fuer eine Meditation
3. Waehle "In Dateien sichern" als Ziel
4. Erwartung: Datei wird in der Dateien-App gespeichert, Dateiname korrekt

### Round-Trip-Test (Import-Validierung)

1. Exportiere eine Meditation in die Dateien-App (wie oben)
2. Oeffne die Dateien-App, long-press auf die exportierte Datei
3. Waehle "Oeffnen mit" → Still Moment
4. Erwartung: Duplikat-Erkennung greift, Meldung "Meditation bereits in der Bibliothek"

### AirDrop

1. Teile eine Meditation per AirDrop an ein anderes Geraet
2. Erwartung: Datei kommt als MP3/M4A an

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Teilen-Aktion | Share Sheet (UIActivityViewController / ShareLink) | Share Sheet (ACTION_SEND Intent) |
| Zugang | Overflow-Menue in Meditationsliste | Overflow-Menue in Meditationsliste |

---

## Referenz

- iOS Meditationsliste: `ios/StillMoment/View/GuidedMeditationsListView.swift`
- Android Meditationsliste: `android/app/src/main/kotlin/com/stillmoment/`
- Import-Logik (shared-045): Fuer Round-Trip-Validierung

---

## Hinweise

- iOS: `ShareLink` (SwiftUI, ab iOS 16) ist der einfachste Weg. Alternativ `UIActivityViewController` fuer mehr Kontrolle.
- Android: Standard `ACTION_SEND` Intent mit `FileProvider` fuer die Content-URI.
- Die Datei muss als Kopie geteilt werden, nicht als Referenz auf den internen Speicher.
- Dieses Feature ermoeglicht erstmals manuelles End-to-End-Testing des Import-Flows (shared-045) ohne externe Hilfsmittel.
