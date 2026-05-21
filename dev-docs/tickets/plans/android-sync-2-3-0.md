# Android-Sync auf iOS 2.3.0

Erstellt: 2026-05-21
Ziel: Android auf Funktions- und Optik-Stand der iOS-Version 2.3.0 bringen.

---

## Leitprinzipien

- **Endstand statt Historie.** Wo iOS sich zwischendurch zurueckbewegt hat (Vessel → Mond, Atemkreis-Glow → Doppel-Lotus), springt Android direkt zum aktuellen Endstand. Zwischenschritte werden nicht nachgebaut.
- **Drei Themes raus, bevor Kerzenschein-Refinement.** Wenn `shared-093` (ein Theme) nicht zuerst landet, muss jede Farbaenderung dreimal gemacht werden.
- **Typografie vor Theme-Refinement.** `shared-094` erwaehnt explizit, dass `bodyEmphasis`/`micro` ueber das neue Token-System laufen — also Newsreader/Geist zuerst.

---

## Was uebersprungen wird

iOS-Schritte, die durch spaetere Tickets ueberschrieben wurden und auf Android nicht nachgebaut werden:

| iOS-Schritt | Grund fuer Skip | Direkter Endstand fuer Android |
|---|---|---|
| `ios-046` Sanduhr-Vessel | wurde durch Mondphase ersetzt | `shared-095` Mondphase |
| `shared-092` Atemkreis-Glow im Danke-Screen | wurde durch Doppel-Lotus ersetzt | `shared-097` Doppel-Lotus-Mandala |
| Drei Themes (`shared-032` etc. — Android hat sie heute noch) | werden auf ein Theme reduziert | `shared-093` |
| Atemkreis-Player aus `shared-087` (Android hat das schon) | wird nur verfeinert | nur `shared-096` Refinement zusaetzlich |

---

## Phasen

Reihenfolge: **A → B → C**, innerhalb einer Phase wo moeglich parallel.

### Phase A — Fundament

Sequenziell, jeder Schritt entfernt Reibung fuer den naechsten.

| # | Ticket | Quelle iOS | Anmerkung |
|---|---|---|---|
| A1 | `shared-093` Theme-System auf ein Theme reduzieren | iOS [x] | Theme-Picker raus, nur Kerzenschein bleibt |
| A2 | **neu: `shared-099` Typografie Newsreader + Geist** | basiert auf `ios-048` | Newsreader (Serif, Display) + Geist (Sans, UI). Inkl. Token-System `bodyEmphasis`/`micro`. Halation-Bump entfaellt. |
| A3 | `shared-094` Theme-Refinement Kerzenschein 2.0 | iOS [x] | Saturierter Sunrise-Gradient, plastische Buttons, waermere Card-Border in Dark Mode |

### Phase B — Visuals

Parallelisierbar, sobald Phase A steht.

| # | Ticket | Quelle iOS | Anmerkung |
|---|---|---|---|
| B1 | `shared-095` Running-Timer Mondphase | iOS [x] | Vessel-Schritt komplett auslassen, direkt Mond |
| B2 | `shared-096` Player Refinement Kerzenschein 2.0 | iOS [x] | Ruhiger Ring + Perle statt atmender Glow. Pre-Roll ohne Bogen |
| B3 | `shared-097` Danke-Screen Doppel-Lotus | iOS [x] | Atemkreis-Variante `shared-092` wird uebersprungen |
| B4 | **neu: `shared-100` Idle-Ring duenn in Running-Sprache** | basiert auf `ios-045` | Track + Bogen + Punkt, kein Drop-Halo mehr. Punkt waechst beim Drag |

### Phase C — Library

Unabhaengig von A/B, kann zeitlich auch parallel laufen.

| # | Ticket | Quelle iOS | Anmerkung |
|---|---|---|---|
| C1 | **neu: `shared-101` Library-Suche** | basiert auf `ios-041` | Live-Filter, History (max 6), Match-Highlight in Akzentfarbe |
| C2 | **neu: `shared-102` Library-Header mit immer sichtbarem Suchfeld** | basiert auf `ios-051` | Haengt an C1. Such-Pille + Aktion-Pille; Title "Bibliothek" raus |
| C3 | `shared-098` Library-Preview Scrub-Slider | iOS [x] | Slider unterhalb der Row beim Vorhoeren |
| C4 | **neu: `shared-103` Share-Import-Verbesserungen** | basiert auf `ios-042` + `ios-043` + `ios-044` | Drei iOS-Tickets in ein Android-Ticket buendeln: immer als Meditation, Prefill-Service, Edit-Sheet-UI mit X-Button + Pflichtfeldern. Inkl. CamelCase-Split aus `ios-044` |

---

## Neue shared-Tickets

Fuer iOS-only-Tickets, die fuer Android nachgezogen werden, neue shared-Nummern anlegen. iOS-Spalte wird mit `[x]` markiert und Verweis "iOS via ios-NNN" eingetragen. Android-Spalte bleibt `[ ]` bis zur Umsetzung.

| Nummer | Titel | iOS-Quelle |
|---|---|---|
| `shared-099` | Typografie Newsreader + Geist | `ios-048` |
| `shared-100` | Idle-Ring duenn in Running-Sprache | `ios-045` |
| `shared-101` | Library-Suche | `ios-041` |
| `shared-102` | Library-Header mit immer sichtbarem Suchfeld | `ios-051` |
| `shared-103` | Share-Import-Verbesserungen | `ios-042` + `ios-043` + `ios-044` |

---

## Abhaengigkeitsgraph

```
A1 (shared-093: ein Theme)
  └─ A2 (shared-099: Typo)
       └─ A3 (shared-094: Kerzenschein 2.0)
            ├─ B1 (shared-095: Mondphase)
            ├─ B2 (shared-096: Player Refinement)
            ├─ B3 (shared-097: Doppel-Lotus)
            └─ B4 (shared-100: Idle-Ring)

C1 (shared-101: Suche)
  └─ C2 (shared-102: Header)
C3 (shared-098: Scrub-Slider) — unabhaengig
C4 (shared-103: Share-Import) — unabhaengig
```

Phase C ist komplett unabhaengig von A/B. Wenn ein zweiter Strang parallel laufen soll, kann C jederzeit gestartet werden.

---

## Offene Punkte fuer den Plan

- `ios-049` (Schrift-Nachweise OFL) und `ios-050` (Typografie 2.1 A11y) sind iOS-only und noch `[ ]` — diese Arbeit kommt nach 2.3.0 und ist nicht Teil des Sync.
- `shared-088` (Einstimmung entfernen) ist iOS noch `[~]`. Android ist hier schon weiter (`[x]`). Kein Action-Item.
- `ios-039`/`ios-040` (Settings-Store-Cleanup, AudioService Single Instance) sind iOS-interne Architektur-Tickets — Android-Pendants gibt es bereits oder sie sind nicht noetig. Nicht Teil des Sync.
