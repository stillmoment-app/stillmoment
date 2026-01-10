# Akzeptanzkriterien Validierung

Pruefregeln und Beispiele fuer gute Akzeptanzkriterien.

## Eigenschaften guter Kriterien

| Eigenschaft | Beispiel |
|-------------|----------|
| **Beobachtbar** | "Settings zeigt neue Section 'Vorbereitungszeit'" |
| **Messbar** | "Picker zeigt Optionen: 5s, 10s, 15s, 20s, 30s" |
| **Testbar** | "Bei Toggle 'Aus' startet Timer sofort" |
| **User-zentriert** | "Einstellung bleibt nach App-Neustart erhalten" |

## Schlechte vs. gute Kriterien

| Schlecht | Besser |
|----------|--------|
| "Funktioniert richtig" | "Timer zaehlt von 10:00 auf 0:00" |
| "Verwendet DataStore" | "Einstellung wird persistent gespeichert" |
| "Performance verbessert" | "Liste laedt in unter 500ms" |
| "Wie erwartet" | "Sound pausiert wenn andere Audio spielt" |

---

## Pflicht-Pruefungen (blockieren Ticket-Erstellung)

### 1. Kriterien vorhanden
- Sektion "Akzeptanzkriterien" existiert
- Mindestens 2 echte Kriterien

### 2. Platzhalter erkennen
- `Kriterium 1`, `Kriterium 2`, etc.
- `{...}` Template-Platzhalter

### 3. Test-Kriterien vorhanden
- Mindestens ein Test-Kriterium bei Feature-Tickets
- **Ausnahme:** Reine UI-Anpassungen (Phase 4-Polish)

---

## Qualitaets-Warnungen (User entscheidet)

### 4. Vage Formulierungen
Warne bei: `funktioniert richtig`, `wie erwartet`, `ist schnell`, `sieht gut aus`

### 5. Implementierungs-Details
Warne bei: `Verwendet X`, `Refactored zu`, `Ruft API auf`

### 6. CHANGELOG fehlt
Warne bei Feature-Tickets mit user-sichtbaren Aenderungen

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

### Feature
- [ ] Settings zeigt neue Section "Vorbereitungszeit"
- [ ] Toggle: An/Aus
- [ ] Bei "An": Picker mit 5s, 10s, 15s, 20s, 30s, 45s
- [ ] Bei "Aus": Timer startet direkt
- [ ] Lokalisiert (DE + EN)

### Tests
- [ ] Unit Tests fuer Persistence und Default-Werte

### Dokumentation
- [ ] GLOSSARY.md (bei neuen Begriffen)
```
