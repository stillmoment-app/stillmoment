# Ticket ios-057: Unit-Tests hinterlassen keine Daten im echten App-Ordner

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Komplexitaet**: Die Ursache ist noch nicht bestätigt. Der Aufwand liegt im Finden aller Tests, die über einen echten Dienst in den Datenbestand der App schreiben (Dateien und gespeicherte Einstellungen). Risiko: Ein Test, der heute zufällig auf solche Reste angewiesen ist, wird nach der Bereinigung rot.
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

Die Unit-Tests schreiben nichts in den echten Datenbestand der App auf dem Simulator: keine Dateien im Meditations-Ordner und keine Einträge in den gespeicherten Einstellungen. Wo ein Test echte Dateien braucht, räumt er sie vollständig wieder auf. Ein Test oder Check belegt, dass nach einem Lauf nichts übrig bleibt.

## Warum

Die Unit-Tests laufen innerhalb der App auf dem Simulator. Nach einem Lauf am 08.10.2026 lagen dort 96 leere Audio-Dateien im echten Meditations-Ordner der App. Früher hat ein Test auf demselben Weg sogar einen Bibliothekseintrag gespeichert, der seitdem UI-Tests rot macht (siehe ios-056). Solche Reste verfälschen spätere Testläufe und manuelle Tests am Simulator, und sie bleiben unbemerkt, bis etwas Unerklärliches passiert.

---

## Akzeptanzkriterien

### Feature
- [ ] Nach einem vollständigen Lauf der Unit-Tests enthält der Meditations-Ordner der App auf dem Simulator keine neuen Dateien.
- [ ] Nach einem vollständigen Lauf der Unit-Tests enthalten die gespeicherten Einstellungen der App keine neuen oder veränderten Einträge (Bibliothek, Timer-Einstellungen usw.).
- [ ] Die tatsächliche Ursache ist im Ticket festgehalten (Hypothese unten bestätigt oder widerlegt).

### Tests
- [ ] Ein Test oder automatischer Check schlägt fehl, wenn ein Unit-Test Dateien im echten Meditations-Ordner oder Einträge in den echten gespeicherten Einstellungen hinterlässt.
- [ ] Alle bestehenden Unit-Tests sind grün.

### Dokumentation
- [ ] `dev-docs/guides/tdd.md` bzw. `ios/CLAUDE.md`: Regel ergänzen, dass Unit-Tests nur in eigene, temporäre Speicherorte schreiben und hinter sich aufräumen.

---

## Manueller Test

1. Auf dem Simulator, auf dem die Unit-Tests laufen, den Meditations-Ordner der App leeren bzw. den Inhalt notieren.
2. `make test-unit-agent` ausführen.
3. Erwartung: Der Meditations-Ordner enthält danach dieselben Dateien wie vorher, die Bibliothek der App zeigt beim normalen Start dieselben Einträge wie vorher.

---

## Referenz

- Muster der gefundenen Dateien: `test_audio_<UUID>.mp3`, erzeugt von `GuidedMeditationTestHelpers.createTemporaryAudioFile()` in `ios/StillMomentTests/Helpers/` (bzw. Kopien davon)
- Verwandt: ios-056 (UI-Tests robust gegen solche Reste), ios-055 (keine Default-Instanzen von Diensten mehr)

---

## Hinweise

- **Hypothese, nicht verifiziert:** Tests des Meditations-Dienstes importieren temporäre Audio-Dateien über den echten Dienst. Der kopiert sie in den realen Meditations-Ordner der App, und der Test räumt die Kopie nicht auf. Die Verifikation gehört zur Umsetzung.
- Der alte Bibliothekseintrag („Achtsame Übung“ / „Melissa Gein“, 13.09.2026) ist sehr wahrscheinlich über einen damals per Default-Argument erzeugten Dienst in die echten gespeicherten Einstellungen gelangt. ios-055 entfernt solche Defaults und schließt diesen Weg vermutlich bereits. Das ist beim Umsetzen zu prüfen, nicht vorauszusetzen.
- **Empfehlung aus der Recherche** ([ios-ui-test-isolation.md](../../concepts/ios-ui-test-isolation.md)), kein Lösungszwang:
  - Die Dateipfade sind heute fest an `applicationSupportDirectory` gebunden: `GuidedMeditationService.swift:138`, `CustomAudioRepository.swift:149`, `WaveformCacheService.swift:77`. Das passt zur Hypothese, beweist sie aber noch nicht.
  - Basisverzeichnis (und `UserDefaults`, das teils schon übergebbar ist) übergebbar machen, gesetzt in `AppDependencies.live()`. Tests nutzen ein temporäres Verzeichnis und eine eigene `UserDefaults`-Suite und räumen in `tearDown` auf.
  - Die Host-App erkennt den Unit-Test-Lauf (z. B. `NSClassFromString("XCTestCase")` oder Umgebungsvariable im Scheme, WWDC18-417) und startet ohne echte Dienste, Migrationen und Seeding.
  - Gemeinsame Vorarbeit mit ios-056, das für den UI-Test-Modus ebenfalls einen getrennten Speicherort braucht.
- **Weiterer Kandidat (Review ios-055):** Viele Dienste haben Default-Argumente auf die echten System-Speicher (`UserDefaults = .standard`, `FileManager = .default`). Vergisst ein Test, eigene Speicherorte zu übergeben, springt der Default still ein, und der Test schreibt in den echten Datenbestand. Die DI-Regel erlaubt diese Defaults bewusst (in der App erzeugen sie keine zweite Instanz). Möglicher Lösungsweg: die Defaults entfernen und die Speicherorte ausdrücklich in `AppDependencies.live()` übergeben. Dann zwingt der Compiler jeden Test, einen Speicherort zu wählen. Nebeneffekt: `live()` lässt sich mit temporären Speicherorten testen. Damit wäre auch die bisher nur per Review gesicherte innere Verdrahtung von `live()` testbar (siehe Plan ios-055, „Bewusste Restlücken“).
- Prioritaet NIEDRIG, weil Nutzer nicht betroffen sind: Die Reste entstehen nur auf Entwickler-Simulatoren. Die sichtbaren Folgen für die UI-Tests fängt ios-056 ab.
