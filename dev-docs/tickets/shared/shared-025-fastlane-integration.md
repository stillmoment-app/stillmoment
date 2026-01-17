# Ticket shared-025: Fastlane Screenshots

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 2-Architektur

---

## Was

Fastlane einrichten fuer automatisierte Screenshot-Generierung auf beiden Plattformen.

## Warum

Manuelle Screenshot-Erstellung ist zeitaufwendig und fehleranfaellig. Fastlane automatisiert diese Prozesse und ermoeglicht konsistente, reproduzierbare Screenshots fuer Store und Website.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Screenshots (beide Plattformen)
- [x] Automatische Screenshot-Generierung fuer alle unterstuetzten Geraete
- [x] Screenshots in allen unterstuetzten Sprachen (DE, EN)
- [x] `make screenshots` Befehl fuer beide Plattformen
- [x] iOS: Post-Processing Script kopiert Screenshots nach docs/
- [x] Android: Direkter Output nach Supply-kompatiblem Verzeichnis (kein Post-Processing)

### Dokumentation
- [x] Screenshot-Dokumentation in dev-docs

---

## Implementiert

### iOS
- `fastlane screenshots` Lane mit `capture_screenshots`
- `fastlane screenshot_single` fuer einzelne Screenshots
- Snapfile Konfiguration fuer Geraete und Sprachen

### Android
- `fastlane screenshots` Lane mit `capture_android_screenshots` (Screengrab)
- Screengrabfile Konfiguration
- UI-Tests in `ScreengrabScreenshotTests`
- `PlayStoreScreenshotCallback` fuer direkten Supply-kompatiblen Output
- Lokalisierung via `MainActivity.attachBaseContext()`

---

## Follow-up Tickets

- shared-026: iOS Store Publishing (deliver)
- shared-027: Android Store Publishing (supply)
- shared-028: CI Release Pipeline

---

## Referenz

- iOS Screenshots: `ios/fastlane/Fastfile`
- Android Screenshots: `android/fastlane/Fastfile`
- Doku: `dev-docs/guides/screenshots.md`

---
