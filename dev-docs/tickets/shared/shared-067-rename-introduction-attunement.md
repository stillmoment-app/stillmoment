# Ticket shared-067: Code-Rename Introduction → Attunement

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~3 | Android ~3
**Phase**: 4-Polish

---

## Was

Alle Code-Identifier (Typen, Properties, Methoden, Enum-Cases, Dateinamen, Lokalisierungs-Keys) von "Introduction" auf "Attunement" und von "Einleitung" auf "Einstimmung" umbenennen. Der Domain-Begriff wurde bereits in der Dokumentation umbenannt (Glossar, Audio-System, DDD, Test Plan) — jetzt muss der Code nachziehen.

## Warum

Code und Dokumentation verwenden unterschiedliche Begriffe fuer dasselbe Konzept. "Attunement" / "Einstimmung" transportiert die meditative Absicht besser als das generische "Introduction" / "Einleitung". Konsistente Terminologie zwischen Code und Doku verhindert Verwirrung bei der Weiterentwicklung.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Rename (beide Plattformen)

#### Typen und Dateien
- [ ] Domain-Model heisst `Attunement` (vorher `Introduction`)
- [ ] Dateinamen enthalten `Attunement` statt `Introduction`

#### Properties und Variablen
- [ ] `introductionId` → `attunementId` in Settings, Timer, DisplayState
- [ ] Audio-Player-Properties verwenden `attunement` statt `introduction`
- [ ] Publisher/Flow-Properties verwenden `attunement` statt `introduction`

#### Methoden
- [ ] `playIntroduction` → `playAttunement`
- [ ] `stopIntroduction` → `stopAttunement`
- [ ] `endIntroduction` → `endAttunement`
- [ ] Alle weiteren Methoden mit `introduction` im Namen

#### Enum-Cases und State Machine
- [ ] `TimerState.introduction` → `TimerState.attunement`
- [ ] `TimerAction.introductionFinished` → `TimerAction.attunementFinished`
- [ ] `TimerEffect.playIntroduction` → `TimerEffect.playAttunement`
- [ ] `TimerEffect.stopIntroduction` → `TimerEffect.stopAttunement`
- [ ] `TimerEffect.endIntroductionPhase` → `TimerEffect.endAttunementPhase`

#### Lokalisierung
- [ ] Lokalisierungs-Keys verwenden `attunement` statt `introduction`
- [ ] Deutsche UI-Labels zeigen "Einstimmung" statt "Einleitung"
- [ ] Englische UI-Labels zeigen "Attunement" statt "Introduction"
- [ ] Accessibility-Labels und Hints aktualisiert

#### Persistenz
- [ ] UserDefaults-Migration: gespeicherter `introductionId`-Key wird beim ersten Start migriert
- [ ] Kein Datenverlust der Benutzer-Einstellung durch Rename

#### Allgemein
- [ ] Keine funktionale Aenderung — rein mechanischer Rename
- [ ] App baut und laeuft auf beiden Plattformen
- [ ] Alle bestehenden Tests passen (angepasst auf neue Namen)

### Tests
- [ ] Bestehende Unit Tests iOS angepasst und gruen
- [ ] Bestehende Unit Tests Android angepasst und gruen

### Dokumentation
- [ ] Glossar "Code-Rename pending"-Hinweise entfernen
- [ ] Audio-System-Doku Code-Referenzen aktualisieren

---

## Manueller Test

1. App mit bestehender Einstimmungs-Einstellung oeffnen (vor Migration)
2. Erwartung: Einstimmung ist weiterhin konfiguriert (Migration hat gegriffen)
3. Timer-Einstellungen → Einstimmungs-Picker oeffnen
4. Einstimmung "Atemuebung" auswaehlen → Timer starten
5. Erwartung: Start-Gong → Einstimmung spielt → stille Phase beginnt (unveraendertes Verhalten)

---

## Hinweise

- Rein mechanischer Rename — keine Logik-Aenderungen. IDE-Refactoring-Tools nutzen.
- UserDefaults-Key muss migriert werden, damit bestehende Einstellungen nicht verloren gehen.
- Audio-Dateinamen (`intro-breath-de.mp3`) muessen NICHT umbenannt werden — nur Code-Identifier.
- Beide Plattformen koennen unabhaengig voneinander umbenannt werden (keine geteilte Persistenz).
