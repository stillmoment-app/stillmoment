# Retrospektive: Claude Code Patterns
## Analyse von 374 Sessions

---

## Agenda

1. **Was funktioniert gut** (4 Patterns)
2. **Wo es Probleme gibt** (4 Anti-Patterns)
3. **Empfehlungen**

Jeder Punkt mit **echten Beispielen** aus den Logs.

---

## TEIL 1: WAS FUNKTIONIERT GUT

---

## Pattern 1: Ticketbasierter Workflow

**Beobachtung:**
Wenn ein Ticket strukturiert ist, braucht der Agent keine Rückfragen.

**Evidenz aus den Logs:**
- Sessions mit Ticket-Referenz: Ø 52-74 Turns
- Sessions ohne klare Spec: bis zu 235 Turns

---

## Pattern 1: Echtes Beispiel (gut)

**Session:** `f92173b2`

```markdown
User: "Implement the following plan:

# Fix: Guided Meditation Preparation Countdown im Background

## Problem
Der Vorbereitungs-Countdown bei Guided Meditations
stoppt, wenn der Bildschirm gesperrt wird.

## Root Cause
`AudioPlayerService.startSilentBackgroundAudio()`
sucht nach `silent.mp3`, die nicht existiert."
```

---

## Pattern 1: Was passiert dann?

**Agent-Reaktion:**

```
"Ich schaue mir an, wie der Vorbereitungstimer
bei geführten Meditationen implementiert ist."

[Exploration → Code-Analyse → Implementation]
```

**Keine Rückfragen nötig.**
Problem, Root Cause und Kontext sind klar.

---

## Pattern 1: Weiteres Beispiel

**Session:** `ded0f6bd`

```markdown
User: "Implement the following plan:

# Plan: Android Screenshot Test - Settings-Button Timing

## Problem-Analyse
Screenshot `05_SettingsView.png` zeigt manchmal
die Timer-Ansicht statt der Settings-Ansicht.

### Ursache identifiziert
In `ScreengrabScreenshotTests.kt:280-300`:
Thread.sleep Timing-Probleme..."
```

**Dateireferenz + Zeilennummern** = Agent weiß genau wo.

---

## Pattern 1: Was macht ein gutes Ticket aus?

| Element | Warum wichtig |
|---------|---------------|
| **Problem** | Was ist kaputt? |
| **Root Cause** | Warum ist es kaputt? |
| **Datei:Zeile** | Wo genau? |
| **Erwartet vs. Tatsächlich** | Was soll passieren? |

Fehlt eines → Rückfragen nötig.

---

## Pattern 2: Review-Skill Integration

**Beobachtung:**
Der strukturierte Review-Prozess funktioniert gut.

**Echtes Beispiel - Session:** `e60923f2`

```
User: "schau dir ios/ios-030-screenshot-tests-ohne-launch-args.md.
       hast du noch fragen, ergänzungen oder anmerkungen
       vor der umsetzung?"
```

---

## Pattern 2: Agent-Reaktion

```
Agent: "Lass mich die referenzierten Dateien und den
        aktuellen Implementierungsstand ansehen.

        [detaillierte Analyse]

        Gute Analyse! Hier meine Fragen und Anmerkungen:

        ## Fragen
        ### 1. Scope: Reguläre UI-Tests auch umstellen?
        ### 2. Hardcoded vs. konfigurierbar...
        ### 3. Alternative Approaches..."
```

**Strukturierte Rückfragen** statt wildes Raten.

---

## Pattern 2: Tool-Nutzung in Reviews

```
Read   ████████████████████████████████ 64x
Bash   █████████████████ 34x  (Tests)
Edit   ██████████ 19x
Glob   ████████ 16x
```

**Read dominiert** - Verstehen vor Verändern.

---

## Pattern 3: Kurze imperative Befehle

**Diese Ein-Zeiler funktionieren:**

```
"mache erst mal nur eine interaktive analyse mit mir.
 ziel ist die spätere erstellung eines plans"
```

```
"Silent Timer funktioniert auch mit 'Stille'"
```

```
"BackgroundSoundRepository: ist das eine gute lösung?"
```

---

## Pattern 3: Warum sie funktionieren

| Befehl | Impliziter Kontext |
|--------|-------------------|
| `"Silent Timer funktioniert auch mit 'Stille'"` | Agent versteht: Alternative wurde getestet |
| `"BackgroundSoundRepository: ist das eine gute lösung"` | Agent gibt DRY/YAGNI-Abwägung |

**Kontext aus vorheriger Konversation** wird genutzt.

---

## Pattern 3: Echtes Beispiel

**Session:** `9d2c9993`

```
User: "warum erzeugt fastlane screenshot namen,
       die es beim release nicht brauchen kann?"
```

**Agent-Reaktion:**
```
"Das liegt an der `UiAutomatorScreenshotStrategy`.
 Ich sehe das Problem:
 - Screengrab speichert mit Timestamp
 - Fastlane Supply erwartet exakte Namen
 - Lösung: Callback-Strategie verwenden..."
```

Präzise Frage → Präzise Antwort.

---

## Pattern 4: Cross-Platform Shared-Tickets

**Beobachtung:**
Shared-Tickets werden parallel auf iOS und Android umgesetzt.

```
shared-023/
├── ticket.md           # Gemeinsame Spec
├── ios-status.md       # iOS-spezifisch
└── android-status.md   # Android-spezifisch
```

Eine Diskussion, nicht zwei.

---

## TEIL 2: WO ES PROBLEME GIBT

---

## Anti-Pattern 1: Natürlichsprachige Bug-Reports

**Session:** `f92173b2`

```
User: "guided meditations vorbereitungszeit unter ios.
       verhalten: ich starte eine meditation mit 15s
       vorbereitungszeit. drücke auf play, 15s countdown
       startet. ich sperre das handy. dann bleibt der
       vorbereitungstimer stehen. der sollte natürlich
       weiter laufen."
```

---

## Anti-Pattern 1: Was der Agent tun muss

```
Agent: "Der Benutzer beschreibt ein Problem mit der
        iOS-App 'Still Moment'. Das Problem ist:

        1. Er startet eine geführte Meditation mit
           15 Sekunden Vorbereitungszeit
        2. Er drückt auf Play, der 15-Sekunden-
           Countdown startet
        3. Er sperrt das Handy (Bildschirm aus)
        4. Der Vorbereitungstimer bleibt stehen

        Das ist ein typisches Problem mit iOS-Apps,
        wenn sie in den Hintergrund gehen..."
```

**Agent muss erst mal paraphrasieren** um sicherzugehen.

---

## Anti-Pattern 1: Dann kommen Rückfragen

**User muss nachliefern:**

```
User: "nach 15s (bzw.) der eingestellten
       vorbereitungszeit soll das guided mediation
       audio starten, auch bei gesperrtem lock screen.

       der Countdown soll also weiter laufen.

       der silent meditation timer funktioniert wie
       erwartet soweit ich das beobachten kann.

       verstehst du das oder hast du rückfragen?"
```

---

## Anti-Pattern 1: Noch mehr Klärung

**Agent fragt weiter:**

```
Agent: "Ich verstehe die Anforderung.
        Der stille Timer funktioniert, aber der
        Guided-Meditation Timer nicht?

        Zu klären: Verwendet der stille Timer
        eine andere Implementierung für das
        Background-Handling?"
```

**3+ Turns** nur um das Problem zu verstehen.

---

## Anti-Pattern 1: Vergleich

| Natürlichsprachig | Als Ticket |
|-------------------|------------|
| "timer bleibt stehen wenn ich sperre" | Problem: Timer stoppt im Background |
| [Agent paraphrasiert] | Root Cause: AudioPlayer suspended |
| [User bestätigt] | Erwartet: Timer läuft weiter |
| [Agent fragt nach] | Datei: `AudioPlayerService.swift:142` |
| **3-5 Turns** | **0 Rückfragen** |

---

## Anti-Pattern 2: Hohe Iteration bei unklaren Specs

**Session:** `9ad48929` - **54 Turns**

```
User: "wir haben ein problem mit
       testScreenshot02_timerRunning und wie man
       ui elemente findet. erkläre mir schritt
       für schritt zeile für zeile was der test macht"
```

---

## Anti-Pattern 2: Der Dialog geht hin und her

**Turn 1 - Agent erklärt:**
```
"Hier ist die Zeile-für-Zeile Erklärung:
 1. `func testScreenshot02_timerRunning()`
 2. `snapshot(ViewController())`
 3. Thread-Sleep: 5 Sekunden Wartezeit..."
```

**Turn 2 - User korrigiert Richtung:**
```
"der test dauert lang, thread sleep ist böse,
 wir laufen in timeouts. lass uns den test
 schritt für schritt neu aufbauen"
```

---

## Anti-Pattern 2: Iteration geht weiter

**Turn 3:**
```
User: "unser workflow. test schritt für schritt
       erweitern, dazwischen immer mit
       make screenshot-single laufen lassen,
       danach auf die ergebnisse schauen"
```

**Turn 4-54:**
```
[weitere 40+ Turns mit iterativem Debugging]
```

---

## Anti-Pattern 2: Was hätte geholfen?

**Statt natürlichsprachiger Exploration:**

```markdown
# Problem: testScreenshot02_timerRunning ist langsam

## Symptom
- Test dauert >30s
- Timeouts bei UI-Element-Suche

## Ziel
- Thread.sleep eliminieren
- WaitCondition nutzen

## Workflow
1. Test inkrementell aufbauen
2. Nach jedem Schritt: make screenshot-single
3. Validieren
```

---

## Anti-Pattern 3: Reviews ohne klare Erwartung

**Session:** `34387677`

```
User: "schau dir die app an. was würdest du als
       nächstes tun (nicht die refactoring tickets,
       sondern neue features)"
```

---

## Anti-Pattern 3: Agent muss Struktur geben

```
Agent: "Das ist sehr offen. Sollen wir:
        1. Die Codebasis analysieren?
        2. Alte Issues ansehen?
        3. Performance/Stabilität?

        Gib mir mehr Kontext für eine
        sinnvolle Priorisierung."
```

**User-Intent unklar** → Agent muss nachfragen.

---

## Anti-Pattern 3: Das "ok" Problem

Nach einem Review:

```
Agent: "Review abgeschlossen. 5 Findings:
        1. Missing null check
        2. Unused import
        3. ..."

User: "ok"

Agent: ???
```

---

## Anti-Pattern 3: Was meint "ok"?

| "ok" könnte bedeuten | Agent interpretiert |
|---------------------|---------------------|
| "Danke, ich fixe selbst" | Warten |
| "Fix die Issues" | Nichts tun |
| "Zur Kenntnis genommen" | Unklar |
| "Weiter zum nächsten" | ??? |

**Lösung:** Explizit fragen oder sagen:
- `"review und fix"` vs. `"nur review"`

---

## Anti-Pattern 4: Komplexe Bug-Beschreibungen

**Session:** `51863eb1`

```
User: "make screenshots läuft durch in android,
       aber ich sehe 3 mal die zeitauswahl
       im timer und 2x die library view. warum?"
```

---

## Anti-Pattern 4: Was folgt

```
Agent: "Lass mich die Screenshot-Tests untersuchen.

        [Mehrere Fragen zur Navigation,
         Timing, App-Startzustand...]

        Das Problem ist komplexer als erwartet -
        mehrere Faktoren spielen zusammen."
```

**Resultat:** 20+ Turns zum vollständigen Verständnis.

---

## Anti-Pattern 4: Besser als Ticket

```markdown
# Bug: Android Screenshots zeigen falsche Views

## Beobachtung
- `make screenshots` läuft durch
- Ergebnis: 3x Zeitauswahl, 2x Library

## Erwartet
- 1x Zeitauswahl, 1x Library, 1x Timer, ...

## Verdacht
Navigation-Timing? App-State nach Test?
```

**Strukturierte Beobachtung** spart 15+ Turns.

---

## TEIL 3: METRIKEN

---

## Quantitative Analyse

| Kategorie | Anzahl | Muster |
|-----------|--------|--------|
| **Gute Tickets** | 10 | "Implement plan:" + Kontext |
| **Natürlichsprache** | 32 | Mehrdeutig, Rückfragen |
| **Review-Anfragen** | 33 | "Schau dir X an" |
| **Kurze Befehle** | 99 | 40-120 Zeichen |
| **Bug-Beschreibungen** | 3 | Symptom + Vergleich |

---

## Der Kostenfaktor

| Szenario | Turns | Aufwand |
|----------|-------|---------|
| Klares Ticket | 52 | Baseline |
| Unklare natürliche Sprache | 235 | **4.5x mehr** |

**Ticket schreiben:** ~10 min Investment
**ROI:** 60+ min gespart

---

## User:Assistant Ratio

**Ideal:** ~1:1 (User sagt was, Agent macht)

**Realität in problematischen Sessions:**
- Session `01f7d7cb`: 79 User : 156 Agent
- **Ratio: 1:2** (viel Klärung, wenig Fortschritt)

**In guten Sessions:**
- Ratio näher an 1:1
- Weniger Rückfragen

---

## TEIL 4: EMPFEHLUNGEN

---

## Empfehlung 1: Ticket-First

**Regel:**
Keine Implementation ohne strukturiertes Ticket.

**Mindest-Struktur:**
```markdown
# Problem
[Was ist kaputt?]

# Root Cause (wenn bekannt)
[Warum?]

# Erwartet
[Was soll passieren?]
```

---

## Empfehlung 2: Bug → Ticket Eskalation

**Wenn natürlichsprachig:**

```
User: "der timer spinnt manchmal"

Agent: "Ich erstelle ein Bug-Ticket.
        Kannst du mir sagen:
        1. Schritte zur Reproduktion?
        2. Was erwartest du?
        3. Was passiert stattdessen?"
```

Strukturiert das Problem **sofort**.

---

## Empfehlung 3: Explizite Review-Expectations

**Etablierte Patterns:**

| Befehl | Bedeutung |
|--------|-----------|
| `"review shared-023"` | Nur Findings auflisten |
| `"review und fix shared-023"` | Findings + Implementation |
| `"review, dann fragen"` | Findings + Diskussion |

---

## Empfehlung 4: Mehr Task-Tracking

**Bei komplexen Tasks explizit tracken:**

```
Agent: "Das sind mehrere Schritte. Ich tracke:

        [ ] Bestehenden Code analysieren
        [ ] ViewModels anpassen
        [ ] UI aktualisieren
        [ ] Tests schreiben"
```

Hilft Agent **und** User den Überblick zu behalten.

---

## Empfehlung 5: Kontext-Shortcuts

**Funktionierende Kurzformen:**

```
"Silent Timer funktioniert auch mit 'Stille'"
→ Agent versteht: Alternative getestet

"BackgroundSoundRepository: gute Lösung?"
→ Agent gibt Trade-off Analyse
```

**Voraussetzung:** Kontext aus vorherigen Turns klar.

---

## Zusammenfassung

| Was funktioniert | Was verbessern |
|------------------|----------------|
| Strukturierte Tickets | Bug-Reports → Tickets |
| "Implement plan:" Pattern | Natürlichsprache reduzieren |
| Kurze Befehle mit Kontext | Explizite Review-Erwartungen |
| Cross-Platform Shared-Tickets | Mehr Task-Tracking |

---

## Metriken zum Tracken

1. **Turns pro Session** (Ziel: <80)
2. **User:Assistant Ratio** (Ziel: >0.5)
3. **Tickets mit Root Cause** (Ziel: 100%)
4. **Reviews mit explizitem Follow-up** (Ziel: 100%)

---

## Nächste Schritte

- [ ] Ticket-Template mit Mindest-Feldern definieren
- [ ] Bug-Report → Ticket Workflow etablieren
- [ ] Review-Patterns dokumentieren
- [ ] Session-Metriken regelmäßig prüfen

---

## Datenbasis

- **374** Session-Logs analysiert
- **25** Sessions detailliert untersucht
- **~515** Conversation Turns ausgewertet
- **Zeitraum:** Januar 2026

---

## Fragen?
