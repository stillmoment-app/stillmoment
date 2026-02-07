# Ticket shared-045: Share Sheet und File Association

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~2d | Android ~1d
**Phase**: 3-Feature

---

## Was

Audio-Dateien (MP3, M4A) koennen ueber das System-Share-Sheet ("Teilen") und "Oeffnen mit" an Still Moment gesendet werden. Die App registriert sich als Handler fuer diese Audio-Dateitypen.

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

## Scope

- **Einzeldatei-Import.** Mehrere Dateien gleichzeitig sind nicht in-scope (siehe shared-044 Batch Import).
- **Unterstuetzte Formate: nur MP3 und M4A.** Registrierung nur fuer diese spezifischen Typen, nicht `audio/*`.
- **Kein Drag & Drop (iPad).** Kann spaeter als eigenes Ticket ergaenzt werden.

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] MP3- und M4A-Dateien koennen ueber das System-Share-Sheet an Still Moment gesendet werden
- [ ] MP3- und M4A-Dateien koennen aus der Files-App (iOS) / Dateimanager (Android) direkt mit Still Moment geoeffnet werden
- [ ] Import erfolgt automatisch (Datei kopieren, Metadaten extrahieren, Library aktualisieren) - gemaess shared-043 Logik
- [ ] Erfolgs-Feedback nach Import (kurze Bestaetigungs-Anzeige wie shared-043)
- [ ] Wenn App nicht laeuft: wird gestartet und Import durchgefuehrt
- [ ] Wenn App im Hintergrund: Import wird durchgefuehrt und Library aktualisiert
- [ ] Wenn App im Vordergrund: Import und Bestaetigung sofort sichtbar
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Fehlerfaelle

- [ ] Nicht-unterstuetztes Format (z.B. WAV, FLAC, OGG): Abbruch mit Fehlermeldung ("Format nicht unterstuetzt")
- [ ] Korrupte/unlesbare Audio-Datei: Fehlermeldung ("Datei konnte nicht importiert werden")
- [ ] Duplikat (Datei bereits importiert): Hinweis dass nichts gemacht wird ("Meditation bereits in der Bibliothek")

### Tests
- [ ] Unit Tests iOS (URL-Handling, Import-Trigger, Fehlerfaelle)
- [ ] Unit Tests Android (Intent-Handling, Import-Trigger, Fehlerfaelle)

### Dokumentation
- [ ] CHANGELOG.md

---

## iOS: Zwei Mechanismen

iOS benoetigt zwei separate Mechanismen um beide Wege abzudecken:

### 1. File Association ("Oeffnen mit")
- `CFBundleDocumentTypes` in Info.plist fuer MP3/M4A UTIs
- `onOpenURL` Handler in der App empfaengt die Datei-URL direkt
- Deckt ab: Files App ("Oeffnen mit"), Safari Downloads, Mail-Anhaenge

### 2. Share Extension ("Teilen")
- Separates App Extension Target (`StillMomentShareExtension`)
- Erscheint im System-Share-Sheet (die App-Icons beim "Teilen"-Dialog)
- Extension kopiert Datei in Shared App Group Container
- Haupt-App prueft Container beim Start / Vordergrund und fuehrt Import durch
- Deckt ab: Teilen aus jeder App heraus (Safari, Mail, WhatsApp, Telegram, etc.)

**Warum beides:** "Oeffnen mit" allein reicht nicht — die meisten Nutzer druecken instinktiv "Teilen", nicht "Oeffnen mit". Ohne Share Extension ist Still Moment im Teilen-Dialog unsichtbar.

---

## Manueller Test

### Share Sheet (iOS)
1. Oeffne Safari und lade eine MP3-Datei herunter
2. Tippe auf "Teilen" (Share-Icon)
3. Waehle "Still Moment" aus den App-Icons
4. Erwartung: App oeffnet sich (oder kommt in Vordergrund), Datei wird importiert, kurze Bestaetigung, Meditation erscheint in Library

### Oeffnen mit (iOS)
1. Oeffne Files App, navigiere zu einer MP3
2. Long-Press → "Oeffnen mit" → "Still Moment"
3. Erwartung: Still Moment oeffnet sich, Datei importiert

### Share Sheet (Android)
1. Oeffne Chrome und lade eine MP3-Datei herunter
2. Tippe auf "Teilen"
3. Waehle "Still Moment"
4. Erwartung: App oeffnet sich, Datei wird importiert, kurze Bestaetigung

### Dateimanager (Android)
1. Oeffne Dateimanager, navigiere zu einer MP3
2. Tippe auf die Datei → "Still Moment" waehlen
3. Erwartung: Still Moment oeffnet sich, Datei importiert

### Fehlerfaelle (beide Plattformen)
1. Teile eine WAV-Datei → Erwartung: Fehlermeldung "Format nicht unterstuetzt"
2. Teile eine korrupte MP3 → Erwartung: Fehlermeldung
3. Teile eine bereits importierte MP3 → Erwartung: Hinweis "bereits vorhanden"

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Share Sheet | Share Extension Target | Intent Filter ACTION_SEND |
| File Association | CFBundleDocumentTypes + onOpenURL | Intent Filter ACTION_VIEW |
| Format-Filter | UTIs: public.mp3, public.mpeg-4-audio | MIME: audio/mpeg, audio/mp4 |
| Fehler-Anzeige | Alert | Snackbar / Dialog |
| Datei-Uebergabe (Share) | Shared App Group Container | Intent URI direkt |
| App-Kaltstart | onOpenURL / Container-Check | onCreate Intent-Handling |

---

## Referenz

- iOS Info.plist: `ios/StillMoment/Info.plist` (aktuell keine Document Types)
- iOS App Entry: `ios/StillMoment/StillMomentApp.swift`
- Android Manifest: `android/app/src/main/AndroidManifest.xml` (aktuell keine Intent Filter)

---

## Hinweise

- iOS Share Extension laeuft in eigenem Prozess mit begrenztem Speicher (~120MB). Die Extension soll nur die Datei in den Shared Container kopieren, kein Import durchfuehren.
- iOS: `CFBundleDocumentTypes` fuer spezifische Audio-UTIs registrieren (nicht `public.audio` generisch).
- Android: Intent Filter fuer `ACTION_VIEW` und `ACTION_SEND` mit spezifischen MIME-Types (`audio/mpeg`, `audio/mp4`), nicht `audio/*`.
- Duplikat-Erkennung: Vergleich ueber Dateiname + Dateigroesse (oder Hash) — Details in Implementierung klaeren.
