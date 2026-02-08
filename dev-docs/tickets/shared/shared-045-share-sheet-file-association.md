# Ticket shared-045: File Association ("Oeffnen mit")

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: iOS ~0.5d | Android ~0.5d
**Phase**: 3-Feature

---

## Was

Audio-Dateien (MP3, M4A) koennen ueber "Oeffnen mit" an Still Moment gesendet werden. Die App registriert sich als Handler fuer diese Audio-Dateitypen ueber File Association.

## Warum

Aktuell muessen Nutzer die App oeffnen, "+"-Button tippen und die Datei im Picker suchen. Wenn jemand eine MP3 in der Files-App (iOS) oder im Dateimanager (Android) findet, ist der natuerliche Impuls "Oeffnen mit → Still Moment". Das reduziert den Import von 4 Schritten auf 2.

Kontext: [BYOM-Strategie](../../concepts/byom-strategy.md)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Scope

- **File Association ("Oeffnen mit") auf beiden Plattformen.** Android unterstuetzt zusaetzlich ACTION_SEND ("Teilen"), da dies trivial moeglich ist. iOS Share Extension bleibt WONTFIX (shared-046).
- **Einzeldatei-Import.** Mehrere Dateien gleichzeitig sind nicht in-scope (siehe shared-044 Batch Import).
- **Unterstuetzte Formate: nur MP3 und M4A.** Registrierung nur fuer diese spezifischen Typen, nicht `audio/*`.

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] MP3- und M4A-Dateien koennen aus der Files-App (iOS) / Dateimanager (Android) direkt mit Still Moment geoeffnet werden ("Oeffnen mit")
- [ ] Import erfolgt ueber den bestehenden Import-Flow (Datei kopieren, Metadaten extrahieren, Library aktualisieren)
- [ ] Erfolgs-Feedback nach Import (Edit Sheet bei fehlenden ID3-Tags, oder stille Bestaetigung falls shared-043 umgesetzt)
- [ ] Wenn App nicht laeuft: wird gestartet und Import durchgefuehrt
- [ ] Wenn App im Hintergrund: Import wird durchgefuehrt und Library aktualisiert
- [ ] Wenn App im Vordergrund: Import sofort sichtbar
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Fehlerfaelle

- [ ] Nicht-unterstuetztes Format: Durch spezifische Registrierung (nur MP3/M4A) sollte Still Moment bei anderen Formaten gar nicht als Option erscheinen. Falls dennoch ein unerwartetes Format ankommt: Abbruch mit Fehlermeldung ("Format nicht unterstuetzt")
- [ ] Korrupte/unlesbare Audio-Datei: Fehlermeldung ("Datei konnte nicht importiert werden")
- [ ] Duplikat (Datei bereits importiert): Hinweis dass nichts gemacht wird ("Meditation bereits in der Bibliothek")

### Tests
- [ ] Unit Tests iOS (URL-Handling, Import-Trigger, Fehlerfaelle)
- [ ] Unit Tests Android (Intent-Handling, Import-Trigger, Fehlerfaelle)
- [ ] Kein UI-Test: `simctl openurl` mit `file://`-URLs routet nicht an registrierte Apps (iOS leitet an Files.app weiter). Ein UI-Test muesste die Dateien-App fernsteuern (fragile fremde UI). Der E2E-Flow wird manuell getestet. Ein automatisierter Round-Trip-Test wird moeglich wenn shared-047 (Export) umgesetzt ist.

### Dokumentation
- [ ] CHANGELOG.md

---

## Technische Umsetzung

### iOS

- `CFBundleDocumentTypes` in Info.plist fuer MP3/M4A UTIs (`public.mp3`, `com.apple.m4a-audio`)
- `onOpenURL` Handler in der App empfaengt die Datei-URL direkt
- Deckt ab: Files App ("Oeffnen mit"), Safari Downloads, Mail-Anhaenge

### Android

- Intent Filter fuer `ACTION_VIEW` und `ACTION_SEND` mit spezifischen MIME-Types (`audio/mpeg`, `audio/mp4`, `audio/x-m4a`)
- `onCreate` / `onNewIntent` verarbeitet den Intent und triggert Import
- Deckt ab: Dateimanager, Download-Manager, "Teilen"-Menue aus anderen Apps

---

## Manueller Test

### Oeffnen mit (iOS)
1. Oeffne Files App, navigiere zu einer MP3
2. Long-Press → "Oeffnen mit" → "Still Moment"
3. Erwartung: Still Moment oeffnet sich, Datei wird importiert

### Dateimanager (Android)
1. Oeffne Dateimanager, navigiere zu einer MP3
2. Tippe auf die Datei → "Still Moment" waehlen
3. Erwartung: Still Moment oeffnet sich, Datei wird importiert

### Fehlerfaelle (beide Plattformen)
1. Oeffne eine korrupte MP3 mit Still Moment → Erwartung: Fehlermeldung
2. Oeffne eine bereits importierte MP3 → Erwartung: Hinweis "bereits vorhanden"

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| File Association | CFBundleDocumentTypes + onOpenURL | Intent Filter ACTION_VIEW + ACTION_SEND |
| Format-Filter | UTIs: public.mp3, com.apple.m4a-audio | MIME: audio/mpeg, audio/mp4 |
| Fehler-Anzeige | Alert | Snackbar / Dialog |
| App-Kaltstart | onOpenURL | onCreate Intent-Handling |

---

## Referenz

- iOS Info.plist: `ios/StillMoment/Info.plist` (CFBundleDocumentTypes fuer MP3/M4A)
- iOS App Entry: `ios/StillMoment/StillMomentApp.swift`
- Android Manifest: `android/app/src/main/AndroidManifest.xml` (aktuell keine Intent Filter)

---

## Hinweise

- iOS: `CFBundleDocumentTypes` fuer spezifische Audio-UTIs registrieren (nicht `public.audio` generisch).
- Android: Intent Filter fuer `ACTION_VIEW` mit spezifischen MIME-Types (`audio/mpeg`, `audio/mp4`), nicht `audio/*`.
- Duplikat-Erkennung: Vergleich ueber Dateiname + Dateigroesse.
- Kein neues Xcode-Target noetig — alles in der Haupt-App.

---

## Bekannte Edge Cases

- **Datei waehrend Timer-Session geoeffnet:** App wechselt zum Library-Tab und zeigt Edit Sheet. Die laufende Timer-Session laeuft im Hintergrund weiter — kein Konflikt, da Timer und Import unterschiedliche Audio-Sessions nutzen.
- **Grosse Dateien:** Kein Groessen-Limit. Der User entscheidet selbst welche Dateien er importiert. iOS kopiert die Datei in den App-Speicher, der durch das System-Quota begrenzt ist.
