# Ticket shared-105: Trim-Punkte fuer gefuehrte Meditationen

**Status**: [x] DONE (iOS + Android)
**Prioritaet**: MITTEL
**Komplexitaet**: Mittel. Datenmodell und Persistenz sind einfache Ergaenzungen; die Risiken liegen im Wiedergabe-Verhalten (Ende am Endpunkt muss auch bei gesperrtem Bildschirm zuverlaessig greifen) und in der Validierung der Zeitangaben.
**Phase**: 3-Feature

---

## Was

User koennen pro Meditation einen optionalen Startpunkt und Endpunkt festlegen. Die Wiedergabe beginnt am Startpunkt und endet am Endpunkt — die Audiodatei selbst bleibt unveraendert (nicht-destruktiv).

## Warum

Importierte Audio-Dateien enthalten oft Einleitungen oder Abschluss-Saetze (teils mit Werbung fuer Kurse), die man nicht bei jeder Meditation hoeren will. Einmal eingestellt, laeuft jede Wiedergabe ohne Intro/Outro — passend zum Kern-Use-Case "starten und Handy weglegen".

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | Phase A Trim-Fundament + Editor-UI via shared-107 (Android-Parität Phase C, 2026-06-16) |

**Android-Fortschritt:** Phase A (Trim-Fundament) umgesetzt — Datenmodell (`trimStartMs`/`trimEndMs`, `effective*`-Properties, effektive vs. volle Dauer), nicht-destruktives getrimmtes Playback (Seek-to-Start nach Seek-Complete, End-Boundary via Progress-Loop auch bei gesperrtem Bildschirm, Bereichs-Klemmung für Skip/Lock-Screen-Seek, bereichs-relative Anzeige), Backward-Compat-Persistenz. Das Editor-UI (Eingabe der Trim-Punkte) kam mit dem Wellenform-Editor in Android-Parität Phase C (shared-107) — seitdem ist shared-105 auf Android user-sichtbar abgeschlossen.

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Edit-Sheet bietet zwei optionale Zeitangaben: "Beginnen bei" und "Beenden bei"
- [ ] Pro Zeitangabe gibt es eine Vorhoer-Moeglichkeit ("ab hier anhoeren"), um den Punkt zu pruefen
- [ ] Ungueltige Angaben werden verhindert: Startpunkt liegt vor Endpunkt, beide innerhalb der Dateidauer
- [ ] Wiedergabe startet am Startpunkt (falls gesetzt)
- [ ] Wiedergabe endet am Endpunkt (falls gesetzt) und verhaelt sich dann wie ein regulaeres Ende (inkl. Abschluss-Screen)
- [ ] Wiedergabe endet auch bei gesperrtem Bildschirm zuverlaessig am Endpunkt
- [ ] Spulen/Ueberspringen im Player bleibt innerhalb des Bereichs zwischen Start- und Endpunkt
- [ ] Die in der Bibliothek und im Player angezeigte Dauer ist die effektive (getrimmte) Dauer
- [ ] Meditationen ohne Trim-Punkte spielen unveraendert (bestehende Bibliothek bleibt unberuehrt)
- [ ] Trim-Punkte bleiben nach App-Neustart erhalten
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS
- [ ] Unit Tests Android

### Dokumentation
- [ ] CHANGELOG.md
- [ ] GLOSSARY.md (Begriff "Trim-Punkte" / "Startpunkt/Endpunkt")

---

## Manueller Test

1. Meditation mit Einleitung importieren, Edit-Sheet oeffnen
2. "Beginnen bei" auf das Ende der Einleitung setzen, per Vorhoeren pruefen, speichern
3. "Beenden bei" vor den Abschluss-Satz setzen, per Vorhoeren pruefen, speichern
4. Meditation abspielen, Handy sperren
5. Erwartung: Wiedergabe startet ohne Einleitung, endet vor dem Abschluss-Satz mit regulaerem Abschluss-Screen; angezeigte Dauer entspricht der getrimmten Laenge — identisch auf beiden Plattformen

---

## Referenz

- Bestehendes Edit-Sheet fuer Meditations-Metadaten (Name/Teacher) als Ort fuer die neuen Eingaben
- Library-Preview mit Scrub-Slider (shared-098) als Referenz fuer Vorhoer-Verhalten

---

## Hinweise

- Bewusst minimales UI: einfache Zeiteingaben plus Vorhoeren. Ein verfeinertes Auswahl-UI (z.B. Slider mit zwei Reglern) ist explizit NICHT in Scope und kommt spaeter als eigenes Ticket, nachdem Erfahrung mit der minimalen Version gesammelt wurde.
- Android: Dateien liegen hinter Content-URIs (SAF) — deshalb nicht-destruktiv arbeiten, die Datei wird nie veraendert.
