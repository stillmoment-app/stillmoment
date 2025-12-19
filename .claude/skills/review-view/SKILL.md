---
name: review-view
description: Bewertet Views auf iOS und Android nach Accessibility, Code-Qualität, Test-Coverage und UX/Layout. Erstellt automatisch Tickets für kritische Findings. Aktiviere diesen Skill wenn der User nach View-Qualitätsprüfung, View-Review, Accessibility-Check einer View, oder Cross-Platform-Konsistenz fragt.
---

# View Quality Review

Systematische Bewertung von Views auf beiden Plattformen (iOS + Android) mit automatischer Ticket-Erstellung.

## Wann dieser Skill aktiviert wird

Dieser Skill wird automatisch geladen wenn der User fragt nach:
- "Bewerte die TimerView" / "Review the Timer screen"
- "Prüfe die Accessibility der PlayerView"
- "Check quality of the Library view"
- "Sind Timer iOS und Android konsistent?"
- "View Quality Check für Settings"

**Keyword aus der Anfrage extrahieren:**
- "Bewerte die **Timer**View" → Keyword: Timer
- "Review **Player** screen" → Keyword: Player
- "Check **Library** view" → Keyword: Library

## Workflow

### Schritt 1: Views finden

Suche Views dynamisch anhand des Keywords:

```
iOS:     ios/**/Views/**/*{keyword}*.swift
Android: android/**/ui/**/*{keyword}*.kt
```

**Ausschlüsse:** Tests, Mocks, Previews (Dateien mit `Test`, `Mock`, `Preview` im Namen)

**Match-Handling:**
- 0 Matches: Fehlermeldung mit verfügbaren Views
- 1-3 pro Plattform: Alle automatisch bewerten
- >3 pro Plattform: User wählt aus

### Schritt 2: Zugehörige Dateien finden

Für jede View automatisch suchen:
- **ViewModel**: `*{ViewName}ViewModel*`
- **Unit-Tests**: `*{ViewName}*Tests.swift` / `*{ScreenName}*Test.kt`
- **UI-Tests**: Im UITests-Verzeichnis

### Schritt 3: Dateien lesen

Alle gefundenen Dateien mit dem Read-Tool lesen:
- View-Code analysieren
- ViewModel-Code analysieren
- Test-Coverage prüfen

### Schritt 4: Bewertung durchführen

Bewerte nach 4 Kategorien (je 25 Punkte, max 100):

1. **Accessibility** (25 Punkte)
   - Siehe `checklists/accessibility.md`

2. **Code-Qualität** (25 Punkte)
   - Siehe `checklists/code-quality.md`

3. **Test-Coverage** (25 Punkte)
   - Siehe `checklists/test-coverage.md`

4. **UX/Layout** (25 Punkte)
   - Siehe `checklists/ux-layout.md`

### Schritt 5: Cross-Platform Vergleich

Vergleiche iOS und Android:
- Sind beide Plattformen konsistent?
- Folgen beide den jeweiligen Platform-Guidelines?
- Gibt es Feature-Parity-Probleme?

### Schritt 6: Report generieren

Erstelle strukturierten Report nach `templates/report.md`:
- Gesamt-Score und Scores pro Kategorie
- Kritische, mittlere und positive Findings
- Cross-Platform Konsistenz-Bewertung

### Schritt 7: Tickets erstellen

Für kritische Findings (Score-Abzug >= 5 Punkte):

1. Ticket-Datei erstellen in `dev-docs/tickets/{platform}/`
2. Format: `{platform}-{NNN}-{view}-{issue}.md`
3. Template: `dev-docs/tickets/TEMPLATE-platform.md`
4. INDEX.md aktualisieren

**Nächste Ticket-Nummern:**
- iOS: ios-016
- Android: android-028
- Shared: shared-006

**Phase-Zuordnung:**
| Finding-Typ | Phase |
|-------------|-------|
| Fehlende Accessibility-Labels | 1-Quick Fix |
| Layout-Probleme | 4-Polish |
| Fehlende Tests | 5-QA |
| Code-Qualität | 4-Polish |

## Referenzen

### Projekt-Standards
- `CLAUDE.md` - Architektur, Patterns, Standards
- `dev-docs/COLOR_SYSTEM.md` - Semantic Colors

### Ticket-System
- `dev-docs/tickets/TEMPLATE-platform.md` - Ticket-Vorlage
- `dev-docs/tickets/INDEX.md` - Ticket-Übersicht

### Verzeichnis-Struktur
| Plattform | Views | ViewModels | Tests |
|-----------|-------|------------|-------|
| iOS | `ios/**/Views/**/*.swift` | `ios/**/ViewModels/*.swift` | `ios/StillMomentTests/**/*Tests.swift` |
| Android | `android/**/ui/**/*.kt` | `android/**/viewmodel/*.kt` | `android/**/test/**/*Test.kt` |

## Scoring-Regeln

### Punkte-Abzug pro Kategorie

| Schwere | Abzug | Ticket? |
|---------|-------|---------|
| Kritisch | 5+ Punkte | Ja |
| Mittel | 2-4 Punkte | Optional |
| Gering | 1 Punkt | Nein |

### Gesamt-Bewertung

| Score | Bewertung |
|-------|-----------|
| 90-100 | Exzellent |
| 75-89 | Gut |
| 60-74 | Verbesserungswürdig |
| < 60 | Kritisch |
