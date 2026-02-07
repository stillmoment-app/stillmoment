# Ticket shared-045: Share Sheet und File Association

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~1d | Android ~1d
**Phase**: 3-Feature

---

## Was

Audio-Dateien (MP3, M4A) koennen ueber das System-Share-Sheet ("Teilen" / "Oeffnen mit") an Still Moment gesendet werden. Die App registriert sich als Handler fuer Audio-Dateitypen.

## Warum

Aktuell muessen Nutzer die App oeffnen, "+"-Button tippen und die Datei im Picker suchen. Wenn jemand eine MP3 in Safari herunterlaed, in Mail erhaelt oder in der Files-App findet, ist der natuerliche Impuls "Teilen → Still Moment". Das reduziert den Import von 4 Schritten auf 2 und macht das Alleinstellungsmerkmal praktisch nutzbar.

Kontext: [BYOM-Strategie](../../concepts/byom-strategy.md)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-043    |
| Android   | [ ]    | shared-043    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] Audio-Dateien (MP3, M4A) koennen ueber das System-Share-Sheet an Still Moment gesendet werden
- [ ] Audio-Dateien koennen aus der Files-App (iOS) / Dateimanager (Android) direkt mit Still Moment geoeffnet werden
- [ ] Import erfolgt automatisch (Datei kopieren, Metadaten extrahieren, Library aktualisieren) - gemaess shared-043 Logik
- [ ] Erfolgs-Feedback nach Import (kurze Bestaetigungs-Anzeige wie shared-043)
- [ ] Wenn App nicht laeuft: wird gestartet und Import durchgefuehrt
- [ ] Wenn App im Hintergrund: Import wird durchgefuehrt und Library aktualisiert
- [ ] Wenn App im Vordergrund: Import und Bestaetigung sofort sichtbar
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (URL-Handling, Import-Trigger)
- [ ] Unit Tests Android (Intent-Handling, Import-Trigger)

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

### Share Sheet
1. Oeffne Safari/Chrome und lade eine MP3-Datei herunter
2. Tippe auf "Teilen" / "Oeffnen mit"
3. Waehle "Still Moment"
4. Erwartung: App oeffnet sich (oder kommt in Vordergrund), Datei wird importiert, kurze Bestaetigung, Meditation erscheint in Library

### Files App (iOS)
1. Oeffne Files App, navigiere zu einer MP3
2. Long-Press → "Oeffnen mit" → "Still Moment"
3. Erwartung: Still Moment oeffnet sich, Datei importiert

### Dateimanager (Android)
1. Oeffne Dateimanager, navigiere zu einer MP3
2. Tippe auf die Datei → "Still Moment" waehlen
3. Erwartung: Still Moment oeffnet sich, Datei importiert

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Share Sheet Eintrag | CFBundleDocumentTypes + onOpenURL (Scene-Handling) | Intent Filter ACTION_SEND + ACTION_VIEW |
| File Association | UTI-Registration fuer audio/* | Intent Filter fuer audio/* MIME-Types |
| App-Kaltstart | Scene Delegate / onOpenURL beim Launch | onCreate Intent-Handling |

---

## Referenz

- iOS Info.plist: `ios/StillMoment/Info.plist` (aktuell keine Document Types)
- iOS App Entry: `ios/StillMoment/StillMomentApp.swift`
- Android Manifest: `android/app/src/main/AndroidManifest.xml` (aktuell keine Intent Filter)

---

## Hinweise

- iOS: Scene-Handling ueber `onOpenURL` ist einfacher als eine App Extension und reicht fuer den Use Case. Keine echte Share Extension noetig.
- iOS: `CFBundleDocumentTypes` fuer audio UTIs registrieren + `LSItemContentTypes`.
- Android: Intent Filter fuer `ACTION_VIEW` und `ACTION_SEND` mit `audio/*` MIME-Type.
- Kein Drag & Drop (iPad) in diesem Ticket. Kann spaeter als eigenes Ticket ergaenzt werden.
