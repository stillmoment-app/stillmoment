---
name: close-ticket
description: Schliesst Tickets vollstaendig ab — committet offene Aenderungen, prueft CHANGELOG, setzt den Status im Frontmatter, verschiebt abgeschlossene Tickets ins Archiv, erzeugt den Index neu, merged Branch nach main (--no-ff) und loescht ihn lokal. Aktiviere bei "Schliesse Ticket...", "Close ticket...", oder /close-ticket.
---

# Close Ticket

Ein Ticket wird mit diesem Skill vollstaendig abgeschlossen — Code, Doku, Status und Git in einem Rutsch.

## Kernprinzip

**Ein Ticket ist erst DONE wenn alles drumherum stimmt:**
- Alle Aenderungen committed
- CHANGELOG-Eintrag vorhanden
- Status im Frontmatter auf `done`, abgeschlossenes Ticket in `archive/<bereich>/`, INDEX.md per `make tickets-index` neu erzeugt
- Branch nach main gemerged und lokal geloescht

**Was dieser Skill NICHT tut:**
- Keine inhaltliche Pruefung der Akzeptanzkriterien — das macht `/review-code` vor dem Close.
- Kein `git push` und kein remote-delete des Branches — der User pusht manuell.
- Keine Tests laufen lassen — Annahme: vor dem Close war alles gruen.

## Wann dieser Skill aktiviert wird

- "Schliesse Ticket ios-023"
- "Close ticket android-005"
- "Ticket shared-001 ist fertig"
- `/close-ticket ios-023`

## Konventionen aus dem Repo

Aus Git-History und CHANGELOG-Struktur:
- **Branch-Name:** `feature/<ticket-id>` oder `feature/<ticket-id>-<platform>` (z.B. `feature/ios-042`, `feature/shared-067-ios`)
- **Commit-Message:** `<type>(<scope>): #<ticket-id> <kurzbeschreibung>` (z.B. `feat(ios): #ios-041 Bibliotheks-Suche`)
- **Type:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- **Scope:** `ios`, `android`, `shared`, oder Sub-Bereich
- **CHANGELOG.md:** `[Unreleased]`-Sektion mit Subsektionen `### Added|Changed|Fixed|Removed (iOS)` bzw. `(Android)`. Jeder Eintrag endet mit `(Ticket: <ticket-id>)`.

## Workflow

### Schritt 1: Ticket-Nummer ermitteln

Reihenfolge der Quellen:

1. **Trigger-Text:** Pattern `(ios|android|shared)-(\d+)` (z.B. "Schliesse Ticket **ios-023**" → `ios-023`)
2. **Aktueller Branch-Name als Fallback:** `git rev-parse --abbrev-ref HEAD`, dann Pattern `feature/(ios|android|shared)-(\d+)(-(ios|android))?` matchen. Beispiele:
   - `feature/ios-042` → `ios-042`
   - `feature/shared-067-ios` → `shared-067`, Plattform-Hinweis `ios` (relevant fuer Shared-Tickets-Sonderfall)
   - `feature/shared-075` → `shared-075`
3. **Wenn beides nichts ergibt:** "Welches Ticket soll geschlossen werden? (z.B. ios-023)"

Wenn die ID aus dem Branch abgeleitet wird, einmal sichtbar bestaetigen:
> "Schliesse Ticket {id} (aus Branch `{branch}` abgeleitet)."

Falls die Trigger-ID und die Branch-ID auseinanderlaufen: STOP, fragen welche stimmt — sonst merged man am Ende den falschen Branch.

### Schritt 2: Ticket finden und lesen

Ticket-Dateinamen haben Suffixe und der Ordner haengt vom Status ab — nie raten, immer per Glob suchen (aktiv + Archiv):
- `dev-docs/tickets/**/{ticket-id}-*.md` — Treffer unter `plans/` ignorieren

Lese die Datei und extrahiere:
- Aktueller Status aus dem Frontmatter (`status:`; shared: `status.ios` / `status.android`)
- Titel (fuer Commit-Messages und CHANGELOG)
- Ticket-Typ (Feature / Bug Fix / Refactoring / ...)

**Wenn Status bereits `done` (shared: fuer die zu schliessende Plattform):**
> "Ticket {id} ist bereits abgeschlossen. Pruefe nur noch Git-Zustand und Merge?"
> Bei "ja" weiter ab Schritt 4. Bei "nein" Ende.

### Schritt 3: Branch-Zuordnung pruefen

Ermittle aktuellen Branch: `git rev-parse --abbrev-ref HEAD`

- Wenn Branch `main` → STOP, fragen: "Du bist auf main. Welcher Branch gehoert zu {ticket-id}?"
- Wenn Branch-Name die Ticket-ID enthaelt → OK
- Sonst warnen: "Aktueller Branch ist `{branch}` — gehoert er zu {ticket-id}? (ja/nein)"

### Schritt 4: Offene Aenderungen committen

`git status --porcelain`

**Wenn leer:** weiter zu Schritt 5.

**Wenn nicht leer:**
1. Zeige `git status` + kurzen `git diff --stat`.
2. Schlage Commit-Message vor, Format: `<type>(<scope>): #<ticket-id> <kurzbeschreibung>`
   - `type` aus Ticket-Typ ableiten (Feature → `feat`, Bug Fix → `fix`, Refactoring → `refactor`, sonst `chore`)
   - `scope` aus Plattform (`ios`, `android`, `shared`)
   - Kurzbeschreibung aus Ticket-Titel
3. Frage: "Committen mit dieser Message? (ja / andere Message / abbrechen)"
4. Bei "ja": stage gezielt (keine `git add -A`, lieber konkrete Pfade aus `git status`), commit.
5. Bei "abbrechen": Skill stoppt — User soll selbst committen und Skill erneut starten.

### Schritt 5: CHANGELOG.md pruefen

Lies den `[Unreleased]`-Block aus `CHANGELOG.md`.

Suche nach einer Zeile mit `(Ticket: {ticket-id})`.

**Wenn vorhanden:** OK, weiter zu Schritt 6.

**Wenn nicht vorhanden:**
1. Frage: "Kein CHANGELOG-Eintrag fuer {ticket-id} gefunden. Soll ich einen erstellen?"
2. Bei "ja":
   - Sektion bestimmen: `Added` (neues Feature), `Changed` (Aenderung an Bestehendem), `Fixed` (Bug Fix), `Removed` (Entfernung)
   - Plattform aus Ticket-ID/Branch ableiten (`(iOS)` / `(Android)`)
   - Eintragsformat aus bestehenden Eintraegen spiegeln: `- **Titel** - Beschreibung. (Ticket: {ticket-id})`
   - Beschreibung aus Ticket-Inhalt zusammenfassen (1–3 Saetze, was sich aus User-Sicht aendert)
   - User-Bestaetigung des Entwurfs einholen, dann eintragen
3. Commit: `docs(<scope>): #<ticket-id> CHANGELOG-Eintrag`

### Schritt 6: Status auf DONE setzen

1. **Frontmatter:** `status: todo|in-progress` → `status: done` (shared: nur `status.ios` bzw. `status.android`, siehe Sonderfall Shared-Tickets)
2. **Archivieren, falls jetzt abgeschlossen:** Plattform-Ticket mit `done|wontfix`; Shared-Ticket, wenn alle Plattformwerte in `done|wontfix|n/a` liegen und mindestens einer nicht `n/a` ist.
   `git mv dev-docs/tickets/<bereich>/<datei>.md dev-docs/tickets/archive/<bereich>/<datei>.md`
   Noch nicht abgeschlossen (shared mit offener Plattform) → Datei bleibt liegen.
3. **Index neu erzeugen:** `make tickets-index` im Repo-Root. INDEX.md nie von Hand editieren. Fertig, wenn Exit 0; bei Fehler das gemeldete Problem beheben und erneut ausfuehren.
4. Commit (Ticket-Datei inkl. Verschiebung + INDEX.md): `docs(<ticket-id>): Ticket abschliessen`

### Schritt 7: Merge in main und Branch loeschen

1. `git checkout main`
2. `git merge --no-ff <branch>` — Default-Merge-Message (`Merge branch '<branch>'`) ist ok
3. **Bei Merge-Konflikt:** STOP. Zeige Konflikt-Files, frage User wie weiter (Konflikt manuell loesen, dann erneut). Skill selbst loest keine Konflikte.
4. **Bei erfolgreichem Merge:** `git branch -d <branch>` (kein `-D` — falls da noch was nicht gemerged ist, soll's failen und der User entscheidet)

### Schritt 8: Zusammenfassung

```
Ticket geschlossen: {ticket-id}

Status: done
Datei: dev-docs/tickets/{archive/}{bereich}/{filename}.md
INDEX.md: neu erzeugt
CHANGELOG: {Eintrag vorhanden / neu erstellt}

Git:
- Commits auf {branch}: {N}
- Merged in main (--no-ff)
- Branch lokal geloescht

Noch zu tun (manuell):
- git push origin main
- git push origin --delete {branch}
```

## Sonderfaelle

### WONTFIX

Falls User sagt "als WONTFIX schliessen":
1. Frage nach Begruendung
2. Fuege Begruendung als Notiz ins Ticket ein
3. Status → `wontfix` (statt `done`), dann Schritt 6 ab Punkt 2 (archivieren, Index erzeugen)
4. Kein Merge — Branch je nach User-Wunsch verwerfen oder behalten

### Shared-Tickets

Bei `shared-*`-Tickets:
1. Frage: "Welche Plattform wurde abgeschlossen?"
   - Nur iOS
   - Nur Android
   - Beide
2. Setze nur die entsprechenden Werte unter `status:` (`ios` / `android`); den anderen Wert unveraendert lassen
3. Wenn die andere Plattform noch `todo`/`in-progress` ist → Ticket bleibt aktiv (kein `git mv`), Index zeigt es teilweise offen. Ist der Branch plattform-spezifisch (`feature/shared-082-ios`) → normal mergen; sonst kein Merge zu main fuer die andere Plattform

### Bereits committet, aber CHANGELOG fehlt

Normaler Pfad — Schritt 5 fuegt CHANGELOG nachtraeglich hinzu (eigener `docs:`-Commit). Kein Squash, kein Amend.

## Referenzen

- `dev-docs/tickets/README.md` — Frontmatter-Schema, Archiv-Regel, `make tickets-index`
- `CHANGELOG.md` — `[Unreleased]`-Sektion ist Pflicht-Quelle fuer Release Notes
- `dev-docs/release/RELEASE_GUIDE.md` — was nach dem Close mit `[Unreleased]` passiert
