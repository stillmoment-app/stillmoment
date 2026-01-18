# Ticket shared-029: Release Prepare Workflow

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: ~2h
**Phase**: 2-Architektur

---

## Was

Shell-Script das den Release-Prozess automatisiert: Validierung, Tests, Screenshots, Version bump, Git commit und Tag. Prueft dass Release Notes vorhanden sind (werden vorher mit `/release-notes` Skill erstellt).

## Warum

Der manuelle Release-Prozess (RELEASE_GUIDE.md) hat viele Schritte, die vergessen werden koennen. Ein automatisiertes Script reduziert Fehler und spart Zeit.

---

## Architektur: Zwei-Schritt-Prozess

```
Schritt 1: /release-notes ios          ← Manuell in Claude Code (interaktiv)
                                          Volle Interaktion moeglich

Schritt 2: make release-prepare VERSION=1.9.0  ← Script (automatisch)
```

```
┌─────────────────────────────────┐
│  1. Validate prerequisites      │
│  2. Check release notes exist   │ ← Prueft ob Fastlane-Dateien da sind
│  3. make check                  │
│  4. make test                   │
│  5. make screenshots            │
│  6. bump-version.sh             │
│  7. git commit + tag            │
└─────────────────────────────────┘
         Alles automatisch
```

**Begruendung**: Release Notes werden separat mit `/release-notes` Skill erstellt. So hat man volle Claude-Interaktion (Feedback, Anpassungen). Das Script validiert nur dass die Notes vorhanden sind und fuehrt dann alles automatisch aus.

---

## Akzeptanzkriterien

### Release Prepare Befehl

```bash
# iOS (im ios/ Verzeichnis)
make release-prepare VERSION=1.9.0

# Android (im android/ Verzeichnis)
make release-prepare VERSION=1.9.0

# Vorschau ohne Ausfuehrung
make release-prepare VERSION=1.9.0 DRY_RUN=1
```

- [x] VERSION Parameter erforderlich (explizit `1.9.0`)
- [x] DRY_RUN Parameter optional: Zeigt alle geplanten Aenderungen ohne Ausfuehrung
- [x] Abbruch bei fehlgeschlagenen Tests (set -e)
- [x] Jede Plattform hat eigene Versionierung

### Validierungen (Schritt 1-2)

- [x] Prueft ob Working Directory clean ist (Release Notes Aenderungen sind erlaubt)
- [x] Prueft ob Tag nicht bereits existiert
- [x] Prueft ob Release Notes vorhanden sind (de-DE + en-US):
  - iOS: `ios/fastlane/metadata/<locale>/changelogs/<VERSION>.txt`
  - Android: `android/fastlane/metadata/android/<locale>/changelogs/<versionCode+1>.txt`
- [x] Fehlermeldung mit Hinweis auf `/release-notes` falls nicht vorhanden

### Automatische Schritte (Schritt 3-7)

- [x] `make check` ausfuehren (Format + Lint) - Auto-Fixes werden mitcommited
- [x] `make test` ausfuehren
- [x] `make screenshots` ausfuehren
- [x] Version in Build-Konfiguration erhoehen (per bump-version.sh)
  - iOS: `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION` (+1)
  - Android: `versionName` + `versionCode` (+1)
- [x] Git commit + tag erstellen

### Git Tags

- [x] iOS: `ios-v1.9.0`
- [x] Android: `android-v1.9.0`

---

## Technische Details

### Dateien

| Datei | Aktion |
|-------|--------|
| `ios/Makefile` | Target `release-prepare` hinzufuegen |
| `ios/scripts/release-prepare.sh` | Neu erstellen |
| `ios/scripts/bump-version.sh` | Neu erstellen |
| `android/Makefile` | Target `release-prepare` hinzufuegen |
| `android/scripts/release-prepare.sh` | Neu erstellen |
| `android/scripts/bump-version.sh` | Neu erstellen |

### Ablauf (Beispiel iOS)

```
# Schritt 1: Release Notes erstellen (in Claude Code)
/release-notes ios

# Schritt 2: Release vorbereiten
$ cd ios
$ make release-prepare VERSION=1.9.0

1. Validating prerequisites...
   ✓ Working directory clean (release notes changes allowed)
   ✓ Tag ios-v1.9.0 does not exist

2. Checking release notes...
   ✓ ios/fastlane/metadata/de-DE/changelogs/1.9.0.txt exists
   ✓ ios/fastlane/metadata/en-US/changelogs/1.9.0.txt exists

3. Running checks...
   make check ✓

4. Running tests...
   make test ✓

5. Generating screenshots...
   make screenshots ✓

6. Bumping version to 1.9.0...
   ✓ MARKETING_VERSION=1.9.0
   ✓ CURRENT_PROJECT_VERSION=2

7. Creating commit and tag...
   ✓ git add -A
   ✓ git commit -m "chore(ios): Prepare release v1.9.0"
   ✓ git tag -a ios-v1.9.0 -m "iOS Release v1.9.0"

Done! Next step:
  git push origin main --tags
  make release

If something went wrong, undo with:
  git reset --hard HEAD~1
  git tag -d ios-v1.9.0
```

### Fehlermeldung bei fehlenden Release Notes

```
$ make release-prepare VERSION=1.9.0

1. Validating prerequisites...
   ✓ Working directory clean (release notes changes allowed)
   ✓ Tag ios-v1.9.0 does not exist

2. Checking release notes...
   ✗ Release notes not found for version 1.9.0

   Run first:
     /release-notes ios

   Then retry:
     make release-prepare VERSION=1.9.0
```

### bump-version.sh

**iOS** (`ios/scripts/bump-version.sh VERSION`):
```bash
# Ersetzt MARKETING_VERSION in project.pbxproj
sed -i '' "s/MARKETING_VERSION = .*/MARKETING_VERSION = $VERSION;/g" ...

# Inkrementiert CURRENT_PROJECT_VERSION
# Liest aktuellen Wert, addiert 1, ersetzt
```

**Android** (`android/scripts/bump-version.sh VERSION`):
```bash
# Ersetzt versionName in build.gradle.kts
sed -i '' "s/versionName = .*/versionName = \"$VERSION\"/g" ...

# Inkrementiert versionCode
# Liest aktuellen Wert, addiert 1, ersetzt
```

---

## Abhaengigkeiten

- Voraussetzung: shared-030 (Release Notes Skill)
- Nachfolger: shared-028 (CI Release Pipeline)

---

## Referenz

- Release Guide: `dev-docs/release/RELEASE_GUIDE.md`
- Release Notes Skill: shared-030

---

## Hinweise

- iOS und Android Versionen koennen divergieren (z.B. iOS 1.8.2, Android 1.7.5)
- Script ist komplett nicht-interaktiv (alle Interaktion passiert vorher im Skill)
- Script bricht bei Fehler sauber ab (set -e), keine Teilzustaende
- Release Notes Aenderungen (vom vorherigen `/release-notes` Skill) werden mitcommitted
- Android Changelog-Validierung: Script liest aktuellen versionCode aus build.gradle.kts und prueft ob Datei fuer versionCode+1 existiert
- Bei Fehler nach Commit: Rollback-Hinweis wird angezeigt (`git reset --hard HEAD~1`)

---
