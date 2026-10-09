---
name: create-ticket
description: Erstellt neue Tickets mit konsistenter Nummerierung, Frontmatter aus dem Template, Philosophie-Validierung und neu generiertem Index. Aktiviere bei "Erstelle Ticket...", "Neues iOS-Ticket...", oder /create-ticket.
---

# Create Ticket

Interaktive Ticket-Erstellung mit automatischer Nummerierung und Qualitaetspruefung.

## Kernprinzip

**Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.** Ein Ticket sagt WAS sich fuer den Nutzer aendert und WARUM — in den Begriffen des Glossars, mit Kriterien, die man ohne Code pruefen kann. Den Weg dorthin findet `/plan-ticket` kurz vor der Umsetzung, mit frischem Blick auf den aktuellen Code.

Der Leser ist ein Coding-Agent mit leerem Kontext. Alles, was er wissen muss und nicht selbst herleiten kann, steht im Ticket: Anlass, beobachtbares Ziel, Grenzen, getroffene Entscheidungen.

## Wann dieser Skill aktiviert wird

- "Erstelle Ticket fuer Timer Background Audio"
- "Neues iOS-Ticket: Sound stoppt bei App-Wechsel"
- "Create ticket for..."
- `/create-ticket`

## Workflow

### Schritt 1: Beschreibung erfassen und Luecken erfragen

Falls keine Beschreibung im Trigger steht, frage:
> "Was soll das Ticket beschreiben?"

Pruefe dann, ob die Beschreibung (plus Gespraechskontext) diese vier Fragen beantwortet:

- **Anlass:** Warum jetzt? Welches Problem hat wer?
- **Fertig:** Woran erkennt man von aussen, dass es funktioniert?
- **Abgrenzung:** Gibt es etwas Naheliegendes, das bewusst nicht dazugehoert?
- **Bei Bugs:** Was passiert (Beobachtet), was sollte passieren (Erwartet), unter welchen Umstaenden?

Was fehlt, fragst du in **einer** gebuendelten Runde (AskUserQuestion). Was die Beschreibung beantwortet, fragst du nicht. Fehlt nichts, geh direkt weiter.

Fertig, wenn jede der vier Fragen aus Worten des Users beantwortet ist — nicht aus deinen Annahmen. Abgrenzung darf leer bleiben, wenn der User keine nennt.

### Schritt 2: Code-Recherche per Subagent (bei Bedarf)

Hilft ein Blick in den Code (Stimmt die Beschreibung? Gibt es den Fall schon? Welches bestehende Verhalten koennte brechen?), schick einen `Explore`-Subagenten. So bleibt der Code aus deinem Kontext und damit aus dem Ticket.

Briefing an den Subagenten: Beschreibung des Users und Antworten aus Schritt 1, dann dieser Auftrag:
> Antworte in fachlicher Sprache, mit Begriffen aus `dev-docs/reference/glossary.md`. Liefere nur: (a) Rueckfragen an den User, (b) Stolperfallen — vor allem bestehendes Verhalten, das die Aenderung gefaehrden koennte, (c) ob es den Fall schon ganz oder teilweise gibt. Ohne Dateipfade, Klassen-, Methoden- oder Variablennamen.

Rueckfragen aus der Recherche stellst du dem User in einer zweiten gebuendelten Runde. Ins Ticket kommt nur, was der User beantwortet hat; bleibt eine Frage offen, nennst du sie dem User und laesst sie aus dem Ticket. Gefaehrdetes Verhalten, das ein Nutzer bemerken wuerde, wird in Schritt 5 zu einem Erhalt-Kriterium.

### Schritt 3: Plattform, Prioritaet und Phase ableiten

Versuche alles aus dem Kontext abzuleiten:
- **Plattform:** iOS-spezifische Begriffe (SwiftUI, AudioSession) → iOS. Android-spezifisch → Android. Unklar oder beide → fragen.
- **Prioritaet** richtet sich nach der Wirkung fuer Nutzer, nicht nach dem Aufwand: Bug mit Datenverlust/Crash → `kritisch`. Feature defekt → `hoch`. Neues Feature → `mittel`. Kosmetik → `niedrig`. Unklar → fragen.
- **Phase:** `1-Quick Fix` | `2-Architektur` | `3-Feature` | `4-Polish` | `5-QA` (Bedeutung: `dev-docs/tickets/README.md`).

Nur bei Ambiguitaet mit AskUserQuestion nachfragen — moeglichst in derselben Runde wie Schritt 1.

### Schritt 4: Naechste Nummer ermitteln

1. Dateinamen aktiver **und** archivierter Tickets globben:
   - iOS: `dev-docs/tickets/**/ios-*.md`
   - Android: `dev-docs/tickets/**/android-*.md`
   - Shared: `dev-docs/tickets/**/shared-*.md`
2. Hoechste Nummer aus den Dateinamen nehmen (Pattern `<platform>-(\d+)`), Treffer unter `plans/` ignorieren
3. Inkrementiere um 1 (dreistellig, z.B. `ios-057`)

### Schritt 5: Entwurf

Lade das passende Template und fuelle es nur mit dem, was aus Beschreibung, Antworten und Recherche stammt:
- Platform: `dev-docs/tickets/TEMPLATE-platform.md`
- Shared: `dev-docs/tickets/TEMPLATE-shared.md`

**Was / Warum:** Was aendert sich fuer den Nutzer, und welches Problem loest es. Ein **Bug** ist jedes Ticket, bei dem bestehendes Verhalten vom gewollten abweicht — unabhaengig von der Phase. Bei Bugs steht unter `## Was` die Struktur:

```markdown
**Beobachtet:** {Was passiert}
**Erwartet:** {Was passieren sollte}
**Umstaende:** {Wann/wo tritt es auf, seit wann}
```

`## Manueller Test` beschreibt bei Bugs die Schritte, mit denen sich der Fehler nachstellen laesst, und endet mit dem erwarteten Verhalten.

**Akzeptanzkriterien:** beobachtbare Ergebnisse, keine Taetigkeiten. Regeln und Beispiele: `validations/acceptance-criteria.md`. Gefaehrdet die Aenderung bestehendes Verhalten, das ein Nutzer bemerken wuerde (aus Recherche oder Gespraech), schreib ein **Erhalt-Kriterium** ("Gongs spielen weiterhin bei gesperrtem Bildschirm").

**Nicht Teil dieses Tickets:** nur fuellen, wenn Schritt 1 eine Abgrenzung ergeben hat; sonst Abschnitt entfernen.

**Hinweise:** nur Rahmenbedingungen und getroffene Entscheidungen mit Begruendung (`validations/philosophy.md`, Abschnitt "Was im Ticket bleibt"). Leer → Abschnitt entfernen.

**Frontmatter** (Schema: `dev-docs/tickets/README.md`), Template-Kommentare entfernen:
- `id`: `{platform}-{NNN}`, identisch mit dem Dateinamen-Prefix
- `title`: Einzeiler, erscheint so im Index. Immer in doppelte Anfuehrungszeichen setzen (`title: "..."`), sonst brechen `:` und `#` das YAML bzw. kuerzen den Titel still; `"` im Titel als `\"` schreiben
- `status`: Plattform-Ticket `todo`; Shared-Ticket `ios: todo` / `android: todo` (nicht betroffene Plattform: `n/a`)
- `phase`, `priority` aus Ableitung/Abfrage
- `depends_on`: Ticket-IDs oder `[]`; Freitext-Abhaengigkeiten nach `## Hinweise`

### Schritt 6: Pruefen

Geh den fertigen Entwurf durch — **jede Zeile, alle Abschnitte**, auch Hinweise und Manueller Test:

1. **Problem statt Loesung:** die vier Fragen aus `validations/philosophy.md`.
2. **Akzeptanzkriterien:** Pflicht-Pruefungen und Warnungen aus `validations/acceptance-criteria.md`.
3. **Nur bei Phase `3-Feature` — Produktphilosophie:** die Entscheidungskriterien und Red Flags aus `dev-docs/tickets/README.md` (Abschnitt "Design-Richtlinien"). Bei Treffer: Hinweis zeigen, nicht blockieren.

Fertig, wenn jede Zeile die vier Fragen besteht und keine Pflicht-Pruefung fehlschlaegt. Was du selbst umformulieren kannst (Code-Begriff → Glossar-Begriff, Taetigkeit → Ergebnis), formulierst du um. Was eine Entscheidung des Users braucht (Warnung zur Produktphilosophie, gestrichener Inhalt, den der User ausdruecklich genannt hat), zeigst du mit Vorschlag und fragst: "Soll ich das Ticket so erstellen?"

### Schritt 7: Ticket schreiben und Index erzeugen

1. Datei schreiben: `dev-docs/tickets/{platform}/{platform}-{NNN}-{slug}.md` (neue Tickets sind aktiv, nie im Archiv). Slug: Kebab-case aus Titel (max 40 Zeichen).
2. `make tickets-index` im Repo-Root ausfuehren. INDEX.md nie von Hand editieren.

Fertig, wenn der Befehl mit Exit 0 endet. Bei Fehler: gemeldetes Problem im Frontmatter der neuen Datei beheben, erneut ausfuehren.

### Schritt 8: Zusammenfassung

Zeige dem User:
```
Ticket erstellt: {platform}-{NNN}

Datei: dev-docs/tickets/{platform}/{filename}.md
Prioritaet: {prioritaet}
INDEX.md: neu erzeugt

Naechste Schritte: `/plan-ticket {platform}-{NNN}` oder `/implement-ticket {platform}-{NNN}`
```

Hat der Subagent eine Stolperfalle gefunden, nenn sie in ein bis zwei Saetzen darunter.

## Beispiel

**Input:**
> "Erstelle Ticket: Wenn User die App wechselt, stoppt der Timer-Sound"

**Rueckfrage-Runde** (Umstaende fehlen): "Bei welchem Sound — Gong, Hintergrundklang oder beidem? Und auch bei gesperrtem Bildschirm?"

**Output:**
```
Ticket erstellt: ios-023

Datei: dev-docs/tickets/ios/ios-023-app-switch-sound-stop.md
Prioritaet: hoch
INDEX.md: neu erzeugt

Naechste Schritte: `/plan-ticket ios-023` oder `/implement-ticket ios-023`
```

## Referenzen

- `dev-docs/tickets/README.md` - Frontmatter-Schema, Phasen, Definition of Done, Design-Richtlinien
- `dev-docs/tickets/TEMPLATE-platform.md` - Platform-Template
- `dev-docs/tickets/TEMPLATE-shared.md` - Shared-Template
- `dev-docs/reference/glossary.md` - Fachbegriffe fuer Ticket-Text
- `validations/philosophy.md` - Problem statt Loesung: vier Fragen pro Zeile
- `validations/acceptance-criteria.md` - Akzeptanzkriterien: beobachtbar, konkret, pruefbar
