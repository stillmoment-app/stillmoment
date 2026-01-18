# Ticket ios-033: SettingsView Dependency Injection

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: shared-024
**Phase**: 2-Architektur

---

## Was

SettingsView soll alle Dependencies injiziert bekommen, statt sie intern zu instantiieren.

## Warum

Konsistenz und Testbarkeit: Die View erstellt aktuell intern `AudioService()` und verwendet `BackgroundSoundRepository()` als Default-Parameter. Das erschwert Testing und weicht vom DI-Pattern ab, das im Rest der App verwendet wird.

Gefunden im Clean Architecture Review (shared-024).

---

## Akzeptanzkriterien

### Feature
- [ ] SettingsView erhält alle Dependencies via Konstruktor
- [ ] Keine internen Service-Instantiierungen in der View
- [ ] Bestehende Funktionalität bleibt erhalten
- [ ] Preview-Funktionalität bleibt erhalten

### Tests
- [ ] Bestehende Tests bleiben grün

### Dokumentation
- [ ] Keine (interne Refaktorierung)

---

## Manueller Test

1. Settings öffnen
2. Gong-Sound ändern → Preview abspielen
3. Background-Sound ändern → Preview abspielen
4. Erwartung: Previews funktionieren wie bisher

---

## Referenz

- Review-Ticket: shared-024 (Clean Architecture Layer-Review)
- DI-Architektur: shared-007

---

## Hinweise

Die Preview-Funktionalität erfordert Default-Werte - diese können über Extension oder Factory bereitgestellt werden, um die Previews nicht zu brechen.
