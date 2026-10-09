---
id: shared-127
title: Datenschutzerklaerung und Offline-Versprechen ehrlich formulieren
status:
  ios: in-progress
  android: in-progress
phase: 1-Quick Fix
priority: hoch
---

# Ticket shared-127: Datenschutzerklaerung und Offline-Versprechen ehrlich formulieren

**Komplexitaet**: Rein textlich, kein App-Code. Das Risiko liegt in der Formulierung: Die Aussage muss ehrlich sein, ohne das tatsaechlich starke Datenschutz-Versprechen zu verwaessern. Mehrere Stellen (Website, Store-Texte, README) in zwei Sprachen muessen konsistent bleiben.

---

## Was

Alle oeffentlichen Aussagen zu Datenschutz und Offline-Betrieb sollen beschreiben, wann die App tatsaechlich eine Internetverbindung nutzt: ausschliesslich dann, wenn der Nutzer selbst eine Aufnahme aus einem Link importiert. Das schliesst den kommenden Podcast-Import (shared-128, shared-129) bereits ein, bei dem die App zur Suche der Folge einmalig bei Apple nachfragt.

## Warum

Die Datenschutzerklaerung sagt heute "Sendet keine Daten an externe Server" und "operates entirely offline", Store-Texte und README werben mit "100% offline — kein Internet erforderlich". Seit dem Link-Import (shared-046, shared-091) stimmt das nicht mehr: Die App laedt Dateien vom Server des Anbieters. Mit dem Podcast-Import kommt ein Abruf bei Apple hinzu. Privacy ist ein Grundwert der App — gerade deshalb muss die Beschreibung genau stimmen. Das eigentliche Versprechen bleibt unveraendert: kein Tracking, keine eigenen Server, keine Kennungen, nichts ohne Nutzeraktion.

---

## Akzeptanzkriterien

### Datenschutzerklaerung (DE + EN)
- [ ] Beschreibt, dass die App nur dann eine Internetverbindung nutzt, wenn der Nutzer selbst eine Aufnahme aus einem Link importiert
- [ ] Nennt, wer dabei was sieht: der Anbieter der Aufnahme (IP-Adresse, wie bei jedem Download im Browser — gilt auch fuer den Abruf seines Podcast-Feeds) und beim Podcast-Import zusaetzlich Apple (welche Podcast-Folge nachgeschlagen wird — deckt sowohl den Lookup-Dienst als auch den Abruf der Folgenseite ab)
- [ ] Stellt klar, dass dabei keine Geraete- oder Nutzerkennungen uebertragen werden und Still Moment selbst keine Server betreibt und nichts erfasst
- [ ] Stellt klar, dass Meditieren (Timer, Wiedergabe der Bibliothek) vollstaendig ohne Internet funktioniert
- [ ] Enthaelt keine Aussage mehr, die dem tatsaechlichen Verhalten widerspricht ("keine Daten an externe Server" (Datenerfassung), "completely offline" (TL;DR), "entirely offline" (Kinder-Abschnitt))
- [ ] Abschnitt "Dateizugriff" beschreibt alle Importwege (Dateiauswahl, Teilen an die App, Link-Import), nicht nur die System-Dateiauswahl
- [ ] Widerspruch "Wir laden deine Dateien niemals hoch, kopieren oder uebertragen sie" vs. "werden in den App-Speicher kopiert" aufgeloest; veraltete Angaben (z.B. "security-scoped bookmarks", falls nicht mehr zutreffend) gegen den aktuellen Code geprueft
- [ ] Aktualisierungsdatum angepasst

### Weitere oeffentliche Aussagen
- [ ] App-Store-Beschreibung (iOS, alle Sprachen) und Play-Store-Beschreibung (Android, alle Sprachen): "100% offline — kein Internet erforderlich" und der Einstieg "Offline und ohne Tracking" / "Offline and tracking-free" durch zutreffende Aussagen ersetzt (z.B. Meditieren ohne Internet)
- [ ] `docs/app-store/APP_STORE_METADATA.md`: Beschreibungen, Feature-Listen und vor allem die **App-Review-Notes** ("operates entirely offline", "No data is sent to external servers") korrigiert — die Review-Notes liest Apples Pruefer
- [ ] Website: FAQ in `docs/support.html` ("Kein Internet erforderlich" / "No internet required") korrigiert
- [ ] README: Offline-Aussagen auf dieselbe zutreffende Formulierung gebracht
- [ ] Formulierungen in nicht-technischer Sprache, DE und EN inhaltlich deckungsgleich

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Datenschutzerklaerung auf der Website in DE und EN lesen
2. Erwartung: Ein nicht-technischer Leser versteht, wann die App ins Internet geht, wer dabei was erfaehrt, und dass beim Meditieren nichts uebertragen wird
3. Store-Texte, `APP_STORE_METADATA.md`, Website (Startseite, Support-FAQ) und README durchsuchen
4. Erwartung: Keine Stelle verspricht mehr "100% offline" oder "kein Internet erforderlich" ohne Einschraenkung

---

## Hinweise

- Die App-Store-Datenschutzangabe ("Keine Daten erfasst") bleibt korrekt: Apple definiert "erfassen" als Uebertragung an den Entwickler oder Dritte zur Speicherung/Auswertung. Trotzdem beim Release pruefen.
- Ebenso die Datensicherheitsangaben in der Play Console beim Release pruefen (Android deklariert die `INTERNET`-Berechtigung).
- Bleiben duerfen Aussagen, die weiterhin zutreffen: Keyword "offline" (iOS-Keywords, `<meta keywords>` der Website) und die Startseite `docs/index.html` ("jederzeit, offline" bezieht sich aufs Abspielen). Nicht um der Einheitlichkeit willen umformulieren.
- Bewusst vor dem Podcast-Import umsetzen: Die Korrektur ist wegen des Link-Imports ohnehin faellig und soll nicht auf das Feature warten. Den Apple-Abruf direkt mit aufnehmen, damit die Texte nicht zweimal angefasst werden.
- Hintergrund und Entscheidungen: `dev-docs/concepts/podcast-import.md`
- Betrifft keinen App-Code. Die Spalten stehen fuer die Store-Texte der jeweiligen Plattform; Website und README gelten fuer beide.

---

## Referenz

- Datenschutzerklaerung: `docs/privacy.html`
- Store-Texte: Fastlane-Metadaten beider Plattformen (`ios/fastlane/metadata/*/description.txt`, `android/fastlane/metadata/android/*/full_description.txt`)
- Store-Metadaten-Vorlage inkl. App-Review-Notes: `docs/app-store/APP_STORE_METADATA.md`
- Website-FAQ: `docs/support.html`
- Netzwerkzugriffe im Code: `ios/StillMoment/Infrastructure/Services/AudioDownloadService.swift`, `android/app/src/main/kotlin/com/stillmoment/infrastructure/network/UrlAudioDownloaderImpl.kt`
