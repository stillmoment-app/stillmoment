# Implementierungsplan shared-046: Share Extension

Dieser Plan beschreibt die technische Umsetzung. Das Ticket (`shared-046-share-extension.md`) beschreibt WAS und WARUM.

---

## Plattform-Status

### Android: ACTION_SEND existiert, aber Chrome-Share funktioniert nicht

Manifest Intent Filter (`audio/mpeg`, `audio/mp4`, `audio/x-m4a`) + `MainActivity.handleIncomingIntent()` + Import-Flow existieren. Share aus Dateimanagern und Audio-Apps funktioniert bereits.

**Problem: Chrome teilt URLs, keine Dateien.** Recherche der Chromium-Quellen (`ShareHelper.java`, `ShareDelegateImpl.java`) hat ergeben: Chrome Android sendet beim "Teilen" aus dem eingebauten Audio-Player **immer** `ACTION_SEND` mit `text/plain` + `EXTRA_TEXT` (die URL). Einzige Ausnahme sind PDFs. Das bedeutet: Still Moment taucht im Chrome-Share-Sheet nicht auf, weil kein `text/plain`-Filter registriert ist.

**Neuer Code noetig:**
1. Zusaetzlicher Intent-Filter fuer `ACTION_SEND` + `text/plain`
2. Intent-Handler: URL aus `EXTRA_TEXT` extrahieren, Endung pruefen (`.mp3`, `.m4a`)
3. Bei Audio-URL: Datei herunterladen, dann bestehenden Import-Flow nutzen
4. Bei Nicht-Audio-URL: still ignorieren (Activity schliessen ohne Aktion)
5. Download-UX: ProgressView analog zu iOS

**Trade-off:** Mit `text/plain`-Filter erscheint Still Moment bei **jedem** Text-Share (Links, Nachrichten, etc.). Auf Android laesst sich das nicht serverseitig filtern — die Filterung muss im Code passieren. Alternatives Vorgehen: keinen `text/plain`-Filter registrieren und nur den Datei-Share-Pfad unterstuetzen (Dateimanager, andere Audio-Apps). Chrome-User muessen dann die MP3 erst herunterladen und aus dem Dateimanager teilen.

**Empfehlung:** `text/plain`-Filter registrieren. Der UX-Nachteil ist auf Android geringer als auf iOS, weil Android-User das Share Sheet individuell sortieren koennen und selten genutzte Apps nach unten rutschen.

### iOS: neue Implementierung noetig

---

## Design-Entscheidungen

### 1. `public.url` registrieren

Safari teilt beim "Teilen" einer MP3-URL immer `public.url` — **nie** `public.audio`. Ohne `public.url`-Registrierung funktioniert der primaere Use Case (MP3 aus Safari teilen) nicht.

**Trade-off:** `NSExtensionActivationRule` kann URLs nicht nach Dateiendung filtern. Still Moment erscheint im Share Sheet fuer **alle** URLs (auch Webseiten, YouTube-Links, etc.). Filterung muss in Code passieren — Extension prueft die URL-Endung und schliesst sich still bei nicht-Audio-URLs.

**Entscheidung:** Wir registrieren fuer `public.audio` + `public.url`. Der UX-Nachteil (Extension erscheint ueberall) ist akzeptabel, weil:
- Still Moment erscheint nur in der zweiten Reihe des Share Sheets (Apps), nicht prominent
- Stilles Schliessen bei nicht-Audio-URLs erzeugt keine Stoerung
- Der Safari-Use-Case ist der Hauptgrund fuer dieses Ticket

Aktivierungsregel:
```
SUBQUERY(extensionItems, $item,
  SUBQUERY($item.attachments, $att,
    ANY $att.registeredTypeIdentifiers UTI-CONFORMS-TO "public.audio"
    || ANY $att.registeredTypeIdentifiers UTI-CONFORMS-TO "public.url"
  ).@count >= 1
).@count >= 1
```

### 2. Kein UI in der Extension

Die Extension zeigt **keine eigene Oberflaeche**. Sie kopiert die Datei in die Inbox und oeffnet die Haupt-App via URL-Scheme (`stillmoment://import`). Die Typ-Auswahl (Meditation / Klangatmosphaere / Einstimmung) findet in der Haupt-App statt — identischer Flow wie bei "Oeffnen mit" (shared-045).

**Begruendung:**
- Kein doppelter UI-Code (Extension hat keinen Zugriff auf App-Theme)
- Konsistentes Verhalten mit shared-045
- Weniger Code im speicherbegrenzten Extension-Prozess

### 3. Auto-Open via URL-Scheme

Die Extension oeffnet `stillmoment://import` nach dem Kopieren. `UIApplication.open()` ist in Extensions nicht verfuegbar.

**Primaerer Weg (iOS 16+):** `NSExtensionContext.open(URL)` — offiziell dokumentierte API seit iOS 8, funktioniert in Share Extensions zuverlaessig.

**Fallback wenn URL-Scheme fehlschlaegt:** Die Haupt-App prueft die Inbox auch bei `scenePhase == .active` (siehe Inbox-Handler). Der User muss die App dann manuell oeffnen — kein stilles Scheitern, sondern der Import passiert beim naechsten App-Start.

**Fehlerfall in der Extension** (App Group Container nicht beschreibbar, unerwarteter Fehler): Alert mit Fehlermeldung, kein stilles Scheitern.

---

## Architektur iOS: Inbox-Pattern

Der App Group Container dient als **Inbox** — die Extension legt Dateien/URL-Referenzen ab, die Haupt-App holt sie ab und importiert via bestehendem `FileOpenHandler`. Kein shared State, keine UserDefaults-Migration, kein Refactoring bestehender Services.

```
Quell-App "Teilen" → Share Extension (eigener Prozess, ~120MB Speicher)
  │
  ├─ public.audio? → Datei in Inbox kopieren
  │
  └─ public.url? → Endung pruefen (.mp3/.m4a?)
  │    ├─ Nein → still schliessen
  │    └─ Ja → URL-Referenz als JSON in Inbox schreiben
  │
  └─ stillmoment://import oeffnen → Extension schliesst sich

Haupt-App (oeffnet sich via URL-Scheme oder ist bereits aktiv)
  → Inbox pruefen
  → Datei? → FileOpenHandler.prepareImport() (Typ-Auswahl, Import)
  → URL-Referenz? → Download + ProgressView, dann prepareImport()
  → Inbox-Eintrag loeschen
```

**Einzeldatei-Import:** Die Inbox verarbeitet immer nur den **neuesten Eintrag** (nach Timestamp). Aeltere verwaiste Eintraege werden beim Inbox-Check geloescht. Batch-Import ist explizit out-of-scope (siehe shared-044).

### Warum Downloads in der Haupt-App

Die Extension hat ~120MB Speicherlimit und begrenzte Laufzeit. Eine 20-Minuten-Meditation (~30MB) herunterladen waere riskant. Die Extension speichert nur die URL-Referenz, die Haupt-App laedt herunter.

### Was sich am bestehenden Code aendert

**Bestehende Services bleiben unveraendert** (`GuidedMeditationService`, `CustomAudioRepository`, `AudioMetadataService`, `FileOpenHandler`). Der Import-Flow ab `prepareImport()` ist identisch mit "Oeffnen mit".

**Aenderungen an bestehenden Dateien:**
- `StillMomentApp.swift`: URL-Scheme-Handler (`stillmoment://import`) in `.onOpenURL` + Inbox-Pruefung bei `scenePhase == .active`
- `Info.plist`: URL-Scheme `stillmoment` registrieren
- Xcode-Projekt: App Group Entitlement fuer Haupt-App-Target

---

## Neuer Code

### 1. ShareViewController (Extension)

Minimaler UIViewController (kein `SLComposeServiceViewController`):

- `NSItemProvider` auswerten:
  - `public.audio` → `loadFileRepresentation` → Datei in Inbox kopieren (**URL ist nur waehrend Callback gueltig!**)
  - `public.url` → URL laden, Endung pruefen, bei Audio-Endung URL-Referenz als JSON in Inbox schreiben
- Bei nicht-Audio-URL: still schliessen (`completeRequest()` ohne Aktion)
- Bei Erfolg: `stillmoment://import` oeffnen, dann `completeRequest()`
- Bei Fehler (Inbox nicht beschreibbar): `UIAlertController` mit lokalisierter Fehlermeldung

**Inbox-Eintraege:**
- Audio-Dateien: direkt als `.mp3`/`.m4a` im Inbox-Verzeichnis, **UUID-Prefix** im Dateinamen (`{UUID}_{original}.mp3`) um Namenskollisionen zu vermeiden
- URL-Referenzen: `.json`-Datei (ebenfalls UUID-Prefix) mit folgendem Schema:
```json
{
  "url": "https://example.com/meditation.mp3",
  "filename": "meditation.mp3",
  "timestamp": "2026-03-13T10:30:00Z"
}
```
- `url`: Download-Quelle
- `filename`: Originaler Dateiname (aus URL-Pfad, fuer Metadaten-Anzeige)
- `timestamp`: Zeitpunkt des Teilens (fuer Cleanup-Logik)

**Atomares Schreiben:** Extension schreibt in temporaere Datei im selben Verzeichnis, dann `rename()` (atomare Operation auf APFS). Verhindert dass die Haupt-App eine halbgeschriebene Datei liest.

**Inbox-Cleanup:** Beim Inbox-Check in der Haupt-App werden alle Eintraege **aelter als 24h** geloescht (verwaiste Eintraege). Nur der **neueste Eintrag** wird verarbeitet — aeltere werden ebenfalls geloescht (kein Batch-Import, siehe shared-044).

### 2. URL-Scheme Handler + Inbox-Handler (Haupt-App)

Neuer Code in `StillMomentApp`:
- URL-Scheme `stillmoment://import` registrieren (Info.plist) und in `.onOpenURL` behandeln
- Fallback: `@Environment(\.scenePhase)` beobachten → bei `.active` Inbox pruefen (fuer den Fall dass die App bereits laeuft oder der URL-Scheme-Aufruf fehlschlaegt)
- Inbox-Verzeichnis: `FileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.stillmoment")`
- Dateien → `FileOpenHandler.prepareImport()` (Typ-Auswahl, Import, Navigation)
- URL-Referenzen → Download-Service, dann `prepareImport()`
- Nur neuesten Eintrag verarbeiten, aeltere + verwaiste (>24h) loeschen
- Nach Verarbeitung: Eintrag aus Inbox loeschen

### 3. Download-Service (Haupt-App)

Einfacher Service fuer URL → lokale Datei:
- `func download(url: URL) async throws -> URL`
- HTTP-Response Content-Type und Dateigroesse validieren
- Nach Download: Format-Validierung via `FileOpenHandler.canHandle()` (Content-Type vom Server kann luegen)
- Netzwerk-Fehler, 404, Timeout behandeln
- Lebt im Infrastructure-Layer (Netzwerk-IO)
- Minimale Implementierung, keine Wiederverwendung geplant

### 4. Download-UX

Kein eigener Screen — der Download ist ein Zwischenschritt vor der Typ-Auswahl:

- **Waehrend Download:** Indeterminate `ProgressView` mit "Meditation wird geladen..." + Cancel-Button. Kein Prozent-Balken (viele Server liefern kein Content-Length fuer Audiodateien).
- **Timeout:** 60 Sekunden (URLSession-Default).
- **Abbrechen:** Bricht URLSession-Task ab, raeumt Inbox-Eintrag auf.
- **Fehler:** Alert mit "Download fehlgeschlagen" + "Erneut versuchen" / "Abbrechen". Kein automatischer Retry.
- **App wird backgrounded:** Kein Background-URLSession. Download laeuft ~30s Standard-Background-Execution weiter. Reicht meistens. Falls nicht: URL-Referenz bleibt in der Inbox, erneuter Download beim naechsten App-Start.

### Fehlerfaelle aus dem Ticket

Die drei Ticket-Fehlerfaelle (falsches Format, korrupte Datei, Duplikat) werden vom bestehenden Import-Flow behandelt (`FileOpenHandler.prepareImport()` → Validierung → Import). Kein neuer Code noetig — der Share-Pfad muendet in denselben Flow wie "Oeffnen mit".

### Lokalisierung (DE + EN)

Neue Strings:
- **Extension:** Fehler-Alert Titel + Text (z.B. "Import fehlgeschlagen" / "Import failed")
- **Download-UX:** "Meditation wird geladen..." / "Loading meditation...", Cancel-Button
- **Download-Fehler:** Alert Titel + Text + "Erneut versuchen" / "Retry" + "Abbrechen" / "Cancel"

---

## Vorbereitung (manuell, vor Implementierung)

Extension Target muss in Xcode erstellt werden (CLI-Tools haben Kompatibilitaetsprobleme mit `PBXFileSystemSynchronizedRootGroup`):

1. File → New → Target → Share Extension → `StillMomentShareExtension`
2. Signing & Capabilities: App Group `group.com.stillmoment` fuer beide Targets
3. Commit: `chore(ios): add Share Extension target and App Group entitlement`

---

## Fachliche Szenarien

### AK: Share aus Safari (URL-Pfad)

- Gegeben: User hat MP3-Link in Safari geoeffnet
  Wenn: User tippt "Teilen" und waehlt Still Moment
  Dann: App oeffnet sich, Download-Indikator erscheint, dann Typ-Auswahl

- Gegeben: User teilt eine Nicht-Audio-URL (z.B. Webseite) an Still Moment
  Wenn: Extension prueft die URL-Endung
  Dann: Extension schliesst sich still, kein Fehler sichtbar

### AK: Share aus Files/Mail (Datei-Pfad)

- Gegeben: User hat MP3 als Mail-Anhang
  Wenn: User tippt "Teilen" und waehlt Still Moment
  Dann: App oeffnet sich, Typ-Auswahl erscheint direkt (kein Download)

### AK: App-Zustand

- Gegeben: Still Moment ist nicht gestartet
  Wenn: User teilt eine Audio-Datei an Still Moment
  Dann: App startet, Import-Flow beginnt

- Gegeben: Still Moment laeuft im Vordergrund
  Wenn: User teilt eine Audio-Datei an Still Moment
  Dann: App wechselt in den Import-Flow

### AK: Fehlerfaelle

- Gegeben: User teilt eine MP3-URL
  Wenn: Download scheitert (Netzwerk-Fehler, Timeout)
  Dann: Alert "Download fehlgeschlagen" mit "Erneut versuchen" und "Abbrechen"

- Gegeben: User teilt eine bereits importierte Datei
  Wenn: Import-Flow erkennt Duplikat
  Dann: Hinweis "Meditation bereits in der Bibliothek"

- Gegeben: User teilt eine korrupte Audio-Datei
  Wenn: Validierung schlaegt fehl
  Dann: Fehlermeldung "Datei konnte nicht importiert werden"

---

## Implementierungs-Reihenfolge

**iOS:**
1. ShareViewController (Extension-Code, inkl. Inbox-Schema)
2. URL-Scheme `stillmoment://import` registrieren + Inbox-Handler (Haupt-App)
3. Download-Service + Download-UX (fuer Safari-URLs)
4. Tests (Inbox-Handling, URL-Validierung, Download, Fehlerfaelle)

**Android:**
1. Intent-Filter fuer `ACTION_SEND` + `text/plain` in `AndroidManifest.xml` ergaenzen
2. `MainActivity.handleIncomingIntent()` erweitern: `text/plain` → URL aus `EXTRA_TEXT` extrahieren, Audio-Endung pruefen
3. Download-Service: URL → lokale Datei (OkHttp oder `HttpURLConnection`), Content-Type und Dateigroesse validieren
4. Download-UX: Indeterminate `ProgressView` mit "Meditation wird geladen..." + Cancel
5. Bei Nicht-Audio-URL: Activity still schliessen (kein Fehler sichtbar)
6. Bei Fehler (Netzwerk, Timeout): Alert analog zu iOS
7. Tests: URL-Erkennung, Download, Fehlerfaelle
8. Optional: Samsung Internet verifizieren (verhält sich vermutlich wie Chrome)

---

## Risiken

| Risiko | Mitigation |
|---|---|
| Extension erscheint fuer alle URLs | Stilles Schliessen bei nicht-Audio-URLs — keine Stoerung |
| Safari teilt Seiten-URL statt MP3-URL (eingebettete Player) | Nur direkte Datei-URLs unterstuetzen, kein HTML-Parsing |
| Download scheitert (Netzwerk, Timeout) | Fehlermeldung in der App, User kann es erneut versuchen |
| App-Oeffnung via URL-Scheme wird von Apple abgelehnt | Fallback: scenePhase-Polling, User oeffnet App manuell |
| App Group Entitlement falsch konfiguriert | Haeufigste Fehlerquelle bei Extensions — Provisioning Profile + Entitlements fuer beide Targets pruefen |
| Android: App erscheint bei jedem Text-Share | Stilles Schliessen bei Nicht-Audio-URLs — Android-User koennen Share Sheet sortieren |
| Android: Andere Browser (Samsung Internet, Firefox) verhalten sich anders als Chrome | Samsung Internet vermutlich identisch (Chromium-basiert). Firefox muss separat getestet werden |
