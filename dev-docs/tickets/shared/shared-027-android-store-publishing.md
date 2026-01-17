# Ticket shared-027: Android Store Publishing mit Fastlane

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: ~3h
**Phase**: 2-Architektur

---

## Was

Fastlane `supply` einrichten fuer automatisierte Uploads zum Google Play Store, inklusive Metadata-Verwaltung.

## Warum

Manuelle Store-Uploads sind zeitaufwendig und fehleranfaellig. Mit `supply` koennen AABs/APKs, Screenshots, Beschreibungen und Release Notes automatisiert hochgeladen werden.

---

## Akzeptanzkriterien

### Store Publishing
- [x] `fastlane supply` Lane konfiguriert
- [x] Metadata-Verzeichnis mit Beschreibungen (DE, EN)
- [x] Release Notes Template
- [x] Screenshots werden direkt in Supply-kompatibles Format geschrieben

### Service Account
- [x] Google Cloud Service Account erstellt
- [x] Play Console API Zugriff konfiguriert
- [x] JSON Key sicher gespeichert (nicht in Git)

### Makefile Integration
- [x] `make release` Befehl
- [x] `make screenshots-upload` fuer separaten Screenshot-Upload
- [x] `make metadata` fuer Metadata-only Upload
- [x] Dry-Run via `make release-validate`

### Dokumentation
- [x] Setup-Anleitung in dev-docs
- [x] Screenshot-Dokumentation aktualisiert

---

## Technische Details

### Fastlane Actions
- `supply`: Upload zum Play Store
- `gradle`: AAB/APK Build

### Service Account Setup
1. Google Cloud Console: Projekt erstellen/auswaehlen
2. Service Account erstellen mit Play Console API Zugriff
3. JSON Key herunterladen
4. In Play Console: Service Account einladen mit Release-Rechten

### Credentials
- Service Account JSON Key
- NIEMALS in Git committen
- Lokale Nutzung: `~/.fastlane/` oder `SUPPLY_JSON_KEY` Umgebungsvariable

### Metadata-Struktur
```
android/fastlane/metadata/android/
├── de-DE/
│   ├── title.txt
│   ├── short_description.txt
│   ├── full_description.txt
│   ├── changelogs/
│   │   └── default.txt
│   └── images/
│       └── phoneScreenshots/   # Screenshots (Supply-Format)
└── en-US/
    └── ... (analog)
```

---

## Implementiert

### Fastlane Lanes
- `release`: Build + Upload zum Play Store (Closed Testing)
- `metadata`: Nur Metadata/Changelogs hochladen
- `screenshots_upload`: Nur Screenshots hochladen
- `release_validate`: Dry-Run Validierung

### Screenshot-Pipeline
- `PlayStoreScreenshotCallback.kt`: Custom Callback ohne Timestamps
- Screenshots werden direkt nach `metadata/android/<locale>/images/phoneScreenshots/` geschrieben
- Kein Post-Processing-Script mehr noetig
- Lokalisierung via `MainActivity.attachBaseContext()` und `Locale.setDefault()`

### Makefile Commands
- `make release` - Build + Upload
- `make release-validate` - Validierung ohne Upload
- `make metadata` - Nur Metadata hochladen
- `make screenshots-upload` - Nur Screenshots hochladen

---

## Manueller Test

1. `make release-dry` ausfuehren
2. Erwartung: Validierung erfolgreich, kein Upload
3. Optional: `make release` fuer echten Upload (Internal Track)

---

## Abhaengigkeiten

- Voraussetzung: shared-025 (Screenshots) - DONE
- Nachfolger: shared-028 (CI Release Pipeline)

---

## Referenz

- Fastlane supply: https://docs.fastlane.tools/actions/supply/
- Play Console API: https://developers.google.com/android-publisher
- Service Account Setup: https://docs.fastlane.tools/actions/supply/#setup

---

## Hinweise

- Erster Upload muss manuell erfolgen (App anlegen in Play Console)
- Service Account braucht "Release Manager" Rolle in Play Console
- Internal Track fuer erste Tests empfohlen

---
