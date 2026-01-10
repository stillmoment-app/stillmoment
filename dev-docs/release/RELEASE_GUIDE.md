# Release Guide

Kurze Anleitung für wiederkehrende Releases von Still Moment.

## Vor dem Release

### 1. Code-Qualität prüfen

```bash
# iOS
cd ios && make check && make test

# Android
cd android && make check && make test
```

### 2. Manueller Test

Vor jedem Release die manuellen Test-Pläne auf echten Geräten durchführen:
- iOS: `TEST_PLAN_IOS.md`
- Android: `TEST_PLAN_ANDROID.md`

### 3. Version erhöhen

**iOS** (in Xcode: Target → General oder direkt in `project.pbxproj`):
- `MARKETING_VERSION` = Versionsnummer (z.B. `1.8.0`)
- `CURRENT_PROJECT_VERSION` = Build-Nummer erhöhen

**Android** (`android/app/build.gradle.kts`):
```kotlin
versionCode = 11        // Erhöhen (muss eindeutig sein)
versionName = "1.8.0"   // Versionsnummer
```

### 4. CHANGELOG.md aktualisieren

Technische Änderungen dokumentieren (für Entwickler):

```markdown
## [1.8.0] - YYYY-MM-DD (Kurztitel)

### Added (iOS & Android)
- **Feature-Name** - Kurzbeschreibung
  - Technische Details
  - Ticket: shared-XXX
```

### 5. RELEASE_NOTES.md aktualisieren

User-facing Release Notes erstellen (für App Store / Play Store):

```markdown
## v1.8.0 - Kurztitel

### English
- Feature benefit in simple language
- Another user-visible improvement

### Deutsch
- Feature-Nutzen in einfacher Sprache
- Weitere sichtbare Verbesserung
```

**Qualitätskriterien:**
- Keine Ticket-Referenzen
- Keine technischen Details (keine Code-Namen, APIs, Patterns)
- Nutzen-orientiert, nicht Feature-orientiert
- 2-5 Punkte pro Version
- Immer DE + EN

### 6. Screenshots aktualisieren (falls UI-Änderungen)

```bash
make screenshots-ios      # Fastlane Snapshots
make screenshots-android  # Paparazzi Screenshots
```

### 7. Git Tag erstellen

Nach allen Änderungen, vor dem Store-Upload:

```bash
git add -A
git commit -m "chore: Prepare release v1.8.0"
git tag -a v1.8.0 -m "Release v1.8.0 - Kurztitel"
git push origin main --tags
```

**Tag-Format:** `v{MAJOR}.{MINOR}.{PATCH}` (z.B. `v1.8.0`)

## Release erstellen

### iOS

1. **Archive erstellen**: Xcode → Product → Archive
2. **Hochladen**: Window → Organizer → Distribute App → App Store Connect
3. **What's New**: Text aus `RELEASE_NOTES.md` (Deutsch) kopieren
4. **App Store Connect**: Build auswählen → Submit to App Review

### Android

1. **Signed Bundle erstellen**:
   ```bash
   cd android
   ./gradlew bundleRelease
   ```
2. **Play Console**: Bundle hochladen → Release erstellen
3. **What's New**: Text aus `RELEASE_NOTES.md` (Deutsch + English) kopieren
4. **Zur Überprüfung senden**

## Nach dem Release

- [ ] Store-Listings prüfen (Screenshots, Beschreibung aktuell?)
- [ ] GitHub Release erstellen (optional, mit Tag verknüpfen)

## Referenzen

| Thema | Dokument |
|-------|----------|
| User-facing Release Notes | `RELEASE_NOTES.md` |
| Technisches Changelog | `../../CHANGELOG.md` |
| Gemeinsame Store-Texte | `STORE_CONTENT_SHARED.md` |
| iOS App Store | `STORE_CONTENT_IOS.md` |
| Android Play Store | `STORE_CONTENT_ANDROID.md` |
| iOS Manual Tests | `TEST_PLAN_IOS.md` |
| Android Manual Tests | `TEST_PLAN_ANDROID.md` |
