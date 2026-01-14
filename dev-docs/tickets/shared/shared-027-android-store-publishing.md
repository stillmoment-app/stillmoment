# Ticket shared-027: Android Store Publishing mit Fastlane

**Status**: [ ] TODO
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
- [ ] `fastlane supply` Lane konfiguriert
- [ ] Metadata-Verzeichnis mit Beschreibungen (DE, EN)
- [ ] Release Notes Template
- [ ] Screenshots werden aus bestehendem Verzeichnis verwendet

### Service Account
- [ ] Google Cloud Service Account erstellt
- [ ] Play Console API Zugriff konfiguriert
- [ ] JSON Key sicher gespeichert (nicht in Git)

### Makefile Integration
- [ ] `make release` oder `make upload` Befehl
- [ ] Dry-Run Modus fuer Validierung ohne Upload

### Dokumentation
- [ ] Setup-Anleitung in dev-docs
- [ ] Service Account Erstellung dokumentiert

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
│   └── changelogs/
│       └── default.txt
├── en-US/
│   └── ... (analog)
└── images/
    └── ... (Screenshots, falls nicht aus docs/)
```

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
