---
name: release-notes
description: Generiert Release Notes aus CHANGELOG.md fuer beide Plattformen, schlaegt Version vor, uebersetzt nach DE+EN, schreibt in Fastlane-Struktur. Aktiviere bei "Release Notes...", "Prepare release...", oder /release-notes.
---

# Release Notes

Generiert user-facing Release Notes aus CHANGELOG.md fuer iOS und Android.

## Kernprinzip

**Nutzen, nicht Features.** Release Notes beschreiben was der User davon hat - nicht was technisch geaendert wurde.

## Wann dieser Skill aktiviert wird

- "Release Notes erstellen"
- "Prepare release 1.9.0"
- "Was kommt in den naechsten Release?"
- `/release-notes`
- `/release-notes 1.9.0`
- `/release-notes --dry-run`
- `/release-notes ios 1.8.1` (Sonderfall: Hotfix)

## Workflow

### Schritt 1: Parameter parsen

Aus dem Aufruf extrahieren:
- `--dry-run` → Nur Vorschau, keine Dateien schreiben
- Version (z.B. `1.9.0`) → Ueberschreibt Vorschlag
- Plattform (z.B. `ios`) → Sonderfall: nur eine Plattform

**Standardfall:** Keine Parameter = beide Plattformen, automatischer Versionsvorschlag.

### Schritt 2: Aktuelle Versionen lesen

**iOS:**
```bash
grep "MARKETING_VERSION" ios/StillMoment.xcodeproj/project.pbxproj | head -1
grep "CURRENT_PROJECT_VERSION" ios/StillMoment.xcodeproj/project.pbxproj | head -1
```
Extrahiere Version aus `MARKETING_VERSION = X.Y.Z;` und Build-Nummer aus `CURRENT_PROJECT_VERSION = N;`

**Android:**
```bash
grep "versionName" android/app/build.gradle.kts
grep "versionCode" android/app/build.gradle.kts
```
Extrahiere `versionName = "X.Y.Z"` und `versionCode = N`

**Versions-Check:**
- Wenn iOS und Android unterschiedliche Versionen haben → Warnung anzeigen
- Empfehlung: Versionen erst angleichen oder plattform-spezifischen Release machen

### Schritt 3: CHANGELOG.md analysieren

1. Lese `CHANGELOG.md`
2. Extrahiere `## [Unreleased]` Sektion (bis zum naechsten `## [`)
3. Parse Eintraege nach Kategorie:
   - `### Added` → Features
   - `### Changed` → Aenderungen
   - `### Fixed` → Bugfixes

**Filterlogik:**

| Eintrag | Behandlung |
|---------|------------|
| Ohne Plattform-Tag | User-facing → Release Notes |
| Mit `(iOS)` oder `(Android)` | Technisch → NICHT in Release Notes |
| `### Changed` ohne Tag | Nachfragen ob user-relevant |

**Beispiel:**
```markdown
### Added
- **Vorbereitungszeit** - Countdown vor MP3-Start     ← Release Notes
- **Intervall-Gong-Lautstaerke** - Separate Lautstaerke  ← Release Notes

### Fixed
- (iOS) Timer-Layout auf iPhone SE                    ← Technisch, ausschliessen
- (Android) Detekt Lint Issues                        ← Technisch, ausschliessen
```

### Schritt 4: Version vorschlagen

Basierend auf [Unreleased] Inhalt:
- Nur `### Fixed` → **Patch** (1.8.0 → 1.8.1)
- `### Added` vorhanden → **Minor** (1.8.0 → 1.9.0)
- Breaking Changes → **Major** (1.8.0 → 2.0.0) - selten bei Apps

Android: Berechne `versionCode + 1`

### Schritt 5: Release Notes generieren

Formuliere user-facing Beschreibungen:

**Aus CHANGELOG:**
```
- **Vorbereitungszeit fuer gefuehrte Meditationen** - Countdown vor MP3-Start
```

**Fuer Release Notes:**
```
English: Preparation time before guided meditations
Deutsch: Vorbereitungszeit vor gefuehrten Meditationen
```

**Regeln:**
- Kurz und praegnant (eine Zeile pro Feature)
- Nutzen kommunizieren, nicht Technik
- Keine Ticket-Nummern, keine technischen Details
- Bullet Points, kein Fliesstext

### Schritt 6: Zeichenlimits pruefen

| Plattform | Limit | Pruefung |
|-----------|-------|----------|
| Android | 500 Zeichen | Play Store Limit - strikt |
| iOS | 4000 Zeichen | App Store Limit - grosszuegig |

Zeige Zeichenzahl:
```
Characters: DE 89/500 ✓, EN 94/500 ✓
```

Bei Ueberschreitung:
```
Characters: DE 523/500 ⚠️ (23 over), EN 487/500 ✓

German text exceeds Android limit (500 chars).
→ Kuerzen oder mit Warnung fortfahren?
```

### Schritt 7: Vorschau anzeigen

```
Reading CHANGELOG.md...
Current versions: iOS 1.8.0 (build 23), Android 1.8.0 (versionCode 11)

[Unreleased] contains:
  ✓ Added: Vorbereitungszeit fuer gefuehrte Meditationen
  ✓ Added: Intervall-Gong-Lautstaerkeregler
  ✗ Fixed (iOS): Timer-Layout - technical, excluding
  ✗ Fixed (Android): Detekt Issues - technical, excluding

Suggested version: 1.9.0 (minor - new features)
Android versionCode: 12

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
  [Unreleased] → [1.9.0] - 2026-01-17 (4 entries moved)

---
Confirm to write files? (or type new version, or "adjust X")
```

### Schritt 8: Interaktion

User kann:
- **Bestaetigen** (Enter/ja/yes) → Schritt 9
- **Neue Version** eingeben (z.B. "1.8.1") → Zurueck zu Schritt 7 mit neuer Version
- **Anpassen** ("mach kuerzer", "fuege X hinzu", "entferne zweiten Punkt") → Anpassen und Schritt 7
- **Abbrechen** ("abbrechen", "cancel") → Ende ohne Aenderungen

### Schritt 9: Dateien schreiben

**Bei `--dry-run`:** Nur Vorschau, hier abbrechen.

**Zielverzeichnisse:**

| Plattform | Verzeichnis | Dateiname |
|-----------|-------------|-----------|
| iOS | `ios/fastlane/metadata/{locale}/changelogs/` | `{version}.txt` |
| Android | `android/fastlane/metadata/android/{locale}/changelogs/` | `{versionCode}.txt` |

**Locales:** `de-DE`, `en-GB` (iOS) / `en-US` (Android)

**Inhalt:** Nur Bullet Points, kein Header.

**Ordner erstellen** falls nicht vorhanden.

### Schritt 10: CHANGELOG.md aktualisieren

1. Finde `## [Unreleased]` Zeile
2. Fuege nach der naechsten Leerzeile ein:
   ```markdown
   ## [1.9.0] - 2026-01-17
   ```
3. Verschiebe alle Eintraege von [Unreleased] in die neue Sektion
4. [Unreleased] bleibt mit leerem Inhalt

**Vorher:**
```markdown
## [Unreleased]

### Added
- **Feature A** - Beschreibung

### Fixed
- (iOS) Technischer Fix

## [1.8.0] - 2026-01-10
```

**Nachher:**
```markdown
## [Unreleased]

## [1.9.0] - 2026-01-17

### Added
- **Feature A** - Beschreibung

### Fixed
- (iOS) Technischer Fix

## [1.8.0] - 2026-01-10
```

### Schritt 11: Zusammenfassung

```
Written:
  ✓ ios/fastlane/metadata/de-DE/changelogs/1.9.0.txt
  ✓ ios/fastlane/metadata/en-GB/changelogs/1.9.0.txt
  ✓ android/fastlane/metadata/android/de-DE/changelogs/12.txt
  ✓ android/fastlane/metadata/android/en-US/changelogs/12.txt
  ✓ CHANGELOG.md ([Unreleased] → [1.9.0])

Next steps:
  cd ios && make release-prepare VERSION=1.9.0
  cd android && make release-prepare VERSION=1.9.0
```

---

## Sonderfaelle

### Leeres [Unreleased]

```
Reading CHANGELOG.md...

⚠️  [Unreleased] is empty. Nothing to release.

Add changes to CHANGELOG.md first, then run /release-notes again.
```

### Versions-Mismatch

```
Reading versions...
  iOS: 1.8.0
  Android: 1.7.5

⚠️  Version mismatch between platforms.

Options:
1. Align versions first (recommended)
2. Use platform-specific release:
   /release-notes ios 1.8.1
   /release-notes android 1.8.0
```

### Hotfix fuer eine Plattform

```
/release-notes ios 1.8.1

Reading CHANGELOG.md...
Current iOS version: 1.8.0

⚠️  Single-platform release (iOS only)

[Unreleased] iOS-specific entries:
  ✓ Fixed (iOS): Kritischer Bugfix

Release Notes for iOS v1.8.1:

English:
- Critical bug fix for timer

Deutsch:
- Kritischer Bugfix fuer Timer

---
Confirm? (Android stays at 1.8.0)
```

Schreibt nur iOS-Dateien. CHANGELOG erhaelt iOS-spezifische Sektion.

### Nur technische Aenderungen

```
[Unreleased] contains:
  ✗ Fixed (iOS): Timer-Layout - technical
  ✗ Changed (Android): Refactoring - technical

⚠️  No user-facing changes found in [Unreleased].

Options:
1. Add user-facing description to CHANGELOG.md
2. Release with generic note: "Bug fixes and improvements"
3. Cancel
```

---

## Referenzen

- Ticket: `dev-docs/tickets/shared/shared-030-release-notes-skill.md`
- Konzept: `dev-docs/concepts/release-prepare-workflow.md`
- CHANGELOG: `CHANGELOG.md`
- iOS Metadata: `ios/fastlane/metadata/`
- Android Metadata: `android/fastlane/metadata/android/`

---

## Zeichenlimits Referenz

| Store | Feld | Limit |
|-------|------|-------|
| Play Store | Release Notes | 500 Zeichen |
| App Store | What's New | 4000 Zeichen |
