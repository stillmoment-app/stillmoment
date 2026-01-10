# Release Guide

Kurze Anleitung für wiederkehrende Releases von Still Moment.

## Vor dem Release

### 1. Code-Qualität prüfen

```bash
# iOS
cd ios && make check && make test-unit

# Android
cd android && make check && make test
```

### 2. Manueller Test

Vor jedem Release die manuellen Test-Pläne auf echten Geräten durchführen:
- iOS: `IOS_RELEASE_TEST_PLAN.md`
- Android: `ANDROID_RELEASE_TEST_PLAN.md`

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

```markdown
## [1.8.0] - YYYY-MM-DD

### Added
- ...
```

### 5. Screenshots aktualisieren (falls UI-Änderungen)

```bash
make screenshots-ios      # Fastlane Snapshots
make screenshots-android  # Paparazzi Screenshots
```

## Release erstellen

### iOS

1. **Archive erstellen**: Xcode → Product → Archive
2. **Hochladen**: Window → Organizer → Distribute App → App Store Connect
3. **App Store Connect**: Build auswählen → Submit to App Review

### Android

1. **Signed Bundle erstellen**:
   ```bash
   cd android
   ./gradlew bundleRelease
   ```
2. **Play Console**: Bundle hochladen → Release erstellen → Zur Überprüfung senden

## Nach dem Release

- [ ] Release im CHANGELOG.md mit Datum finalisieren
- [ ] Git-Tag erstellen: `git tag v1.8.0 && git push --tags`
- [ ] Store-Listings prüfen (bei Feature-Änderungen)

## Referenzen

| Thema | Dokument |
|-------|----------|
| App Store Texte | `APP_STORE_METADATA.md` |
| Play Store Texte | `ANDROID_PLAY_STORE_LISTING.md` |
| iOS Manual Tests | `IOS_RELEASE_TEST_PLAN.md` |
| Android Manual Tests | `ANDROID_RELEASE_TEST_PLAN.md` |
