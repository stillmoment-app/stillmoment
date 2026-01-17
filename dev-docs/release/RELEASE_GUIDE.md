# Release Guide

Kurze Anleitung fuer wiederkehrende Releases von Still Moment.

## Quick Release (Empfohlen)

Der automatisierte Workflow fuehrt alle Schritte durch: Validierung, Tests, Screenshots, Version bump, Git commit und Tag.

### Android

```bash
cd android

# 1. Release Notes generieren (aus CHANGELOG.md)
/release-notes android

# 2. Release vorbereiten (Dry Run zuerst empfohlen)
make release-prepare VERSION=1.9.0 DRY_RUN=1  # Vorschau
make release-prepare VERSION=1.9.0            # Ausfuehren

# 3. Push und Upload
git push origin main --tags
make release
```

### iOS

```bash
cd ios

# 1. Release Notes generieren (aus CHANGELOG.md)
/release-notes ios

# 2. Release vorbereiten (Dry Run zuerst empfohlen)
make release-prepare VERSION=1.9.0 DRY_RUN=1  # Vorschau
make release-prepare VERSION=1.9.0            # Ausfuehren

# 3. Push und Upload
git push origin main --tags
# Xcode -> Product -> Archive -> Distribute App
```

### Was `make release-prepare` tut

1. **Validierung**: VERSION Parameter, Working Directory clean, Tag existiert nicht
2. **Release Notes pruefen**: Changelog-Dateien muessen vorhanden sein
3. **Code Quality**: `make check` (Format, Lint)
4. **Tests**: `make test`
5. **Screenshots**: `make screenshots`
6. **Version bump**: versionCode/versionName bzw. CURRENT_PROJECT_VERSION/MARKETING_VERSION
7. **Git commit**: `chore(platform): Prepare release v$VERSION`
8. **Git tag**: `platform-v$VERSION`

---

## Manueller Release (Alternative)

Falls der automatisierte Workflow nicht genutzt werden soll.

### 1. Code-Qualitaet pruefen

```bash
# iOS
cd ios && make check && make test

# Android
cd android && make check && make test
```

### 2. Version erhoehen

**iOS** (in Xcode: Target -> General oder direkt in `project.pbxproj`):
- `MARKETING_VERSION` = Versionsnummer (z.B. `1.8.0`)
- `CURRENT_PROJECT_VERSION` = Build-Nummer erhoehen

**Android** (`android/app/build.gradle.kts`):
```kotlin
versionCode = 11        // Erhoehen (muss eindeutig sein)
versionName = "1.8.0"   // Versionsnummer
```

### 3. CHANGELOG.md aktualisieren

Technische Aenderungen dokumentieren (fuer Entwickler):

```markdown
## [1.8.0] - YYYY-MM-DD (Kurztitel)

### Added (iOS & Android)
- **Feature-Name** - Kurzbeschreibung
  - Technische Details
  - Ticket: shared-XXX
```

### 4. Release Notes erstellen

```bash
/release-notes ios    # oder android
```

Der Skill generiert user-facing Release Notes aus CHANGELOG.md und schreibt sie in die Fastlane-Struktur.

### 5. Screenshots aktualisieren (falls UI-Aenderungen)

```bash
# iOS
cd ios && make screenshots

# Android
cd android && make screenshots
```

### 6. Git Tag erstellen

Nach allen Aenderungen, vor dem Store-Upload:

```bash
git add -A
git commit -m "chore: Prepare release v1.8.0"
git tag -a v1.8.0 -m "Release v1.8.0 - Kurztitel"
git push origin main --tags
```

**Tag-Format:** `v{MAJOR}.{MINOR}.{PATCH}` (z.B. `v1.8.0`)

## Release erstellen

### iOS

1. **Archive erstellen**: Xcode -> Product -> Archive
2. **Hochladen**: Window -> Organizer -> Distribute App -> App Store Connect
3. **What's New**: Fastlane uebernimmt Release Notes automatisch
4. **App Store Connect**: Build auswaehlen -> Submit to App Review

### Android

1. **Upload via Fastlane**:
   ```bash
   cd android
   make release
   ```
2. **Play Console**: Release ueberpruefen und freigeben

## Nach dem Release

- [ ] Store-Listings pruefen (Screenshots, Beschreibung aktuell?)
- [ ] GitHub Release erstellen (optional, mit Tag verknuepfen)

## Referenzen

| Thema | Dokument |
|-------|----------|
| Technisches Changelog | `../../CHANGELOG.md` |
| Gemeinsame Store-Texte | `STORE_CONTENT_SHARED.md` |
| iOS App Store | `STORE_CONTENT_IOS.md` |
| Android Play Store | `STORE_CONTENT_ANDROID.md` |
