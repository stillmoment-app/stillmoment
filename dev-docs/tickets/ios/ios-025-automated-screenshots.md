# Ticket ios-025: Vollautomatische Screenshot-Generierung

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: ios-023 (Screenshots-Target)
**Phase**: 5-QA

---

## Was

XCUITest-basierte Screenshot-Automatisierung mit Fastlane Snapshot einrichten,
die alle relevanten App-Zustaende in DE + EN automatisch erfasst.

## Warum

Das aktuelle interaktive Skript erfordert manuelle Bedienung (5-10 Min pro Durchlauf).
Vollautomatische Screenshots ermoeglichen reproduzierbare Ergebnisse fuer
Website-Updates und App Store Releases.

---

## Akzeptanzkriterien

- [x] Ruby-Environment isoliert (rbenv + Bundler + vendor/bundle)
- [x] .ruby-version im Projekt (3.2.2)
- [x] ScreenshotTests.swift im StillMomentUITests Target
- [x] Fastlane Snapshot Konfiguration (Gemfile, Snapfile, Fastfile)
- [x] Screenshots in App Store Groesse (6.7" iPhone 15 Plus)
- [x] Screenshots fuer DE + EN generiert
- [x] `make screenshots` fuehrt vollautomatischen Prozess aus
- [x] Screenshots landen in `docs/images/screenshots/`

## Screenshots (4 Szenen)

| Screenshot | Beschreibung | Automatisierung |
|------------|--------------|-----------------|
| timer-main | Timer Idle mit Zeitauswahl | App starten, Screenshot |
| timer-running | Laufender Timer (~09:55) | 10 Min waehlen, starten, 5s warten |
| library-list | Bibliothek mit Test-Meditations | Screenshots-Target, Library-Tab |
| player-view | Player mit Meditation | Meditation antippen |

---

## Manueller Test

1. `cd ios && make screenshots` ausfuehren
2. Erwartung: 8 Screenshots in `docs/images/screenshots/` (4 Szenen x 2 Sprachen)
3. Keine manuelle Interaktion noetig

---

## Referenz

- Screenshots-Target mit Test-Fixtures: ios-023
- UI Tests: `ios/StillMomentUITests/ScreenshotTests.swift`
- Dokumentation: `dev-docs/SCREENSHOTS.md`

---

## Hinweise

### Ruby-Environment Isolation

Standard-Setup fuer Fastlane ohne System-Ruby-Konflikte:
- rbenv fuer Ruby-Versionsverwaltung
- .ruby-version Datei im ios/ Ordner
- Bundler mit vendor/bundle (lokale Gems)
- `bundle exec fastlane` statt direktem Aufruf

### App Store Screenshot-Groessen

Apple erlaubt Media Manager: Ein Screenshot-Set fuer 6.7" reicht,
automatische Skalierung fuer kleinere iPhones (6.5", 5.5").
Nur iPhone 15 Pro Max als Device konfigurieren.

### Pragmatischer Ansatz fuer Timer-Running

Statt exakte Zeit (z.B. 4:37 von 15:00) wird eine akzeptable Zeit verwendet:
- 10 Minuten waehlen, starten, 5 Sekunden warten
- Ergebnis: ~09:55 (ausreichend fuer Marketing-Screenshots)
- Vermeidet komplexe Time-Travel-Logik oder 10+ Minuten Wartezeit

### Fastlane Snapshot

- Industrie-Standard fuer iOS Screenshot-Automatisierung
- Verwendet XCUITests mit `snapshot()` Funktion
- Multi-Language Support built-in
- Ruby-basiert (Bundler fuer Dependency Management)

### Screenshots-Target Nutzung

- Tests muessen gegen `StillMoment-Screenshots` Scheme laufen
- Test-Fixtures (5 Meditations) sind automatisch vorhanden
- Kein manueller MP3-Import noetig

### Web-Optimierung

- `process-screenshots.sh` komprimiert automatisch mit `sips -Z 512`
- Reduziert Screenshots von ~500KB auf ~50-150KB
- Erfuellt Website-Guideline (<200KB pro Bild)
