# Ticket shared-046: Share Extension ("Teilen")

**Status**: [x] WONTFIX
**Prioritaet**: HOCH
**Aufwand**: iOS ~2d | Android ~0.5d
**Phase**: 3-Feature
**Abschluss**: File Association (shared-045) + geplanter In-App Import decken den Use Case ab. Share Extension ist unnoetig — Still Moment wuerde in der App-Liste des Teilen-Menues zwischen dutzenden anderen Apps untergehen. Der natuerliche Flow ist: Datei in Downloads sichern, dann in Still Moment importieren.

---

## Was

Audio-Dateien (MP3, M4A) koennen ueber das System-Share-Sheet ("Teilen") an Still Moment gesendet werden. Auf iOS erfordert dies ein separates Share Extension Target.

## Warum

"Oeffnen mit" (shared-045) deckt nur die Files-App und direkte Datei-Oeffnung ab. Die meisten Nutzer druecken aber instinktiv "Teilen" wenn sie eine MP3 in Safari, Mail, WhatsApp oder Telegram sehen. Ohne Share Extension ist Still Moment im Teilen-Dialog unsichtbar.

Kontext: [BYOM-Strategie](../../concepts/byom-strategy.md)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-045    |
| Android   | [ ]    | shared-045    |

---

## Scope

- **Nur Share Sheet ("Teilen").** File Association ("Oeffnen mit") ist shared-045.
- **Einzeldatei-Import.** Mehrere Dateien gleichzeitig sind nicht in-scope (siehe shared-044 Batch Import).
- **Unterstuetzte Formate: nur MP3 und M4A.** Registrierung nur fuer diese spezifischen Typen, nicht `audio/*`.

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] MP3- und M4A-Dateien koennen ueber das System-Share-Sheet an Still Moment gesendet werden
- [ ] Still Moment erscheint im Teilen-Dialog mit App-Icon
- [ ] Import erfolgt ueber den bestehenden Import-Flow (Datei kopieren, Metadaten extrahieren, Library aktualisieren)
- [ ] Erfolgs-Feedback nach Import
- [ ] Wenn App nicht laeuft: wird gestartet und Import durchgefuehrt
- [ ] Wenn App im Hintergrund: Import wird durchgefuehrt und Library aktualisiert
- [ ] Wenn App im Vordergrund: Import und Bestaetigung sofort sichtbar
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Fehlerfaelle

- [ ] Nicht-unterstuetztes Format: Durch spezifische Registrierung (nur MP3/M4A) sollte Still Moment bei anderen Formaten gar nicht als Option erscheinen. Falls dennoch ein unerwartetes Format ankommt: Abbruch mit Fehlermeldung ("Format nicht unterstuetzt")
- [ ] Korrupte/unlesbare Audio-Datei: Fehlermeldung ("Datei konnte nicht importiert werden")
- [ ] Share Extension kann Datei nicht kopieren (z.B. Speicher voll): Abbruch mit Fehlermeldung in der Extension
- [ ] Duplikat (Datei bereits importiert): Hinweis dass nichts gemacht wird ("Meditation bereits in der Bibliothek")

### Tests
- [ ] Unit Tests iOS (Container-Handling, Import-Trigger aus Container, Fehlerfaelle)
- [ ] Unit Tests Android (Intent-Handling, Import-Trigger, Fehlerfaelle)

### Dokumentation
- [ ] CHANGELOG.md

---

## Technische Umsetzung

### iOS (komplex)

iOS benoetigt ein separates App Extension Target:

1. **Share Extension Target** (`StillMomentShareExtension`)
   - Neues Target im Xcode-Projekt
   - Eigene Info.plist mit `NSExtension` Konfiguration
   - `NSExtensionActivationSupportsFileWithMaxCount = 1`
   - Aktivierungsregel fuer MP3/M4A UTIs

2. **App Group Container**
   - App Group Entitlement fuer Haupt-App und Extension
   - Extension kopiert empfangene Datei in Shared Container
   - Extension zeigt kurze Bestaetigung und schliesst sich

3. **Haupt-App Container-Polling**
   - Beim App-Start und bei `scenePhase == .active` pruefen ob Dateien im Container liegen
   - Gefundene Dateien importieren und aus Container loeschen

**Wichtig:** Die Share Extension laeuft in eigenem Prozess mit begrenztem Speicher (~120MB). Die Extension soll nur die Datei in den Shared Container kopieren, kein Import durchfuehren.

### Android (einfach)

- Intent Filter fuer `ACTION_SEND` mit spezifischen MIME-Types (`audio/mpeg`, `audio/mp4`)
- Intent URI direkt verarbeiten (kein Container noetig)
- Gleiche Import-Logik wie bei `ACTION_VIEW` aus shared-045

---

## Manueller Test

### Share Sheet (iOS)
1. Oeffne Safari und lade eine MP3-Datei herunter
2. Tippe auf "Teilen" (Share-Icon)
3. Waehle "Still Moment" aus den App-Icons
4. Erwartung: Extension zeigt kurze Bestaetigung, App importiert Datei, Meditation erscheint in Library

### Share Sheet (Android)
1. Oeffne Chrome und lade eine MP3-Datei herunter
2. Tippe auf "Teilen"
3. Waehle "Still Moment"
4. Erwartung: App oeffnet sich, Datei wird importiert, kurze Bestaetigung

### Fehlerfaelle (beide Plattformen)
1. Teile eine korrupte MP3 → Erwartung: Fehlermeldung
2. Teile eine bereits importierte MP3 → Erwartung: Hinweis "bereits vorhanden"

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Share Sheet | Share Extension Target | Intent Filter ACTION_SEND |
| Format-Filter | UTIs in Extension-Aktivierungsregel | MIME: audio/mpeg, audio/mp4 |
| Fehler-Anzeige | Alert (in Extension) | Snackbar / Dialog |
| Datei-Uebergabe | Shared App Group Container | Intent URI direkt |
| App-Kaltstart | Container-Check bei scenePhase .active | onCreate Intent-Handling |

---

## Referenz

- iOS Xcode-Projekt: `ios/StillMoment.xcodeproj`
- iOS App Entry: `ios/StillMoment/StillMomentApp.swift`
- Android Manifest: `android/app/src/main/AndroidManifest.xml`
- Import-Logik aus shared-045 (wiederverwendbar)

---

## Hinweise

- iOS Share Extension ist ein eigenes Xcode-Target mit eigenem Build-Prozess. Am besten manuell in Xcode anlegen (File → New → Target → Share Extension), dann Code vom Agent schreiben lassen.
- App Group Identifier-Konvention: `group.com.stillmoment.shared`
- Extension-Info.plist braucht `NSExtensionPointIdentifier: com.apple.share-services`
- Android: `ACTION_SEND` Intent Filter ist trivial — gleiche Struktur wie `ACTION_VIEW` aus shared-045.
- Duplikat-Erkennung: Vergleich ueber Dateiname + Dateigroesse.
