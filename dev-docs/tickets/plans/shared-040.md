# Implementierungsplan: shared-040 (iOS)

Ticket: [shared-040](../shared/shared-040-app-store-narrativ.md)
Erstellt: 2026-03-22
Aktualisiert: 2026-03-23

## Scope

Nur **Bilder 1-4 iOS**. Ausgelagert in eigene Tickets:
- Bild 5 (Zitat-Bild, rein typografisch)
- Keywords-Optimierung (Long-Tail)

---

## Bestandsaufnahme

### Was existiert

| Komponente | Status | Pfad |
|-----------|--------|------|
| Snapfile | Fertig | `ios/fastlane/Snapfile` (iPhone 17 Pro Max, de-DE + en-GB, iOS 26.1) |
| Screenshot UI Tests | 5 Tests | `ios/StillMomentUITests/ScreenshotTests.swift` |
| Screenshots Target | Fertig | `ios/StillMoment-Screenshots/` mit eigenem Scheme |
| Test Fixtures | 5 MP3s | `TestFixtureSeeder.swift` (Sarah Kornfield, Tara Goldstein, Jon Salzberg) |
| Fastfile Lanes | 3 Lanes | `screenshots`, `screenshot_single`, `screenshot_validate` |
| Post-Processing | Fertig | `ios/scripts/process-screenshots.sh` (kopiert + komprimiert fuer Website) |
| Makefile | Fertig | `make screenshots`, `make screenshot-single` |
| ImageMagick | Installiert | `brew install imagemagick` (7.1.2-18, Voraussetzung fuer frameit) |

### Was fehlt

| Komponente | Beschreibung |
|-----------|-------------|
| `Framefile.json` | frameit-Konfiguration (Background, Font, Padding) |
| `title.strings` | DE + EN Headlines pro Screenshot |
| `background.png` | Dunkles Hintergrundbild fuer frameit |

### Was sich aendern muss

5 bestehende Tests → 4 neue Tests mit neuen Szenen und Snapshot-Namen:

| Bild | Alt (aktuell) | Neu | Headline DE | Headline EN |
|------|--------------|-----|------------|------------|
| 01 | Timer idle mit Picker | Library (gefuellt, nach Lehrer gruppiert) | "Deine MP3s. Deine Praxis." | "Your MP3s. Your practice." |
| 02 | Timer running | Timer running (Candlelight Dark) | "Kein Abo. Keine Werbung." | "No subscription. No ads." |
| 03 | Library List | Praxis Editor (Gong-Section sichtbar) | "Stiller Timer mit Gongs." | "Silent timer with gongs." |
| 04 | Player View | Player im Zen Mode (Tab Bar weg) | "Kein Tracking. Keine Cloud." | "No tracking. No cloud." |

Alle Screenshots in **Candlelight Dark** Theme.

---

## Design-Entscheidungen

### 1. frameit fuer Headline-Compositing

**Entscheidung:** frameit (Teil von Fastlane, bereits installiert).

Deklarative Konfiguration ueber `Framefile.json` + `title.strings`. Kein Custom-Script noetig. ImageMagick ist Voraussetzung und installiert.

Alternative (Swift-Script mit Core Graphics) waere Overengineering — frameit erst testen, bei Bedarf umschwenken.

### 2. Ohne Device Frame (`show_complete_frame: false`)

**Entscheidung:** Kein Device-Rahmen um die Screenshots. Nur Headline oben + UI-Screenshot unten auf dunklem Hintergrund.

Begruendung: Ticket fordert "Headlines dominieren, UI ist Beiwerk". Device Frames lenken ab und verkleinern den Screenshot unnoetig. Falls frameit diesen Modus nicht gut unterstuetzt → Fallback mit Device Frame.

### 3. Background-Bild

**Entscheidung:** Solid-Color PNG in Candlelight Dark `backgroundPrimary` (`#1A100C`, rgb 0.102/0.063/0.047). Generiert via ImageMagick. Kann spaeter durch Gradient ersetzt werden.

### 4. Lehrer-Namen bleiben

**Entscheidung:** Bestehende Namen beibehalten (Sarah Kornfield, Tara Goldstein, Jon Salzberg). Leicht veraendert, kein Risiko mit echten Personen, realistisch genug fuer Screenshots.

### 5. Bild 3: PraxisEditorView (Uebersicht)

**Entscheidung:** PraxisEditorView selbst zeigen (nicht IntervalGongsEditorView). Die Uebersicht mit Sections (Preparation, Audio, Gongs) kommuniziert Konfigurationstiefe besser als ein Detailscreen. Headline "Stiller Timer mit Gongs" passt zur Uebersicht.

### 6. Font fuer Headlines

**Entscheidung:** SF Pro (Semibold). System-Font unter `/System/Library/Fonts/SFNS.ttf`. frameit bekommt diesen Pfad direkt — kein Download oder Bundling noetig. Weight-Steuerung ueber `font_weight` Parameter in Framefile.json.

---

## Betroffene Dateien

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `ios/fastlane/screenshots/Framefile.json` | **Neu** | frameit-Konfiguration |
| `ios/fastlane/screenshots/background.png` | **Neu** | Generiert: `magick -size 1290x2796 xc:'#1A100C' background.png` |
| `ios/fastlane/screenshots/de-DE/title.strings` | **Neu** | Deutsche Headlines |
| `ios/fastlane/screenshots/en-GB/title.strings` | **Neu** | Englische Headlines |
| `ios/StillMomentUITests/ScreenshotTests.swift` | **Aendern** | 5 alte Tests → 4 neue Tests |
| `ios/fastlane/Fastfile` | **Aendern** | `frame_screenshots` nach `capture_screenshots` einbauen |
| `ios/scripts/process-screenshots.sh` | **Aendern** | Naming-Mapping: 5 alte → 4 neue Namen |
| `ios/Makefile` | **Aendern** | Default THEME=candlelight MODE=dark fuer screenshots Target |

---

## Reihenfolge der Implementierung

### Phase 1: frameit-Infrastruktur (Proof of Concept)

Ziel: frameit auf den bestehenden Screenshots testen, ohne Tests zu aendern.

1. **Background-Bild generieren** — `magick -size 1290x2796 xc:'#1A100C' background.png`
2. **Framefile.json erstellen** — Background, Padding, Font, `show_complete_frame: false`
3. **title.strings anlegen** — DE + EN Headlines (erstmal mit alten Screenshot-Namen zum Testen)
4. **Fastfile anpassen** — `frame_screenshots(path: "./fastlane/screenshots")` nach `capture_screenshots`
5. **Proof of Concept** — `make screenshots THEME=candlelight MODE=dark`, visuell pruefen

→ Ergebnis: Alte Screenshots mit Frames + Headlines. Zeigt ob frameit-Output professionell genug aussieht.

### Phase 2: Screenshot-Tests umbauen

6. **ScreenshotTests umschreiben** — 4 neue Tests:
   - `testScreenshot01_libraryFilled` — Library-Tab, warten auf Test-Fixture-Rows
   - `testScreenshot02_timerRunning` — Timer-Tab, 10 min, Start tappen, warten auf Display
   - `testScreenshot03_praxisEditor` — Timer-Tab, Config-Button, warten auf PraxisEditorView, ggf. swipeUp fuer Gong-Section
   - `testScreenshot04_playerZenMode` — Library-Tab, erste Meditation tappen, Play tappen (Zen Mode), 0.8s warten
7. **title.strings aktualisieren** — Snapshot-Namen matchen: `01_LibraryFilled`, `02_TimerRunning`, `03_PraxisEditor`, `04_PlayerZenMode`
8. **process-screenshots.sh aktualisieren** — Neues Naming-Mapping:
   - `01_LibraryFilled` → `library-list`
   - `02_TimerRunning` → `timer-running`
   - `03_PraxisEditor` → `timer-settings`
   - `04_PlayerZenMode` → `player-view`
9. **Makefile** — Default `THEME=candlelight MODE=dark` fuer screenshots Target
10. **Pipeline testen** — `make screenshots`, alle 4 Bilder pruefen

### Phase 3: Verifizierung

11. **Visuell pruefen** — Headlines dominant? UI kleiner? Candlelight Dark korrekt?
12. **Einzeltest** — `make screenshot-single TEST=testScreenshot01_libraryFilled`
13. **Release-Validierung** — `make release-dry` (4 PNGs pro Locale)
14. **Website-Kopien** — `docs/images/screenshots/` korrekt?

---

## Offene Fragen

- [x] Lehrer-Namen: Bestehende Namen beibehalten
- [x] Bild 4: Player im Zen Mode
- [x] Font: SF Pro Display Semibold
- [x] Bild 5: Eigenes Ticket
- [x] Keywords: Eigenes Ticket
- [x] ImageMagick: Installiert (7.1.2-18)
- [x] SF Pro Font: System-Font `/System/Library/Fonts/SFNS.ttf`, kein Download noetig
- [ ] `show_complete_frame: false`: Testen ob frameit Headlines ohne Device Frame korrekt rendert. Fallback: mit Frame.

---

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| frameit ohne Device Frame sieht nicht gut aus | Phase 1 ist Proof of Concept — frueh pruefen, Fallback: mit Frame |
| SF Pro System-Font funktioniert nicht mit frameit | System-Font `/System/Library/Fonts/SFNS.ttf` direkt referenzieren, bei Bedarf Apple Developer Download |
| PraxisEditorView Gong-Section nicht sichtbar | swipeUp im Test, auf iPhone 17 Pro Max vermutlich ohne Scroll sichtbar |
