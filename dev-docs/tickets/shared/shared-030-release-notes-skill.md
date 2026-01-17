# Ticket shared-030: Release Notes Skill

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: ~2h
**Phase**: 2-Architektur

---

## Was

Claude Code Skill `/release-notes` der aus CHANGELOG.md user-facing Release Notes generiert und in die Fastlane-Struktur fuer beide Plattformen schreibt.

## Warum

- CHANGELOG.md ist technisch (fuer Entwickler), Release Notes sind user-facing (fuer App Stores)
- Manuelle Uebersetzung und Umformulierung ist fehleranfaellig und zeitaufwendig
- Claude kann intelligent filtern (user-facing vs. technisch) und uebersetzen (DE + EN)
- iOS und Android releasen gleichzeitig mit identischen Features → ein Aufruf fuer beide

---

## Design-Entscheidungen

### Features sind immer shared

Still Moment hat Feature-Paritaet zwischen iOS und Android. Alle Features werden fuer beide Plattformen implementiert. Plattform-spezifische Eintraege im CHANGELOG sind technische Details (Bugfixes, Refactorings), keine unterschiedlichen Features.

**Konsequenz:**
- Release Notes sind fuer beide Plattformen inhaltlich identisch
- Ein Skill-Aufruf schreibt beide Plattformen
- Kein Plattform-Parameter im Standardfall

### CHANGELOG-Format

```markdown
## [Unreleased]

### Added
- **Feature X** - User-facing Beschreibung

### Fixed
- (iOS) Technischer Bugfix - nicht in Release Notes
- (Android) Technischer Bugfix - nicht in Release Notes

### Changed
- **UI Verbesserung** - User-facing wenn relevant
- (iOS) Internes Refactoring - nicht in Release Notes
```

- Eintraege ohne Plattform-Tag = shared, user-facing → Release Notes
- Eintraege mit `(iOS)` oder `(Android)` Tag = technisch → nicht in Release Notes
- Bei Unsicherheit: Skill fragt nach

---

## Akzeptanzkriterien

### Skill-Aufruf

```bash
/release-notes              # Automatischer Versions-Vorschlag
/release-notes 1.9.0        # Explizite Version
/release-notes --dry-run    # Nur Vorschau, keine Dateien schreiben
/release-notes ios 1.8.1    # Sonderfall: nur eine Plattform (Hotfix)
```

- [x] Version als optionaler Parameter (sonst Vorschlag)
- [x] Plattform-Parameter optional (Standard: beide)
- [x] `--dry-run` Flag: Zeigt Vorschau ohne Dateien zu schreiben

### Versions-Vorschlag

- [x] Liest aktuelle Versionen aus Build-Konfigurationen:
  - iOS: `MARKETING_VERSION` aus project.pbxproj
  - Android: `versionName` aus build.gradle.kts
- [x] Prueft dass beide Plattformen dieselbe Version haben (Warnung wenn nicht)
- [x] Analysiert CHANGELOG.md [Unreleased] Sektion
- [x] Schlaegt Version vor nach Semantic Versioning:
  - Nur fixes → **patch** (1.8.0 → 1.8.1)
  - Neue features → **minor** (1.8.0 → 1.9.0)
- [x] Android: Berechnet naechsten versionCode (aktueller + 1)

### CHANGELOG Analyse

- [x] Liest [Unreleased] Sektion aus CHANGELOG.md
- [x] Filtert user-facing Eintraege:
  - `Added` ohne Tag → immer user-facing
  - `Fixed` / `Changed` ohne Tag → meist user-facing, bei Unsicherheit nachfragen
  - Eintraege mit `(iOS)` oder `(Android)` Tag → technisch, ausschliessen
- [x] Zeigt was eingeschlossen/ausgeschlossen wird
- [x] Extrahiert user-facing Benefits (Nutzen, nicht technische Details)

### Release Notes Generierung

- [x] Generiert user-facing Beschreibungen (Nutzen, nicht Features)
- [x] Uebersetzt nach DE + EN
- [x] Zeigt Vorschlag im Chat
- [x] Interaktive Anpassung moeglich ("mach kuerzer", "fuege X hinzu")
- [x] Schreibt in Fastlane-Struktur nach Bestaetigung

### Zeichenlimit-Pruefung

- [x] Android: Max 500 Zeichen pro Sprache (Play Store Limit)
- [x] iOS: Max 4000 Zeichen pro Sprache (App Store Limit)
- [x] Warnung wenn Limit ueberschritten
- [x] Zeigt aktuelle Zeichenzahl an
- [x] Bei Ueberschreitung: User muss bestaetigen oder kuerzen

**Beispiel bei Ueberschreitung:**
```
Characters: DE 523/500 ⚠️ (23 over), EN 487/500 ✓

German text exceeds Android limit. Options:
1. Shorten the German text
2. Write anyway (will be truncated in Play Store)
```

### Fastlane-Struktur

**iOS:**
- `ios/fastlane/metadata/de-DE/release_notes.txt`
- `ios/fastlane/metadata/en-US/release_notes.txt`

**Android:**
- `android/fastlane/metadata/android/de-DE/changelogs/<versionCode>.txt`
- `android/fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`

### CHANGELOG.md Update

- [x] Aktualisiert CHANGELOG.md nach Bestaetigung:
  - Neuer Header: `## [1.9.0] - 2026-01-17`
  - Verschiebt alle [Unreleased] Eintraege in neue Sektion
  - [Unreleased] bleibt leer zurueck
- [x] Zeigt Preview der CHANGELOG-Aenderungen vor dem Schreiben

**Beispiel vorher:**
```markdown
## [Unreleased]

### Added
- **Feature A** - Beschreibung
- **Feature B** - Beschreibung

### Fixed
- (iOS) Technischer Fix
```

**Beispiel nachher:**
```markdown
## [Unreleased]

## [1.9.0] - 2026-01-17

### Added
- **Feature A** - Beschreibung
- **Feature B** - Beschreibung

### Fixed
- (iOS) Technischer Fix
```

---

## Technische Details

### Skill-Datei

`.claude/skills/release-notes/SKILL.md`

### Standardablauf (beide Plattformen)

```
/release-notes

Reading CHANGELOG.md...
Current versions: iOS 1.8.0 (build 23), Android 1.8.0 (versionCode 11)

[Unreleased] contains:
  ✓ Added: Vorbereitungszeit fuer gefuehrte Meditationen
  ✓ Added: Intervall-Gong-Lautstaerkeregler
  ✗ Fixed (iOS): Timer-Layout - technical, excluding
  ✗ Fixed (Android): Detekt Issues - technical, excluding

Suggested version: 1.9.0 (minor - new features)

---

Release Notes for v1.9.0:

English:
- Preparation time before guided meditations
- Separate volume control for interval gongs

Deutsch:
- Vorbereitungszeit vor gefuehrten Meditationen
- Eigene Lautstaerke fuer Intervall-Gongs

Characters: DE 89/500 ✓, EN 94/500 ✓

---

CHANGELOG.md changes:
  [Unreleased] → [1.9.0] - 2026-01-17 (4 entries)

---
Version okay? Or type new version (e.g. "1.8.1"):
```

User kann:
- Bestaetigen → Dateien werden geschrieben
- Neue Version eingeben → Notes werden mit neuer Version geschrieben
- Feedback geben → "Mach den ersten Punkt kuerzer"
- Abbrechen → Nichts wird geschrieben

### Nach Bestaetigung

```
Written:
  ✓ ios/fastlane/metadata/de-DE/release_notes.txt
  ✓ ios/fastlane/metadata/en-US/release_notes.txt
  ✓ android/fastlane/metadata/android/de-DE/changelogs/12.txt
  ✓ android/fastlane/metadata/android/en-US/changelogs/12.txt
  ✓ CHANGELOG.md ([Unreleased] → [1.9.0])

Next steps:
  cd ios && make release-prepare VERSION=1.9.0
  cd android && make release-prepare VERSION=1.9.0
```

### Sonderfall: Nur eine Plattform (Hotfix)

```
/release-notes ios 1.8.1

Reading CHANGELOG.md...
Current iOS version: 1.8.0

⚠️  Single-platform release (iOS only)
    Android stays at 1.8.0

[Unreleased] contains:
  ✓ Fixed (iOS): Kritischer Bugfix

Release Notes for iOS v1.8.1:
...
```

Schreibt nur iOS-Dateien, CHANGELOG erhaelt iOS-spezifische Sektion.

### Sonderfall: Leeres [Unreleased]

```
/release-notes

Reading CHANGELOG.md...

⚠️  [Unreleased] is empty. Nothing to release.
```

### Sonderfall: Versions-Mismatch

```
/release-notes

Reading versions...
  iOS: 1.8.0
  Android: 1.7.5

⚠️  Version mismatch between platforms.
    Recommend aligning versions first, or use platform-specific release:
    /release-notes ios 1.8.1
    /release-notes android 1.8.0
```

---

## Abhaengigkeiten

- Voraussetzung fuer: shared-029 (Release Prepare Script)

---

## Referenz

- Konzept: `dev-docs/concepts/release-prepare-workflow.md`
- CHANGELOG: `CHANGELOG.md`
- Fastlane iOS: `ios/fastlane/metadata/`
- Fastlane Android: `android/fastlane/metadata/android/`

---

## Hinweise

- Skill ist auch ohne `make release-prepare` nutzbar (z.B. vorab Release Notes pruefen)
- Ordner werden automatisch erstellt falls nicht vorhanden
- **Zeichenlimits**: Android 500, iOS 4000 - Skill warnt bei Ueberschreitung
- **default.txt loeschen**: `android/fastlane/metadata/android/*/changelogs/default.txt` kann geloescht werden sobald versionierte Changelogs existieren
- **Feature-Paritaet**: Beide Plattformen erhalten identische Release Notes
- **Plattform-Tags im CHANGELOG**: `(iOS)` / `(Android)` markieren technische Details, nicht Features

---
