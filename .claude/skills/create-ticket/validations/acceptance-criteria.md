# Akzeptanzkriterien Validierung

Kompakte Pruefregeln fuer den create-ticket Skill.
Ausfuehrliche Beispiele: `dev-docs/TICKET_GUIDE.md`

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
