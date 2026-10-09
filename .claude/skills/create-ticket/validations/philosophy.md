# Ticket-Philosophie Validierung

Prueft, ob ein Ticket das Problem beschreibt und die Loesung dem Umsetzer laesst.

## Die vier Fragen

Stelle sie fuer **jede Zeile** des fertigen Entwurfs, in allen Abschnitten:

| # | Frage | Wenn ja |
|---|-------|---------|
| 1 | **Entscheidet das der Umsetzer?** (Datei, Methode, Pattern, Schicht, Ablauf im Code) | Streichen. Steckt eine fachliche Anforderung dahinter, diese stattdessen nennen. |
| 2 | **Stammt der Begriff aus dem Code statt aus dem Glossar?** | Durch den Begriff aus `dev-docs/reference/glossary.md` ersetzen. Gibt es keinen, ist der Begriff neu: im Ticket fachlich erklaeren. |
| 3 | **Braucht man Code, um die Zeile zu pruefen?** | So umformulieren, dass man sie an der App, an einem Test-Ergebnis oder an Daten pruefen kann. |
| 4 | **Steht das schon an anderer Stelle im Ticket?** | Streichen. |

Warum Glossar-Begriffe: Ohne Pfade ist der Fachbegriff die Bruecke vom Ticket zum Code. iOS, Android und Glossar verwenden dieselben Namen — ein Agent, der den Glossar-Begriff liest, findet die passenden Stellen auf beiden Plattformen; ein selbst gewaehltes Synonym fuehrt ins Leere.

## Was im Ticket bleibt

| Bleibt | Beispiel |
|--------|----------|
| **Konkrete Daten an der Grenze zur Aussenwelt** — Beispielwerte, Grenzwerte, Formate, URLs, Fehlermeldungen | "Angenommen werden `audio/mpeg`, `audio/mp4`, …"; "Meldung: \"Folge nicht verfuegbar\"" |
| **Getroffene Entscheidungen mit Begruendung** | "Nur die Link-Vorschau der Seite nutzen, nicht den internen Datenblock — undokumentiert, und die Nutzungsbedingungen verbieten Scraping." |
| **Rahmenbedingungen, die der Umsetzer nicht herleiten kann** | "Apples Lookup-Dienst liefert hoechstens die 200 neuesten Folgen." |
| **Verweise auf Tickets und Konzeptdokumente** | "Vorschlaege wie in shared-128"; "Recherche: `dev-docs/concepts/podcast-import.md`" |
| **Fachliche Vorbilder** | "Gleiches Ladefenster wie beim Link-Import" |

Faustregel fuer `## Hinweise`: Eine Zeile sagt, **was gilt** oder **was nicht in Frage kommt, und warum**. Wie man vorgeht, findet `/plan-ticket`.

## Vorher / Nachher

| Vorher | Nachher | Frage |
|--------|---------|-------|
| "In AudioService.swift eine Methode stopWithFade() einbauen, die ueber 2 Sekunden ausblendet" | "Die Soundscape blendet beim Stoppen sanft aus (ca. 2 Sekunden)" | 1, 2 |
| "MPRemoteCommandCenter.togglePlayPauseCommand registrieren" | "Die Play/Pause-Taste am Kopfhoerer startet und pausiert die Meditation" | 1, 2 |
| "AudioSessionCoordinatorProtocol im Domain-Layer hinzufuegen" | "Startet eine Meditation, stoppt eine laufende Vorschau" | 1, 3 |
| "Zuordnung ueber den exakten Titel (`<item><title>`)" | "Importiert wird nur, wenn genau eine Folge im Feed exakt den gesuchten Titel traegt" | 1 |
| "Die Lint-Ausnahme entfaellt" | "Der Audio-Koordinator ist nicht mehr global erreichbar" — oder streichen, wenn das ein Mittel und kein Ziel ist | 1, 3 |
| "Referenz: `ios/StillMoment/Infrastructure/Services/AudioDownloadService.swift`" | streichen — `/plan-ticket` findet die Dateien | 1 |

## Beispiel-Rueckmeldung an den User

Nur zeigen, wenn eine Streichung Inhalt betrifft, den der User ausdruecklich genannt hat:

```
Im Entwurf standen Umsetzungsdetails aus deiner Beschreibung:
- Methode stopWithFade() in AudioService.swift

Vorschlag:
"Die Soundscape blendet beim Stoppen sanft aus (ca. 2 Sekunden)"

Soll ich das Ticket so erstellen?
```
