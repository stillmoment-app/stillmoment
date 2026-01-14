# Ticket shared-028: CI Release Pipeline

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: ~4h
**Phase**: 2-Architektur

---

## Was

GitHub Actions Workflow einrichten fuer automatisierte Store-Releases, getriggert durch Git Tags oder manuellen Dispatch.

## Warum

Lokale Releases sind fehleranfaellig und nicht reproduzierbar. Eine CI-Pipeline garantiert konsistente Builds und ermoeglicht Releases ohne lokale Entwicklungsumgebung.

---

## Akzeptanzkriterien

### GitHub Actions Workflow
- [ ] Release-Workflow fuer iOS (TestFlight/App Store)
- [ ] Release-Workflow fuer Android (Internal/Production Track)
- [ ] Trigger: Git Tag (`v*`) oder manueller Dispatch
- [ ] Version aus Tag extrahieren

### Secrets Management
- [ ] iOS: App Store Connect API Key als Secret
- [ ] Android: Service Account JSON als Secret
- [ ] iOS: Code Signing (match oder manuell)

### Release Tracks
- [ ] iOS: TestFlight als Default, App Store optional
- [ ] Android: Internal Track als Default, Production optional
- [ ] Track-Auswahl via Workflow Input

### Dokumentation
- [ ] Release-Workflow in dev-docs dokumentiert
- [ ] Secrets-Setup Anleitung

---

## Technische Details

### Workflow Trigger
```yaml
on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      platform:
        type: choice
        options: [ios, android, both]
      track:
        type: choice
        options: [internal, production]
```

### Secrets (GitHub Repository Settings)
- `APP_STORE_CONNECT_API_KEY_JSON`: App Store Connect API Key
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: Play Console Service Account
- `MATCH_PASSWORD` (optional): Fastlane match Encryption Password

### Jobs
1. **ios-release**: macOS Runner, Xcode, Fastlane deliver
2. **android-release**: Ubuntu Runner, Java, Fastlane supply

---

## Manueller Test

1. Tag erstellen: `git tag v1.0.0-test`
2. Tag pushen: `git push origin v1.0.0-test`
3. GitHub Actions Workflow laeuft
4. Erwartung: Builds erfolgreich, Upload zu Test-Tracks

---

## Abhaengigkeiten

- Voraussetzung: shared-026 (iOS Store Publishing)
- Voraussetzung: shared-027 (Android Store Publishing)

---

## Referenz

- GitHub Actions: https://docs.github.com/en/actions
- Fastlane CI Setup: https://docs.fastlane.tools/best-practices/continuous-integration/
- GitHub Secrets: https://docs.github.com/en/actions/security-guides/encrypted-secrets

---

## Hinweise

- macOS Runner fuer iOS erforderlich (GitHub-hosted oder self-hosted)
- Android kann auf Ubuntu laufen (schneller, guenstiger)
- Dry-Run auf Feature-Branches empfohlen vor echtem Release

---
