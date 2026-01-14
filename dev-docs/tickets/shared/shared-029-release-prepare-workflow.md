# Ticket shared-029: Release Prepare Workflow

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: ~4h
**Phase**: 2-Architektur

---

## Was

Lokalen Release-Vorbereitungs-Workflow automatisieren: Tests, Version bump, RELEASE_NOTES Vorschlag, Git commit und Tag. Standard ist synchroner Release beider Plattformen, mit Option fuer plattformspezifische Bugfixes.

## Warum

Der manuelle Release-Prozess (RELEASE_GUIDE.md) hat viele Schritte, die vergessen werden koennen. Ein automatisierter Workflow reduziert Fehler und spart Zeit.

---

## Akzeptanzkriterien

### Release Prepare Befehl
- [ ] `make release-prepare VERSION=1.8.0` - Beide Plattformen (Standard)
- [ ] `make release-prepare VERSION=1.8.1 PLATFORM=ios` - Nur iOS
- [ ] `make release-prepare VERSION=1.8.1 PLATFORM=android` - Nur Android
- [ ] VERSION Parameter: `patch`, `minor`, `major` oder explizit `1.8.0`
- [ ] Abbruch bei fehlgeschlagenen Tests

### Automatische Schritte
- [ ] Tests ausfuehren (nur fuer ausgewaehlte Plattform(en))
- [ ] Version in Build-Konfiguration erhoehen
  - iOS: `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION`
  - Android: `versionName` + `versionCode`
- [ ] RELEASE_NOTES.md Vorschlag aus CHANGELOG.md [Unreleased] generieren
- [ ] User kann Vorschlag editieren oder bestaetigen
- [ ] Git commit und tag erstellen

### Git Tags
- [ ] Synchroner Release: `v1.8.0`
- [ ] Nur iOS: `v1.8.1-ios`
- [ ] Nur Android: `v1.8.1-android`

### Interaktiver Modus
- [ ] Zeigt CHANGELOG [Unreleased] Sektion
- [ ] Schlaegt RELEASE_NOTES vor (user-facing, DE + EN)
- [ ] Fragt: [e]dit / [c]onfirm / [s]kip
- [ ] Bei [e]dit: Oeffnet $EDITOR

### Validierungen
- [ ] Prueft ob CHANGELOG [Unreleased] nicht leer ist
- [ ] Prueft ob Working Directory clean ist
- [ ] Prueft ob Tag nicht bereits existiert
- [ ] Warnung wenn keine Tests vorhanden

---

## Technische Details

### Befehle

```bash
# Standard: Beide Plattformen (synchron)
make release-prepare VERSION=1.8.0

# Semantic Version bump
make release-prepare VERSION=patch   # 1.7.0 → 1.7.1
make release-prepare VERSION=minor   # 1.7.0 → 1.8.0
make release-prepare VERSION=major   # 1.7.0 → 2.0.0

# Plattform-spezifischer Bugfix
make release-prepare VERSION=1.8.1 PLATFORM=ios
make release-prepare VERSION=1.8.1 PLATFORM=android
```

### Ablauf (Standard: beide Plattformen)

```
$ make release-prepare VERSION=1.8.0

1. Running tests...
   iOS:     make -C ios check && make -C ios test ✓
   Android: make -C android check && make -C android test ✓

2. Current version: 1.7.0 → 1.8.0
   iOS:     MARKETING_VERSION=1.8.0, BUILD=12
   Android: versionName=1.8.0, versionCode=12

3. CHANGELOG [Unreleased]:
   ### Added (iOS & Android)
   - **Intervall-Gong-Lautstärkeregler** - Separate Lautstärke...

4. Suggested RELEASE_NOTES:

   ## v1.8.0

   ### English
   - Separate volume control for interval gongs

   ### Deutsch
   - Eigene Lautstärke für Intervall-Gongs

   [e]dit / [c]onfirm / [s]kip? c

5. Updating files...
   ✓ ios/StillMoment.xcodeproj (version)
   ✓ android/app/build.gradle.kts (version)
   ✓ dev-docs/release/RELEASE_NOTES.md
   ✓ CHANGELOG.md ([Unreleased] → [1.8.0])

6. Creating commit and tag...
   ✓ git add -A
   ✓ git commit -m "chore: Prepare release v1.8.0"
   ✓ git tag -a v1.8.0 -m "Release v1.8.0"

Done! Next steps:
  git push origin main --tags
  cd ios && make release      # iOS
  cd android && make release  # Android
```

### Ablauf (Plattform-spezifisch)

```
$ make release-prepare VERSION=1.8.1 PLATFORM=ios

1. Running tests...
   iOS: make -C ios check && make -C ios test ✓
   (Android skipped)

2. Current iOS version: 1.8.0 → 1.8.1
   MARKETING_VERSION=1.8.1, BUILD=13

3. CHANGELOG [Unreleased]:
   ### Fixed (iOS)
   - **Crash beim App-Start** - Fix fuer seltenen Edge Case...

4. Suggested RELEASE_NOTES:
   ...

5. Updating files...
   ✓ ios/StillMoment.xcodeproj (version)
   ✓ dev-docs/release/RELEASE_NOTES.md
   ✓ CHANGELOG.md

6. Creating commit and tag...
   ✓ git commit -m "chore: Prepare release v1.8.1 (iOS)"
   ✓ git tag -a v1.8.1-ios -m "Release v1.8.1 (iOS only)"

Done! Next steps:
  git push origin main --tags
  cd ios && make release
```

### RELEASE_NOTES Generierung

Transformation von technisch → user-facing:

| CHANGELOG (technisch) | RELEASE_NOTES (user-facing) |
|-----------------------|-----------------------------|
| `**Feature-Name** - Technische Beschreibung` | Nutzen in einfacher Sprache |
| Ticket-Referenzen | Entfernt |
| Code-Details | Entfernt |
| Architektur-Infos | Entfernt |

### Script-Implementierung

Empfehlung: Bash-Script `scripts/release-prepare.sh`

```bash
#!/bin/bash
VERSION=$1
PLATFORM=${2:-both}  # both, ios, android

# ... Implementation
```

---

## Manueller Test

1. Auf Feature-Branch testen (nicht main)
2. `make release-prepare VERSION=1.8.0-test`
3. Pruefen:
   - Tests liefen
   - Versionen korrekt aktualisiert
   - RELEASE_NOTES Vorschlag sinnvoll
   - Commit und Tag erstellt
4. Tag loeschen: `git tag -d v1.8.0-test`
5. Commit reverten: `git reset --hard HEAD~1`

Zusaetzlich plattformspezifisch testen:
6. `make release-prepare VERSION=1.8.1-test PLATFORM=ios`
7. Pruefen: Nur iOS Version geaendert, Tag ist `v1.8.1-test-ios`

---

## Abhaengigkeiten

- Nachfolger: shared-028 (CI Release Pipeline)

---

## Referenz

- Aktueller Prozess: `dev-docs/release/RELEASE_GUIDE.md`
- CHANGELOG Format: `CHANGELOG.md`
- RELEASE_NOTES Format: `dev-docs/release/RELEASE_NOTES.md`

---

## Hinweise

- CHANGELOG muss bei Ticket-Abschluss gepflegt sein (`/close-ticket` prueft)
- RELEASE_NOTES sind user-facing, koennen manuell angepasst werden
- Script sollte idempotent sein (mehrfach ausfuehrbar ohne Schaden)
- Bei plattformspezifischen Releases: CHANGELOG-Sektion sollte Plattform angeben

---
