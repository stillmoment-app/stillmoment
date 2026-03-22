# Implementierungsplan: shared-040

Ticket: [shared-040](../shared/shared-040-app-store-narrativ.md)
Erstellt: 2026-03-22

## Bestandsaufnahme

### Was existiert

| Komponente | Status | Pfad |
|-----------|--------|------|
| Snapfile | Fertig | `ios/fastlane/Snapfile` (iPhone 17 Pro Max, de-DE + en-GB) |
| Screenshot UI Tests | 5 Tests | `ios/StillMomentUITests/ScreenshotTests.swift` |
| Screenshots Target | Fertig | `ios/StillMoment-Screenshots/` mit eigenem Scheme |
| Test Fixtures | 5 MP3s | `TestFixtureSeeder.swift` (Sarah Kornfield, Tara Goldstein, Jon Salzberg) |
| Fastfile Lanes | 3 Lanes | `screenshots`, `screenshot_single`, `screenshot_validate` |
| Post-Processing | Fertig | `ios/scripts/process-screenshots.sh` (kopiert + komprimiert fuer Website) |
| Makefile | Fertig | `make screenshots`, `make screenshot-single` |
| Metadata | Fertig | `ios/fastlane/metadata/{de-DE,en-GB}/` (alle Felder) |
| Framefile.json | **FEHLT** | — |
| .strings fuer Headlines | **FEHLT** | — |
| Background-Bild | **FEHLT** | — |
| Bild 5 (Zitat) Pipeline | **FEHLT** | — |

### Was sich aendern muss

**Screenshot-Tests:** Die 5 bestehenden Tests erzeugen die falschen Bilder. Neues Mapping:

| Bild | Alt (aktuell) | Neu | Headline DE | Headline EN |
|------|--------------|-----|------------|------------|
| 01 | Timer idle mit Picker | Library (gefuellt) | "Deine MP3s. Deine Praxis." | "Your MP3s. Your practice." |
| 02 | Timer running | Timer running (Candlelight Dark) | "Kein Abo. Keine Werbung." | "No subscription. No ads." |
| 03 | Library List | Praxis Editor (Gong-Settings) | "Stiller Timer mit Gongs." | "Silent timer with gongs." |
| 04 | Player View | Player (Zen Mode) | "Kein Tracking. Keine Cloud." | "No tracking. No cloud." |
| 05 | Settings View | Zitat (rein typografisch) | Philosophie-Zitat | Philosophie-Zitat EN |

**Test Fixtures:** Lehrer-Namen muessen realistischer werden fuer Bild 1 (aktuell: Sarah Kornfield, Tara Goldstein, Jon Salzberg — angelehnt an echte Lehrer aber nicht echt genug). Ticket fordert: "Tara Brach, Jack Kornfield, Gil Fronsdal".

**Keywords (aktuell):**
- DE: `meditation,timer,achtsamkeit,privat,offline,geführt,eigene,bibliothek,audio,importieren`
- EN: `meditation,timer,mindfulness,private,offline,guided,own,library,audio,import,free`

Muessen optimiert werden auf Long-Tail (siehe Ticket).

---

## Design-Entscheidungen

### 1. frameit vs. ImageMagick direkt

**Trade-off:** frameit ist Fastlane-nativ und einfach zu konfigurieren, kann aber keine Bilder ohne Device Frame erzeugen (Bild 5). ImageMagick direkt waere flexibler, aber mehr Aufwand.

**Entscheidung:** Hybridansatz.
- Bild 1-4: frameit (Device Frame + Headline + Background)
- Bild 5: eigenes Script mit ImageMagick (`convert` oder `magick`) — erzeugt rein typografisches Bild

### 2. Lehrer-Namen in Test Fixtures

**Trade-off:** Echte Namen (Tara Brach, Jack Kornfield) sind realistischer, aber es sind reale Personen. Leicht veraenderte Namen (Sarah Kornfield) vermeiden rechtliche Fragen, wirken aber kuenstlich.

**Entscheidung:** Offen — User muss entscheiden. Echte Namen sind im Store ueblich (Insight Timer zeigt sie), aber Still Moment hat keinen Bezug zu diesen Lehrern.

### 3. Background-Bild fuer frameit

**Trade-off:** frameit braucht ein Background-Bild (nicht einfach eine Farbe). Optionen:
- a) 1-Pixel-Bild in App-Hintergrundfarbe (minimalistisch, konsistent mit App)
- b) Gradient oder Textur (professioneller, aber muss zum App-Design passen)

**Entscheidung:** Option a) als Start — ein einfaches dunkles Bild das zum Candlelight Dark Theme passt. Kann spaeter durch Gradient ersetzt werden.

---

## Betroffene Dateien

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `ios/fastlane/Framefile.json` | **Neu** | frameit-Konfiguration (Headlines, Font, Background, Padding) |
| `ios/fastlane/screenshots/de-DE/title.strings` | **Neu** | Deutsche Headlines pro Screenshot |
| `ios/fastlane/screenshots/en-GB/title.strings` | **Neu** | Englische Headlines pro Screenshot |
| `ios/fastlane/screenshots/background.png` | **Neu** | Dunkles Hintergrundbild fuer frameit |
| `ios/scripts/generate-quote-image.sh` | **Neu** | ImageMagick-Script fuer Bild 5 (Zitat) |
| `ios/StillMomentUITests/ScreenshotTests.swift` | **Aendern** | Tests umbauen (neue Reihenfolge, neue Szenarien) |
| `ios/StillMoment-Screenshots/TestFixtureSeeder.swift` | **Aendern** | Lehrer-Namen aktualisieren |
| `ios/fastlane/Fastfile` | **Aendern** | frameit-Schritt in `screenshots` Lane einbauen |
| `ios/scripts/process-screenshots.sh` | **Aendern** | Neues Naming-Mapping, Bild 5 integrieren |
| `ios/Makefile` | **Pruefen** | Evtl. ImageMagick-Dependency dokumentieren |
| `ios/fastlane/metadata/de-DE/keywords.txt` | **Aendern** | Long-Tail Keywords |
| `ios/fastlane/metadata/en-GB/keywords.txt` | **Aendern** | Long-Tail Keywords |

---

## Reihenfolge der Implementierung

### Phase 1: frameit-Infrastruktur (ohne Tests zu aendern)

1. **Background-Bild erzeugen** — dunkles PNG fuer frameit
2. **Framefile.json erstellen** — Headlines, Font, Padding, Background konfigurieren
3. **title.strings anlegen** — DE + EN Headlines pro Screenshot
4. **Fastfile anpassen** — `frame_screenshots` nach `capture_screenshots` einbauen
5. **Testen** — `make screenshots` ausfuehren, pruefen ob bestehende Screenshots + Frames korrekt aussehen

→ Ergebnis: Die alten Screenshots bekommen schon mal Frames + Headlines. Proof of Concept.

### Phase 2: Screenshot-Tests umbauen

6. **TestFixtureSeeder anpassen** — neue Lehrer-Namen, ggf. mehr Fixtures
7. **ScreenshotTests umschreiben** — neue Reihenfolge, neue Szenarien:
   - `testScreenshot01_libraryFilled` — Library mit Lehrer-Gruppierung (USP-Shot)
   - `testScreenshot02_timerRunning` — Timer in Candlelight Dark
   - `testScreenshot03_praxisEditor` — Praxis Editor mit Gong-Konfiguration sichtbar
   - `testScreenshot04_playerZenMode` — Player mit laufender Meditation im Zen Mode (Tab Bar weg)
8. **title.strings aktualisieren** — neue Headlines passend zu neuen Screenshots
9. **Testen** — `make screenshots`, Ergebnis pruefen

### Phase 3: Bild 5 (Zitat)

10. **generate-quote-image.sh erstellen** — ImageMagick-Script das Zitat-Bild in korrekter Store-Aufloesung erzeugt (1290x2796px fuer iPhone 17 Pro Max)
11. **process-screenshots.sh anpassen** — Bild 5 aus Script-Output integrieren
12. **Fastfile anpassen** — Zitat-Generierung in Pipeline einbauen
13. **Testen** — Gesamtpipeline: `make screenshots` erzeugt alle 5 Bilder fertig geframed

### Phase 4: Keywords + Metadaten

14. **Keywords optimieren** — Long-Tail Keywords fuer DE + EN
15. **release_dry** — Validierung dass alles zusammenpasst

---

## Offene Fragen

- [x] **Lehrer-Namen:** Weiterhin leicht veraenderte Namen (kein Risiko mit echten Personen)
- [x] **Bild 4 (Privacy):** Player im Zen Mode — zeigt Zurueckhaltung visuell, Privacy-Headline passt dazu
- [x] **Font fuer Headlines:** SF Pro Display, Semibold — konsistent mit App, lesbar im Store, kein Custom Font noetig
- [x] **Android:** Spaeter, eigener Plan
- [ ] **ImageMagick-Dependency:** Ist ImageMagick auf dem CI installiert? frameit braucht es sowieso, aber fuer Bild 5 brauchen wir erweiterte Features (Text-Rendering)

---

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| frameit-Layout sieht nicht professionell genug aus | Phase 1 ist ein Proof of Concept — frueh pruefen, bei Bedarf auf Canva/Figma ausweichen |
| ImageMagick Text-Rendering fuer Bild 5 sieht schlecht aus (Kerning, Anti-Aliasing) | Alternative: HTML→Screenshot via `wkhtmltoimage` oder Playwright |
| Lehrer-Namen-Diskussion blockiert den Rest | Phase 1+3 sind unabhaengig von den Namen, koennen vorab umgesetzt werden |
| iPhone 17 Pro Max Simulator nicht verfuegbar | Snapfile auf verfuegbaren Simulator anpassen, Aufloesung pruefen |
