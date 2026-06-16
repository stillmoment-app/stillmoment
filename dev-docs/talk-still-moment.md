# Talk: Wie ich „Still Moment" gebaut habe

> Eine Lernreise: Software mit agentic coding bauen · Produkte entwickeln · in den App-Ökosystemen von Apple & Google ankommen.
>
> Format: ~25 Min + Q&A · Publikum: gemischt (Tech-affin, aber kein Tiefdive nötig)
> Datenbasis: Git-History (1370 Commits, 26.10.2025 → 14.06.2026, 30 Release-Tags)

---

## Talk-Beschreibung

**1370 Commits später: Learnings aus der Produktentwicklung mit Vibe Coding**

Wie weit kommt man bei der App-Entwicklung mit Vibe Coding

- ohne den Code zu lesen
- ohne Wissen über die Programmiersprache
- ohne Wissen über UI-Entwicklungspatterns

Und was muss man stattdessen tun und wissen?

---

## Kernbotschaft (ein Satz)

> „In acht Monaten habe ich aus einem Wochenend-Timer zwei live ausgelieferte Apps gemacht — und dabei drei Dinge gelernt, die ich vorher nicht konnte: wie man mit KI-Agenten Software baut, wie man ein Produkt formt statt nur Features zu stapeln, und wie die App-Stores von Apple und Google wirklich ticken."

Roter Faden über den ganzen Talk: **Die App ist nicht das Ergebnis. Das Gelernte ist das Ergebnis.**

---

## Aufbau (Folienblöcke)

### 0. Hook (1 Folie, 1 Min)
- Screenshot der fertigen App neben dem allerersten Commit „Initial Commit".
- „Dazwischen liegen 1370 Commits und drei Dinge, die ich lernen musste."
- Optional: Live-Zahl — Initial Commit → App Store in **32 Tagen**.

### 1. Was ist Still Moment? (1–2 Folien, 2 Min)
- Meditations-App: eigene MP3s als Bibliothek (Kernfeature) + stiller Timer (Add-on).
- Die Haltung zuerst: **kein Tracking, keine Server, keine Werbung, kein Abo.** „Die App soll sich wie eine Pause anfühlen, nicht wie eine weitere Benachrichtigung."
- Leitfrage des Projekts: *„Würde ein Mönch zustimmen?"* — das wird später wichtig (Subtraktion).

---

## Faden 1 — Software bauen mit agentic coding

### 2. Vom Prompt zum Produkt (3 Min)
- Start solo, iOS, SwiftUI. Aber von Anfang an mit Architektur-Disziplin: Clean Architecture + MVVM, Domain-Layer ohne Framework-Imports.
- **Der eigentliche Hebel: nicht „KI schreibt Code", sondern „ich baue mir ein System, in dem die KI zuverlässig arbeitet."**

### 3. Das Skill-Ökosystem entsteht (3 Min)
- Aus Ad-hoc-Prompts werden wiederverwendbare **Skills**: `create-ticket`, `plan-ticket`, `implement-ticket`, `close-ticket`, `review-code`, `review-view`, `create-ui-test`.
- Ein Memory-System, das über Sessions hinweg lernt (konkrete Beispiele aus `MEMORY.md`: SwiftUI-Theming-Fallstricke, Lock-Screen-Audio-Bugs).
- `CLAUDE.md` als „Verfassung" — sogar bewusst um 91 % gekürzt für Effizienz.
- **Lektion:** Kontext-Engineering schlägt Prompt-Tricks.

### 3b. Projektmanagement wird zur Kerndisziplin (3 Min) ← *unterschätzte Lektion*
- **Überraschung:** Beim agentic coding ist Projektmanagement nicht Beiwerk, sondern die eigentliche Arbeit. Der Agent schreibt den Code — die Führung muss von mir kommen.
- **Eine Quelle der Wahrheit, agenten-lesbar:** Tickets, Glossar, Architektur-Doku, Konzepte — alles an *einer* Stelle (`dev-docs/`), in Markdown, so strukturiert, dass der Agent es zuverlässig findet und versteht. Verstreutes Wissen = der Agent rät.
- **Ubiquitous Language wird plötzlich kritisch:** Was bei Solo-Arbeit „im Kopf" reicht, muss mit dem Agenten *explizit und einheitlich benannt* sein. Gleiche Begriffe auf iOS und Android (`dev-docs/reference/glossary.md`). Misnamed concepts → Bugs. Die DDD-Idee der „allgegenwärtigen Sprache" wird vom Lehrbuch-Konzept zur täglichen Notwendigkeit.
- **Aufräumen kostet — und lohnt:** Refactorings, Konsolidierung von Doku und Konzepten, Glossar-Pflege sind zeitraubend und unspektakulär, aber genau sie halten den Agenten produktiv. Vernachlässigte Doku verlangsamt jede künftige Session.
- **Lektion:** Der Mensch wird vom Coder zum Redakteur/Projektleiter. Die Qualität der *Dokumentation und Sprache* bestimmt die Qualität des KI-Outputs.

### 4. Der ehrliche Fehlschlag (2–3 Min) ← *wichtigster Talk-Moment*
- Feb 2026: vollautonomer **Two-Agent-Workflow** (`make implement`), Live-Agent-Stream, eigene „LEARN-Phase". Es funktionierte… so halb.
- März 2026: **„remove autonomous ticket pipeline"** — bewusst zurückgebaut auf die schlankere, von Hand orchestrierte Skill-Pipeline.
- **Lektion:** Mehr Autonomie ≠ besser. Der Mensch als Orchestrator + enge, prüfbare Schritte schlugen das „macht alles allein"-Experiment.

---

## Faden 2 — Ein Produkt entwickeln (nicht nur Features)

### 5. Features wachsen — im Rahmen (2 Min)
- Timer → Guided Meditations → konfigurierbare Gongs/Vorbereitungszeit → Themes → Bibliotheks-Suche → Waveform-Trim-Editor pro Meditation.
- Aber immer entlang einer Priorität: **Bibliothek zuerst, Timer als Add-on.** Das prägt Tab-Reihenfolge, Onboarding, Marketing.

### 6. Subtraktion als Designprinzip (2 Min) ← *Kontrast-Moment*
- Das „Einstimmung/Attunement"-Feature wurde **komplett wieder entfernt** (shared-088).
- „Less is more" nicht als Spruch, sondern als Commit.
- **Lektion:** Produktreife heißt auch Nein sagen — zu eigenen Features.

### 7. Design bekommt eine Sprache (2–3 Min)
- Reaktives Theme-System (Customizable Color Themes), eigenes **Typografie-System 2.1** (Newsreader Serif + Geist Sans, 10 Tokens, Dynamic Type).
- Visuelle Identität: „Kerzenschein 2.0", Mondphasen-Timer, Atemkreis-Player, Danke-Screen der App-Termination übersteht.
- Accessibility ernst genommen: VoiceOver/TalkBack-Audits, Coverage-Gates ≥ 80 %.
- **Lektion:** Der Unterschied zwischen „App" und „Produkt" liegt in den letzten 20 % — Theming, Typografie, Edge-Cases.

---

## Faden 3 — Die App-Ökosysteme von Apple & Google

### 8. Der Cross-Platform-Sprung (2–3 Min)
- 15.12.2025: Android (Kotlin/Compose) kommt dazu — und holt in ~5 Wochen zur Parität auf, was iOS in Monaten aufbaute.
- Das Geheimnis: **`#shared-xxx`-Tickets** erzwingen identisches Verhalten auf beiden Plattformen; `#ios-xxx` / `#android-xxx` für Plattform-Spezifika.
- Reale Reibung: Screenshot-Alignment, Android-API-36-Locale-Fix, iOS-16-Support, plattform-getrennte Versionierung (`ios-v` / `android-v`).

### 9. Release-Automatisierung & Store-Realität (2–3 Min)
- Von „interaktivem Screenshot-Tool" → vollautomatische Screenshot-Generierung → **Fastlane deliver (App Store) + supply (Play Store)**.
- CI ab Tag 14, getrennte Unit/UI-Test-Schemes, agent-optimierter Test-Runner.
- Store-Pflichten gelernt: App-Store-Compliance, Datenschutz, Impressum, bilinguale Store-Texte (DE/EN), Closed Beta → Public.
- **Lektion:** Die Code-Arbeit ist die Hälfte. Die andere Hälfte ist die Maschinerie drumherum.

---

## Randnotiz — Marketing & Userbasis (1–2 Min)

- Kein Performance-Marketing, kein Budget: **Marketing über persönliches Anschreiben.**
- Userbasis bewusst klein — aber das **Feedback ist großartig** und direkt.
- Passt zur Produktphilosophie: kein Wachstum um jeden Preis. Qualität der Beziehung > Quantität der Installs.
- *Mögliche Pointe:* „Ich kenne meine Nutzer mit Namen. Das ist kein Bug, das ist das Feature."

---

## Schluss — Die drei Mitnahmen (2 Min)

1. **Agentic Coding:** Baue das System, nicht nur den Code — eine agenten-lesbare Quelle der Wahrheit und eine einheitliche Sprache schlagen jeden Prompt-Trick. Du wirst vom Coder zum Projektleiter. Und trau dich, ein zu autonomes Setup wieder zurückzubauen.
2. **Produkt:** Reife zeigt sich im Weglassen und in den letzten 20 %.
3. **Ökosysteme:** Der Store-Prozess ist ein eigenes Handwerk — automatisiere ihn früh.

Abschlussbild: dieselbe App wie im Hook, daneben „Würde ein Mönch zustimmen?" — Antwort: ja.

---

## Anhang — Belegbare Zahlen & Daten (für Q&A / Faktencheck)

| Fakt | Wert |
|---|---|
| Entwicklungszeitraum | 26.10.2025 – 14.06.2026 (~8 Monate) |
| Commits gesamt | 1370 |
| Release-Tags | 30 (`v1.0` → `v2.3.0`) |
| iOS App-Store-Launch | 27.11.2025 (v1.0), ~32 Tage nach Initial Commit |
| Android-Start | 15.12.2025 (Timer-MVP), erstes Release v1.4.0 (Closed Beta) 26.12.2025 |
| Umbenennung | „MediTimer" → „Still Moment" am 08.11.2025 |
| Commit-Peaks | Dez 2025 (221), Feb 2026 (412), Mai 2026 (315) |
| Autonomer Agent-Workflow | eingeführt 07.02.2026, entfernt 13.03.2026 |
| Coverage-Gate | ≥ 80 % (CI bricht darunter ab) |

### Markante Commits zum Zitieren
- `2025-10-26 Initial Commit`
- `2025-11-08 refactor: Rename app from MediTimer to Still Moment`
- `2025-11-27 Release v1.0 - App Store Launch`
- `2025-12-15 Add Android app (Kotlin/Compose) - Timer MVP complete`
- `2026-02-07 feat: Autonomous ticket implementation with two-agent workflow`
- `2026-03-13 chore: remove autonomous ticket pipeline (make implement)`
- `2026-05-04 feat(ios): #shared-088 Einstimmung-Feature komplett entfernen`




wichtig: dokumente mit hohem blast radius lesen, straffen und warten
