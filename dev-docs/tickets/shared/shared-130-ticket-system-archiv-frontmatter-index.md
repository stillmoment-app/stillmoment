---
id: shared-130
title: Ticket-System mit Archiv, Frontmatter und generiertem Index
status:
  ios: in-progress
  android: in-progress
phase: 2-Architektur
priority: mittel
---

# Ticket shared-130: Ticket-System mit Archiv, Frontmatter und generiertem Index

**Komplexitaet**: Keine App-Aenderung, aber breite Streuung: alle bestehenden Tickets werden migriert, und die Ticket-Skills haengen am heutigen Format. Risiko liegt in vergessenen Pfad-Referenzen und darin, dass Skills nach der Umstellung Tickets nicht mehr finden.

---

## Was

Das Ticket-System unter `dev-docs/tickets/` soll uebersichtlich werden: Abgeschlossene Tickets wandern in ein Archiv, der Status jedes Tickets steht an genau einer maschinenlesbaren Stelle in der Ticket-Datei, und `INDEX.md` wird daraus erzeugt statt von Hand gepflegt.

## Warum

Von rund 260 Tickets sind nur etwa 25 offen oder in Arbeit — sie gehen zwischen den erledigten unter. Der Status steht heute doppelt (Ticket-Datei und `INDEX.md`), wird von Hand synchron gehalten und laeuft dabei auseinander. Die handgepflegte Index-Tabelle ist zu lang, um auf einen Blick zu sehen, was ansteht.

---

## Design-Entscheidungen

### Archiv statt Ordner pro Status

Nur zwei Zustaende werden ueber den Ordner abgebildet: **aktiv** (offen + in Arbeit) und **archiviert** (DONE + WONTFIX). Kein eigener Ordner fuer "in Arbeit" — das waere staendiges Verschieben ohne Mehrwert. Die Plattform-Unterteilung (`shared`, `ios`, `android`) bleibt in beiden Bereichen erhalten.

Ein shared-Ticket wird erst archiviert, wenn **beide** Plattformen DONE oder WONTFIX sind.

### Frontmatter als einzige Status-Quelle

Jedes Ticket bekommt einen maschinenlesbaren Kopf (YAML-Frontmatter) mit mindestens: ID, Titel, Status, Phase, Prioritaet, Abhaengigkeiten. shared-Tickets fuehren den Status pro Plattform. Die heutige `**Status**:`-Zeile und die Plattform-Status-Tabelle im Ticket-Text entfallen — es gibt keine zweite Stelle mehr, die widersprechen kann.

### Index wird erzeugt

`INDEX.md` entsteht per Make-Target aus dem Frontmatter aller Tickets. Aktive Tickets stehen oben, archivierte darunter (oder in einer eigenen Datei). Handaenderungen am Index sind nicht mehr vorgesehen.

---

## Akzeptanzkriterien

### Struktur & Migration
- [x] Unter `dev-docs/tickets/` liegen in `shared/`, `ios/`, `android/` nur noch aktive Tickets; alle DONE- und WONTFIX-Tickets liegen im Archiv
- [x] Jedes bestehende Ticket hat Frontmatter mit ID, Titel, Status, Phase, Prioritaet, Abhaengigkeiten; shared-Tickets mit Status pro Plattform
- [x] Der migrierte Status jedes Tickets stimmt mit dem bisherigen `INDEX.md`-Eintrag ueberein; Widersprueche zwischen alter Datei und altem Index sind vor der Migration aufgeloest und im PR aufgelistet
- [x] Keine Ticket-Datei enthaelt mehr eine `**Status**:`-Zeile oder Plattform-Status-Tabelle
- [x] Die Git-Historie verschobener Tickets bleibt verfolgbar (`git log --follow` zeigt die Commits vor dem Umzug)
- [x] Die Templates erzeugen Tickets im neuen Format

### Generierter Index
- [x] Ein Make-Befehl erzeugt `INDEX.md` vollstaendig aus den Ticket-Dateien
- [x] Im erzeugten Index stehen aktive Tickets vor archivierten; die aktiven passen ohne Scrollen durch die erledigten
- [x] Alle Links im erzeugten Index fuehren zu existierenden Dateien
- [x] Ein Ticket mit fehlendem oder ungueltigem Frontmatter laesst den Befehl mit verstaendlicher Meldung (Dateiname + Problem) fehlschlagen
- [x] Zweimaliges Ausfuehren ohne Ticket-Aenderung erzeugt keinen Diff

### Skills & Doku
- [x] `/create-ticket` legt Tickets im neuen Format an und aktualisiert den Index ueber den Generator
- [x] `/close-ticket` setzt den Status im Frontmatter, verschiebt abgeschlossene Tickets ins Archiv und erzeugt den Index neu
- [x] `/plan-ticket`, `/implement-ticket` und alle weiteren Skills, die Tickets lesen, finden Tickets sowohl im aktiven Bereich als auch im Archiv
- [x] `dev-docs/agents/issue-tracker.md` beschreibt das neue Format, das Archiv und den Generator
- [x] Keine Datei im Repo verweist mehr auf einen Ticket-Pfad, der nach dem Umzug nicht existiert

### Tests
- [x] Automatisierte Tests fuer den Index-Generator: gueltiges Ticket, fehlendes Frontmatter, shared-Ticket mit gemischtem Plattform-Status, Sortierung aktiv vor archiviert

---

## Manueller Test

1. Index-Befehl ausfuehren → `git status` zeigt keine Aenderung an `INDEX.md`
2. `/create-ticket` mit einem Test-Ticket → Datei hat Frontmatter, Ticket erscheint im Index unter "aktiv"
3. Test-Ticket per `/close-ticket` schliessen → Datei liegt im Archiv, Index zeigt es dort, Link funktioniert
4. Ein archiviertes Ticket per ID mit `/plan-ticket` aufrufen → Skill findet es
5. Erwartung: Der Kopf von `INDEX.md` zeigt nur die ~25 aktiven Tickets; Test-Ticket danach wieder entfernen

---

## Hinweise

- Bestehende Konvention "Ticket-Dateinamen nie raten, per Glob nach ID suchen" bleibt — das Suchmuster muss das Archiv einschliessen.
- `dev-docs/tickets/plans/` bleibt unveraendert; Plaene verweisen per Ticket-ID, nicht per Pfad.
- Etwa ein Dutzend Dateien ausserhalb von `dev-docs/tickets/` (Docs, Skills, Plaene) enthalten heute feste Ticket-Pfade.
- Geprueft und verworfen: fertige Tools wie Backlog.md oder Beads — sie wuerden den Umbau aller Ticket-Skills erzwingen (Beads zudem Alpha und kein lesbares Markdown).
- Plattformunabhaengig (Repo-Tooling) — beide Spalten werden gemeinsam geschlossen.
