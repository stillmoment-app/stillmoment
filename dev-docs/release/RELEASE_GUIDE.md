# Release Guide

Kurze Anleitung fuer wiederkehrende Releases von Still Moment.

## Release Workflow

Der automatisierte Workflow fuehrt alle Schritte durch: Validierung, Tests, Screenshots, Version bump, Git commit, Tag und Upload.

```bash
# 1. Release Notes generieren (schreibt iOS + Android)
/release-notes

# 2. iOS Release vorbereiten
cd ios
make release-prepare VERSION=1.9.0 DRY_RUN=1  # Vorschau
make release-prepare VERSION=1.9.0            # Ausfuehren

# 3. Android Release vorbereiten
cd ../android
make release-prepare VERSION=1.9.0 DRY_RUN=1  # Vorschau
make release-prepare VERSION=1.9.0            # Ausfuehren

# 4. Push
git push origin main --tags

# 5. Upload zu Stores
cd ../ios && make release VERSION=1.9.0
cd ../android && make release VERSION=1.9.0
```

### Hotfix (nur eine Plattform)

Falls ausnahmsweise nur eine Plattform released werden muss:

```bash
/release-notes ios 1.8.1    # Schreibt nur iOS-Dateien
cd ios && make release-prepare VERSION=1.8.1
```

---

## Was die Befehle tun

### `make release-prepare VERSION=x.y.z`

1. **Validierung**: VERSION Parameter, Working Directory clean, Tag existiert nicht
2. **Release Notes pruefen**: Changelog-Dateien muessen vorhanden sein
3. **Code Quality**: `make check` (Format, Lint)
4. **Tests**: `make test`
5. **Screenshots**: `make screenshots`
6. **Version bump**: versionCode/versionName bzw. CURRENT_PROJECT_VERSION/MARKETING_VERSION
7. **Git commit**: `chore(ios): Prepare release v1.9.0`
8. **Git tag**: `ios-v1.9.0` bzw. `android-v1.9.0`

### `make release VERSION=x.y.z`

**iOS:**
- Baut App (IPA)
- Laedt Build, Metadata und Screenshots zu App Store Connect hoch
- Option: `SKIP_BUILD=1` um nur Metadata/Screenshots hochzuladen

**Android:**
- Baut App Bundle (AAB)
- Laedt zu Play Console (Closed Testing) hoch

---

## Nach dem Upload

### iOS (App Store Connect)

1. Build erscheint nach wenigen Minuten unter "TestFlight" oder "App Store"
2. Build auswaehlen
3. "Submit for Review" klicken

### Android (Play Console)

1. Release in Closed Testing ueberpruefen
2. Bei Bedarf zu Production promoten

---

## Nach dem Release

- [ ] Store-Listings pruefen (Screenshots, Beschreibung aktuell?)
- [ ] GitHub Release erstellen (optional, mit Tag verknuepfen)

## Referenzen

| Thema | Dokument |
|-------|----------|
| Release Notes Skill | `/release-notes` |
| Fastlane iOS Setup | `../guides/fastlane-ios.md` |
| Technisches Changelog | `../../CHANGELOG.md` |
| Gemeinsame Store-Texte | `STORE_CONTENT_SHARED.md` |
| iOS App Store | `STORE_CONTENT_IOS.md` |
| Android Play Store | `STORE_CONTENT_ANDROID.md` |
