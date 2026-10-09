# Stillmoment Ticket-System

Unified Ticket-System fuer iOS und Android mit Cross-Platform Support.
Die Uebersicht aller Tickets steht in [INDEX.md](INDEX.md) — sie wird generiert, nicht von Hand gepflegt.

## Struktur

```
dev-docs/tickets/
├── INDEX.md              ← GENERIERT (make tickets-index), nie von Hand editieren
├── README.md             ← diese Datei: Konventionen, Workflow, Philosophie
├── TEMPLATE-platform.md  ← Vorlage fuer ios-/android-Tickets
├── TEMPLATE-shared.md    ← Vorlage fuer shared-Tickets
├── shared/ ios/ android/ ← nur aktive Tickets (todo / in-progress)
├── archive/
│   └── shared/ ios/ android/   ← abgeschlossene Tickets (done / wontfix)
└── plans/                ← Implementierungsplaene (<ticket-id>[-<platform>].md)
```

Dateiname: `<id>-<slug>.md`, IDs fortlaufend pro Prefix (`shared-NNN`, `ios-NNN`, `android-NNN`).

**Ticket per ID finden:** Glob `dev-docs/tickets/**/<id>-*.md` (deckt aktiv + Archiv ab). Treffer unter `plans/`
ignorieren — Plaene fuer shared-Tickets heissen `<id>-ios.md` / `<id>-android.md` und passen sonst ins Muster.
Den Dateinamen nie raten: Slug und Thema stimmen nicht immer ueberein, und der Ordner haengt vom Status ab.

## Frontmatter

Der Status steht **nur** im Frontmatter. Es gibt keine `**Status**:`-Zeile und keine Plattform-Status-Tabelle im Ticket-Text.

Plattform-Ticket (`ios-NNN`, `android-NNN`):

```yaml
---
id: ios-053
title: Anleitung "So importierst du aus Apple Podcasts"
status: todo
phase: 4-Polish
priority: niedrig        # optional
depends_on: [shared-128] # optional, nur Ticket-IDs
---
```

Shared-Ticket (`shared-NNN`):

```yaml
---
id: shared-026
title: iOS Store Publishing
status:
  ios: done
  android: n/a
phase: 2-Architektur
priority: mittel         # optional
depends_on: []           # optional
---
```

| Feld | Werte |
|------|-------|
| `id` | muss zum Dateinamen-Prefix passen (`<id>-<slug>.md`) |
| `title` | Einzeiler (erscheint so im Index) |
| `status` (Plattform) | `todo` \| `in-progress` \| `done` \| `wontfix` |
| `status` (Shared) | Map mit genau `ios` und `android`; Werte wie oben plus `n/a` (Plattform nicht betroffen) |
| `phase` | `1-Quick Fix` \| `2-Architektur` \| `3-Feature` \| `4-Polish` \| `5-QA` |
| `priority` (optional) | `kritisch` \| `hoch` \| `mittel` \| `niedrig` |
| `depends_on` (optional) | Liste von Ticket-IDs. Freitext-Abhaengigkeiten gehoeren in den Abschnitt `## Hinweise` |

Weitere Kopfzeilen im Text (`**Komplexitaet**`, `**Aufwand**`, `**Plan**`, …) bleiben normaler Ticket-Text.

## Status, Archiv und Index

**Abgeschlossen** heisst:
- Plattform-Ticket: `status` ist `done` oder `wontfix`.
- Shared-Ticket: alle Plattformwerte sind `done`, `wontfix` oder `n/a`, und mindestens einer ist nicht `n/a`.

Abgeschlossene Tickets liegen in `archive/<bereich>/`, aktive im Bereichsordner. Beim Abschliessen wird die Datei
per `git mv` ins Archiv verschoben (Git-Historie bleibt mit `git log --follow` verfolgbar).

Nach jeder Status-Aenderung und jedem neuen Ticket im Repo-Root:

```bash
make tickets-index   # validiert alle Tickets und schreibt INDEX.md neu
make tickets-check   # validiert nur; schlaegt fehl, wenn INDEX.md veraltet ist
```

Bei ungueltigem Frontmatter oder einem Ticket im falschen Ordner bricht `make tickets-index` mit Datei + Problem ab
und laesst INDEX.md unveraendert.

## Phasen

| Phase | Beschreibung |
|-------|--------------|
| 1-Quick Fix | Kritische Bugs, sofort beheben |
| 2-Architektur | Strukturelle Grundlagen |
| 3-Feature | Neue Funktionalitaet |
| 4-Polish | UX-Verbesserungen, Feinschliff |
| 5-QA | Tests und Qualitaetssicherung |

---

## Workflow

Die Ticket-Skills decken den ganzen Ablauf ab:

`/create-ticket` → `/plan-ticket` → `/implement-ticket` → `/review-code` → `/close-ticket`

```bash
# 1. Ticket finden und lesen (aktiv oder Archiv)
ls dev-docs/tickets/**/ios-001-*.md

# 2. Claude Code beauftragen
"Setze Ticket ios-001 um gemaess der Spezifikation"
"Setze den iOS-Subtask von shared-001 um"

# 3. Tests ausfuehren
cd ios && make test-unit
cd android && make test-unit

# 4. Status im Frontmatter setzen, abgeschlossene Tickets ins Archiv verschieben, Index erzeugen
make tickets-index
```

---

## Branch-Konvention

```bash
# Platform-spezifisch
git checkout -b feature/ios-001-headphone-playpause
git checkout -b feature/android-005-guided-meditation-repository

# Cross-Platform (separate Branches pro Plattform)
git checkout -b feature/shared-001-ambient-fade-ios
git checkout -b feature/shared-001-ambient-fade-android
```

## Commit-Konvention

```bash
feat(ios): #ios-001 Play/Pause fuer kabelgebundene Kopfhoerer
fix(android): #android-001 Affirmationen lokalisieren
feat(shared): #shared-001 Ambient Sound Fade (iOS)
feat(shared): #shared-001 Ambient Sound Fade (Android)
```

---

## Dokumentations-Regel

Jedes Ticket muss bei Abschluss folgende Dokumentation aktualisieren:

| Ticket-Typ | CHANGELOG.md | CLAUDE.md | README.md |
|------------|--------------|-----------|-----------|
| Bug Fix | Ja | Nein | Nein |
| Feature | Ja | Bei Architektur | Bei Major |
| Architektur | Ja | Ja | Nein |
| QA | Nein | Nein | Nein |

---

## Templates

- [TEMPLATE-platform.md](TEMPLATE-platform.md) - Vorlage fuer ios-/android-Tickets
- [TEMPLATE-shared.md](TEMPLATE-shared.md) - Vorlage fuer shared-Tickets

---

## Ticket-Philosophie

**Tickets beschreiben das WAS und WARUM, nicht das WIE.**

| Gehoert ins Ticket | Gehoert NICHT ins Ticket |
|--------------------|--------------------------|
| Was soll gemacht werden? | Code-Implementierung |
| Warum ist es wichtig? | Dateilisten (neu/aendern) |
| Akzeptanzkriterien | Architektur-Diagramme |
| Manueller Testfall | Test-Befehle |
| Referenz auf existierenden Code | Zeilennummern |
| Nicht-offensichtliche Hinweise | Offensichtliche Patterns |

**Warum?**
- Claude Code hat Zugriff auf CLAUDE.md (Architektur, Commands, Patterns)
- Claude Code kann bestehenden Code als Referenz lesen
- Claude Code kann selbst bessere Loesungen finden
- Weniger Pflege-Aufwand fuer Tickets

---

## Design-Richtlinien

**Ziel:** Eine einfache, warmherzige Meditations-App, die dem User hilft und sich nicht in den Vordergrund draengt.

### Grundprinzipien

| Prinzip | Bedeutung |
|---------|-----------|
| **Einfach > Feature-reich** | Weniger ist mehr |
| **Ruhe > Information** | Meditations-App, nicht Dashboard |
| **Unaufdringlich** | Hilft, draengt sich nicht auf |
| **Warmherzig** | Freundlich, nicht steril |

### Entscheidungskriterien fuer Features

**Vor jedem Ticket fragen:**
1. Hilft das dem User bei der Meditation? (nicht nur "ist es nuetzlich?")
2. Wuerde das Fehlen den User stoeren?
3. Ist es die einfachste Loesung?

**Red Flags (Ticket ueberdenken):**
- "Android/iOS hat das auch" - Kein guter Grund allein
- "Koennte nuetzlich sein" - Wahrscheinlich nicht noetig
- "Mehr Information fuer den User" - Oft das Gegenteil von hilfreich
- "Feature-Parity" - Nur wenn beide Plattformen davon profitieren

### Plattform-Konsistenz

| Situation | Empfehlung |
|-----------|------------|
| Feature sinnvoll fuer beide | Shared Ticket, identische UX |
| Plattform-Pattern unterschiedlich | Separate Umsetzung, gleiches Ziel |
| Feature nur auf einer Plattform sinnvoll | Nur dort umsetzen |
| Feature auf einer Plattform ueberfluessig | Dort entfernen, nicht portieren |

### Qualitaets-Pflicht

- **Accessibility bleibt Pflicht** - Einfachheit ≠ weniger Accessibility
- **Performance zaehlt** - Schnelle App = unaufdringliche App
