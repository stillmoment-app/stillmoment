# Akzeptanzkriterien Validierung

Pruefregeln und Beispiele fuer gute Akzeptanzkriterien.

Akzeptanzkriterien sind der Fahrplan fuer `/implement-ticket`: Jedes Kriterium wird einzeln per TDD umgesetzt und von `/review-code` einzeln geprueft. Ein gutes Kriterium laesst sich direkt in einen Test oder einen manuellen Pruefschritt uebersetzen.

## Eigenschaften guter Kriterien

| Eigenschaft | Beispiel |
|-------------|----------|
| **Beobachtbar** | "Settings zeigt neue Section 'Vorbereitungszeit'" |
| **Konkret** | "Picker zeigt Optionen: 5s, 10s, 15s, 20s, 30s" |
| **Pruefbar** | "Bei Toggle 'Aus' startet Timer sofort" |
| **User-zentriert** | "Einstellung bleibt nach App-Neustart erhalten" |

**Konkrete Beispiele** machen ein Kriterium zum Test: Eingabe → erwartetes Ergebnis, Grenzwerte, Formate. Sie gehoeren ins Kriterium, nicht in die Hinweise.

**Erhalt-Kriterien** sichern bestehendes Verhalten, das die Aenderung gefaehrden koennte und das ein Nutzer bemerken wuerde: "Start-, Intervall- und End-Gong spielen weiterhin bei gesperrtem Bildschirm." Was man nur im Code oder Netzwerk-Mitschnitt sieht (keine Cookies, keine Restdateien), sichern die bestehenden Tests — das regelt die Definition of Done.

**Fachliche Testfaelle** sind willkommen, wenn sie Faelle benennen statt Taetigkeiten: "Eindeutiger Treffer, kein Treffer, mehrere gleiche Titel" — nicht "Unit Tests schreiben". Dass getestet wird, regelt die Definition of Done in `dev-docs/tickets/README.md`.

## Schlechte vs. gute Kriterien

| Schlecht | Besser |
|----------|--------|
| "Funktioniert richtig" | "Timer zaehlt von 10:00 auf 0:00" |
| "Verwendet DataStore" | "Einstellung wird persistent gespeichert" |
| "Performance verbessert" | "Liste laedt in unter 500ms" |
| "Wie erwartet" | "Sound pausiert wenn andere Audio spielt" |
| "Unit Tests iOS" | streichen (Definition of Done) — oder fachliche Faelle nennen |
| "CHANGELOG.md" | streichen (Definition of Done) |

---

## Pflicht-Pruefungen (blockieren Ticket-Erstellung)

### 1. Kriterien vorhanden
- Sektion "Akzeptanzkriterien" existiert
- Mindestens 2 echte Kriterien

### 2. Platzhalter erkennen
- `Kriterium 1`, `Kriterium 2`, etc.
- `{...}` Template-Platzhalter

### 3. Jedes Kriterium ist pruefbar
- Fuer jedes Kriterium laesst sich ein Test oder ein manueller Pruefschritt angeben, dessen Ergebnis bestanden/nicht bestanden ist

---

## Qualitaets-Warnungen (User entscheidet)

### 4. Vage Formulierungen
Warne bei: `funktioniert richtig`, `wie erwartet`, `ist schnell`, `sieht gut aus`

### 5. Taetigkeit statt Ergebnis
Warne bei: `Verwendet X`, `Refactored zu`, `Ruft API auf`, `Tests schreiben`, `Doku aktualisieren`

### 6. Erhalt-Kriterium fehlt
Warne, wenn Recherche oder Gespraech bestehendes Verhalten als gefaehrdet benannt haben, aber kein Kriterium es sichert

---

## Ablauf

```
1. PFLICHT pruefen → Bei Fehler: Ticket nicht erstellen
2. WARNUNGEN sammeln → Mit Verbesserungsvorschlaegen anzeigen
3. User fragen: "Trotzdem erstellen?"
```

---

## Beispiel: Gutes Ticket

**ios-029: Konfigurierbare Vorbereitungszeit**

```markdown
## Was

Die Vorbereitungszeit vor der Meditation soll konfigurierbar werden.
User koennen sie an/aus schalten und zwischen 5s bis 45s waehlen.

## Warum

Erfahrene Meditierende moechten direkt starten, andere brauchen
mehr Zeit zum Ankommen.

## Akzeptanzkriterien

- [ ] Settings zeigt neue Section "Vorbereitungszeit"
- [ ] Toggle: An/Aus, Standard: An mit 15s
- [ ] Bei "An": Picker mit 5s, 10s, 15s, 20s, 30s, 45s
- [ ] Bei "Aus": Timer startet direkt
- [ ] Einstellung bleibt nach App-Neustart erhalten
- [ ] Start-Gong spielt weiterhin zu Beginn der Meditation, mit und ohne Vorbereitungszeit

## Nicht Teil dieses Tickets

- Eigene Klaenge waehrend der Vorbereitungszeit
```
