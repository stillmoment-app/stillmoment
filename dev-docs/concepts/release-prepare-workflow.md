# Konzept: Release Prepare Workflow

**Tickets**: shared-029 (Script), shared-030 (Skill)
**Status**: Konzept
**Erstellt**: 2026-01-14
**Aktualisiert**: 2026-01-17

---

## Uebersicht

Dieses Dokument haelt Design-Entscheidungen fuer den automatisierten Release-Vorbereitungs-Workflow fest.

**Kernentscheidungen**:
1. Features sind immer shared - beide Plattformen erhalten identische Release Notes
2. iOS und Android releasen gleichzeitig (gleiche Version, gleiche Woche)
3. Zwei-Schritt-Prozess: Skill fuer Release Notes, Script fuer Automatisierung

---

## 1. Feature-Paritaet

### Entscheidung

Still Moment hat Feature-Paritaet zwischen iOS und Android. Alle Features werden fuer beide Plattformen implementiert.

### Konsequenzen

- Release Notes sind fuer beide Plattformen inhaltlich identisch
- Ein Skill-Aufruf (`/release-notes`) schreibt beide Plattformen
- Kein Plattform-Parameter im Standardfall
- Plattform-spezifische Eintraege im CHANGELOG sind technische Details, keine Features

### CHANGELOG-Format

```markdown
## [Unreleased]

### Added
- **Feature X** - User-facing (→ Release Notes)

### Fixed
- (iOS) Technischer Bugfix (→ nicht in Release Notes)
- (Android) Technischer Bugfix (→ nicht in Release Notes)
```

- Eintraege ohne Tag = shared, user-facing
- Eintraege mit `(iOS)` / `(Android)` Tag = technisch, nicht user-facing

---

## 2. Zwei-Schritt-Architektur

### Entscheidung

```
Schritt 1: /release-notes              ← Claude Code Skill (interaktiv)
Schritt 2: make release-prepare VERSION=1.9.0  ← Shell-Script (automatisch)
```

### Ablauf

```
┌─────────────────────────────────────────────────────────────┐
│  Schritt 1: /release-notes                                  │
│  - Liest CHANGELOG.md                                       │
│  - Schlaegt Version vor (Semantic Versioning)               │
│  - Generiert Release Notes (DE + EN)                        │
│  - Volle Interaktion: Feedback, Anpassungen                 │
│  - Schreibt in Fastlane-Struktur (beide Plattformen)        │
│  - Updated CHANGELOG.md                                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Schritt 2: make release-prepare VERSION=1.9.0              │
│  (einmal pro Plattform: cd ios && ..., cd android && ...)   │
│  1. Validate prerequisites                                  │
│  2. Check release notes exist                               │
│  3. make check                                              │
│  4. make test                                               │
│  5. make screenshots                                        │
│  6. bump-version.sh                                         │
│  7. git commit + tag                                        │
│                                                             │
│  Alles automatisch, keine Interaktion                       │
└─────────────────────────────────────────────────────────────┘
```

### Begruendung

**Skill separat** (Schritt 1):
- Volle Claude-Interaktion moeglich
- Feedback geben: "Mach kuerzer", "Fuege X hinzu"
- Version anpassen bevor Rest laeuft
- Kann auch ohne Script genutzt werden (z.B. vorab Release Notes sehen)
- Schreibt beide Plattformen in einem Aufruf

**Script automatisch** (Schritt 2):
- Deterministisch und zuverlaessig
- Keine vergessenen Schritte
- Validiert dass Release Notes vorhanden sind (de-DE + en-US)
- Laeuft komplett durch ohne Unterbrechung
- Bei Fehler nach Commit: Rollback-Hinweis

### Verworfene Alternative: Alles in einem Script

**Abgelehnt weil:**
- Eingeschraenkte Interaktion (nur [y/n])
- Kein echtes Feedback moeglich
- Claude CLI im Script ist umstaendlich

---

## 3. Tag-Format

### Entscheidung

Plattform-Prefix vor der Version.

| Plattform | Tag-Format | Beispiel |
|-----------|------------|----------|
| iOS | `ios-v{VERSION}` | `ios-v1.9.0` |
| Android | `android-v{VERSION}` | `android-v1.9.0` |

### Begruendung

- Klare Zuordnung welcher Tag zu welcher Plattform gehoert
- `git tag --list 'ios-*'` zeigt alle iOS Releases
- Ermoeglicht unterschiedliche Versionen bei Hotfixes

---

## 4. CHANGELOG und RELEASE_NOTES

### Entscheidung

- **CHANGELOG.md**: Gemeinsam fuer beide Plattformen, Quelle fuer Release Notes
- **RELEASE_NOTES**: Direkt in Fastlane-Struktur pro Sprache

### Begruendung

- CHANGELOG ist fuer Entwickler - zeigt was sich im Projekt geaendert hat
- CHANGELOG ist strukturiert und kann von Claude geparst werden
- RELEASE_NOTES sind fuer User - zeigen was in dieser Store-Version neu ist
- Claude uebersetzt und formuliert user-facing

---

## 5. RELEASE_NOTES Generierung (Skill)

### Entscheidung

Claude Skill `/release-notes` analysiert CHANGELOG.md, schlaegt Version vor, und generiert Release Notes fuer beide Plattformen.

### Ablauf

1. Lese aktuelle Versionen aus Build-Konfigurationen (iOS + Android)
2. Pruefe dass Versionen uebereinstimmen (Warnung wenn nicht)
3. Lese CHANGELOG.md [Unreleased] Sektion
4. Filtere user-facing Eintraege (ohne Plattform-Tag)
5. Analysiere Aenderungen (features vs. fixes)
6. Schlage Version vor (Semantic Versioning)
7. Generiere user-facing Release Notes
8. Uebersetze nach DE + EN
9. Interaktion: User kann Feedback geben, Version aendern
10. Schreibe in Fastlane-Struktur (beide Plattformen)
11. Update CHANGELOG.md

### Fastlane-Struktur

**iOS:**
- `ios/fastlane/metadata/de-DE/changelogs/<VERSION>.txt`
- `ios/fastlane/metadata/en-US/changelogs/<VERSION>.txt`

**Android:**
- `android/fastlane/metadata/android/de-DE/changelogs/<versionCode>.txt`
- `android/fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`

### Beispiel

```
/release-notes

Reading CHANGELOG.md...
Current versions: iOS 1.8.0 (build 23), Android 1.8.0 (versionCode 11)

[Unreleased] contains:
  ✓ Added: Vorbereitungszeit fuer gefuehrte Meditationen
  ✓ Added: Intervall-Gong-Lautstaerkeregler
  ✗ Fixed (iOS): Timer-Layout - technical, excluding

Suggested version: 1.9.0 (minor - new features)

Release Notes for v1.9.0:

English:
- Preparation time before guided meditations
- Separate volume control for interval gongs

Deutsch:
- Vorbereitungszeit vor gefuehrten Meditationen
- Eigene Lautstaerke fuer Intervall-Gongs

Characters: DE 89/500 ✓, EN 94/500 ✓

---
Version okay? Or type new version (e.g. "1.8.1"):
```

---

## 6. Sonderfall: Hotfix fuer eine Plattform

Falls ausnahmsweise nur eine Plattform released werden muss:

```bash
/release-notes ios 1.8.1    # Nur iOS
```

- Schreibt nur iOS-Dateien
- CHANGELOG erhaelt iOS-spezifische Sektion
- Android bleibt unveraendert

---

## 7. Zusaetzliche Parameter (Script)

### DRY_RUN

```bash
make release-prepare VERSION=1.8.0 DRY_RUN=1
```

Zeigt alle geplanten Aenderungen ohne Ausfuehrung.

---

## 8. Commit-Format

| Plattform | Commit-Message |
|-----------|---------------|
| iOS | `chore(ios): Prepare release v1.9.0` |
| Android | `chore(android): Prepare release v1.9.0` |

---

## 9. Version Bump

### Entscheidung

Automatisch per bump-version.sh Script.

### iOS

- `MARKETING_VERSION` in project.pbxproj ersetzen
- `CURRENT_PROJECT_VERSION` um 1 erhoehen

### Android

- `versionName` in build.gradle.kts ersetzen
- `versionCode` um 1 erhoehen

### Semantic Versioning (Skill-Vorschlag)

- Nur fixes → **patch** (1.8.0 → 1.8.1)
- Neue features → **minor** (1.8.0 → 1.9.0)
- Breaking changes → **major** (1.8.0 → 2.0.0)

---

## Referenzen

- Ticket Script: `dev-docs/tickets/shared/shared-029-release-prepare-workflow.md`
- Ticket Skill: `dev-docs/tickets/shared/shared-030-release-notes-skill.md`
- Aktueller Prozess: `dev-docs/release/RELEASE_GUIDE.md`
- CHANGELOG: `CHANGELOG.md`
