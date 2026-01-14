# Ticket shared-026: iOS Store Publishing mit Fastlane

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: ~4h
**Phase**: 2-Architektur

---

## Was

Fastlane `deliver` einrichten fuer automatisierte Uploads zu App Store Connect, inklusive Metadata-Verwaltung und optionalem Code Signing mit `match`.

## Warum

Manuelle Store-Uploads sind zeitaufwendig und fehleranfaellig. Mit `deliver` koennen Builds, Screenshots, Beschreibungen und Release Notes automatisiert hochgeladen werden.

---

## Akzeptanzkriterien

### Store Publishing
- [ ] `fastlane deliver` Lane konfiguriert
- [ ] Metadata-Verzeichnis mit Beschreibungen (DE, EN)
- [ ] Release Notes Template
- [ ] Screenshots werden aus bestehendem Verzeichnis verwendet

### Code Signing (optional)
- [ ] `match` fuer Zertifikat-Verwaltung evaluiert
- [ ] Entscheidung dokumentiert: match vs. manuelles Signing

### Makefile Integration
- [ ] `make release` oder `make upload` Befehl
- [ ] Dry-Run Modus fuer Validierung ohne Upload

### Dokumentation
- [ ] Setup-Anleitung in dev-docs
- [ ] Credential-Verwaltung dokumentiert (App Store Connect API Key)

---

## Technische Details

### Fastlane Actions
- `deliver`: Upload zu App Store Connect
- `match` (optional): Code Signing Zertifikate
- `pilot`: TestFlight Upload (falls gewuenscht)

### Credentials
- App Store Connect API Key (JSON-Datei)
- NIEMALS in Git committen
- Lokale Nutzung: `~/.fastlane/` oder Umgebungsvariablen

### Metadata-Struktur
```
ios/fastlane/metadata/
├── de-DE/
│   ├── name.txt
│   ├── subtitle.txt
│   ├── description.txt
│   ├── keywords.txt
│   ├── release_notes.txt
│   └── privacy_url.txt
├── en-US/
│   └── ... (analog)
└── review_information/
    └── notes.txt
```

---

## Manueller Test

1. `make release-dry` ausfuehren
2. Erwartung: Validierung erfolgreich, kein Upload
3. Optional: `make release` fuer echten Upload

---

## Abhaengigkeiten

- Voraussetzung: shared-025 (Screenshots) - DONE
- Nachfolger: shared-028 (CI Release Pipeline)

---

## Referenz

- Fastlane deliver: https://docs.fastlane.tools/actions/deliver/
- Fastlane match: https://docs.fastlane.tools/actions/match/
- App Store Connect API: https://developer.apple.com/documentation/appstoreconnectapi

---

## Hinweise

- Erster Upload muss manuell erfolgen (App anlegen in App Store Connect)
- API Key hat 6 Monate Gueltigkeit, dann erneuern
- TestFlight Upload kann als Zwischenschritt vor Store-Release dienen

---
