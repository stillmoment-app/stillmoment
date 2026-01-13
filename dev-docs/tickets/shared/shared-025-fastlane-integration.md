# Ticket shared-025: Fastlane Integration

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~4h | Android ~4h
**Phase**: 2-Architektur

---

## Was

Fastlane einrichten fuer automatisierte Screenshots und Store-Uploads auf beiden Plattformen.

## Warum

Manuelle Screenshot-Erstellung und Store-Uploads sind zeitaufwendig und fehleranfaellig. Fastlane automatisiert diese Prozesse und ermoeglicht konsistente, reproduzierbare Releases.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Screenshots (beide Plattformen)
- [ ] Automatische Screenshot-Generierung fuer alle unterstuetzten Geraete
- [ ] Screenshots in allen unterstuetzten Sprachen (DE, EN)
- [ ] Optional: Geraeterahmen mit `frameit`

### Store Publishing
- [ ] iOS: Upload zu App Store Connect via `deliver`
- [ ] Android: Upload zum Play Store via `supply`
- [ ] Metadata-Verwaltung (Beschreibungen, Keywords, Release Notes)

### Integration
- [ ] `make screenshots` Befehl fuer beide Plattformen
- [ ] `make release` Befehl fuer Store-Upload
- [ ] CI-Integration moeglich (Credentials via Secrets)

### Dokumentation
- [ ] Setup-Anleitung in dev-docs
- [ ] Credential-Verwaltung dokumentiert

---

## Manueller Test

1. `make screenshots` ausfuehren
2. Screenshots werden in korrekten Ordnern generiert
3. `make release` ausfuehren (Dry-Run)
4. Erwartung: Upload-Vorschau ohne Fehler

---

## Referenz

- iOS: Bestehende UI-Tests als Basis fuer `snapshot`
- Android: Bestehende UI-Tests als Basis fuer `screengrab`
- Fastlane Docs: https://docs.fastlane.tools/

---

## Hinweise

- iOS Code Signing: `match` vereinfacht Zertifikat-Verwaltung
- Android: Service Account fuer Play Console API noetig
- Beide: Credentials niemals committen, nur via CI-Secrets

---
