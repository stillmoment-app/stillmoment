# Android Roadmap: Feature-Parity mit iOS

## Ziel
Android-App auf Feature-Parity mit iOS v0.5 bringen.

## Status-Legende
- `[ ]` TODO
- `[~]` IN PROGRESS
- `[x]` DONE

---

## Ticket-Übersicht

| Nr | Ticket | Phase | Status | Abhängigkeit |
|----|--------|-------|--------|--------------|
| [001](001-affirmations-i18n.md) | Affirmationen lokalisieren | Quick Fix | [x] | - |
| [002](002-audio-session-coordinator.md) | Audio Session Coordinator | Architektur | [x] | - |
| [003](003-timer-repository-impl.md) | TimerRepository Implementierung | Architektur | [x] | - |
| [003-2](003-2-timer-viewmodel-repository.md) | TimerViewModel Repository Integration | Architektur | [x] | 003 |
| [004](004-guided-meditation-models.md) | GuidedMeditation Domain Models | Feature | [x] | - |
| [005](005-guided-meditation-repository.md) | GuidedMeditation Repository | Feature | [ ] | 004 |
| [006](006-guided-meditation-viewmodel.md) | GuidedMeditation ViewModel | Feature | [ ] | 005 |
| [007](007-library-screen-ui.md) | Library Screen UI | Feature | [ ] | 006 |
| [008](008-player-screen-ui.md) | Audio Player Screen UI | Feature | [ ] | 006 |
| [009](009-tabview-navigation.md) | TabView Navigation | Feature | [ ] | 007, 008 |
| [010](010-mediasession-lockscreen.md) | MediaSession Lock Screen | Polish | [ ] | 008 |
| [011](011-accessibility-audit.md) | Accessibility Audit | QA | [ ] | 009 |
| [012](012-ui-tests.md) | UI Tests | QA | [ ] | 009 |
| [013](013-integration-test.md) | Final Integration Test | QA | [ ] | Alle |
| [014](014-ambient-sound-fade.md) | Ambient Sound Fade In/Out | Feature | [ ] | - |

---

## Dokumentations-Regel

**Jedes Ticket beinhaltet implizit:**
- CHANGELOG.md aktualisieren (bei Feature/Fix)
- CLAUDE.md aktualisieren (bei Architektur-Änderungen)
- Inline-Kommentare wo nötig

**Explizite Doku-Updates:**
- Ticket 002: CLAUDE.md → Android Audio Coordination Sektion
- Ticket 009: CLAUDE.md → Android Navigation Sektion
- Ticket 013: README.md → Android Feature-Liste

---

## Phasen

### Phase 1: Quick Fixes (Blocker)
Kritische Bugs die sofort behoben werden müssen.

### Phase 2: Architektur-Grundlagen
Strukturelle Verbesserungen für robuste Feature-Entwicklung.

### Phase 3: Guided Meditations Feature
Komplettes Feature für Feature-Parity mit iOS.

### Phase 4: Polish
UX-Verbesserungen und Feinschliff.

### Phase 5: Quality Assurance
Tests und Qualitätssicherung.

---

## Parallelisierbare Tickets

Diese Tickets haben keine Abhängigkeiten und können parallel bearbeitet werden:
- 001, 002, 003, 004 (001-003 erledigt)

Nach Abschluss von 003:
- 003-2 kann bearbeitet werden

Nach Abschluss von 006:
- 007 und 008 können parallel bearbeitet werden

---

## Workflow

```bash
# 1. Ticket lesen
cat dev-docs/android-roadmap/001-affirmations-i18n.md

# 2. Claude Code beauftragen
"Setze Ticket 001 um gemäß der Spezifikation"

# 3. Tests ausführen
cd android && ./gradlew test

# 4. Status in INDEX.md aktualisieren
# [ ] → [x]
```

---

## Branch-Konvention

```bash
git checkout -b feature/android-001-affirmations-i18n
```

## Commit-Konvention

```
feat(android): #001 Affirmationen lokalisieren

- Strings aus TimerViewModel entfernt
- Context.getString() für Ressourcen verwendet
```
