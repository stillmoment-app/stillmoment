# Ticket shared-084: Meditationen-Tab als erster Tab

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Niedrig — Tab-Reihenfolge tauschen + Default-Tab beim ersten Start. Last-used-Persistenz (shared-002) muss erhalten bleiben.
**Phase**: 4-Polish

---

## Was

Der Meditationen-Tab steht an erster Stelle der Tab-Bar (Position 1), der Timer-Tab an zweiter. Beim allerersten App-Start landet der User auf dem Meditationen-Tab. Bei jedem weiteren Start gilt weiterhin der zuletzt gewaehlte Tab (siehe shared-002).

## Warum

Das Aufbauen einer eigenen Meditations-Bibliothek ist das Kernfeature der App; der Timer ist Add-on. Tab 1 ist der "das ist die App"-Slot und gehoert dem Kernfeature. Die App Store Description sortiert "GEFUEHRTE MEDITATIONEN" bereits vor "FREIE MEDITATION" — die App-IA soll das spiegeln. Der Empty State der Meditationen-Liste mit Import-Anleitungen (shared-039/039b) holt neue User beim ersten Start passend ab.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-002    |
| Android   | [ ]    | shared-002    |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Tab-Reihenfolge in der Tab-Bar: Meditationen, Timer, Einstellungen (von links nach rechts)
- [ ] Beim allerersten App-Start ist der Meditationen-Tab aktiv
- [ ] Bei spaeteren App-Starts ist der zuletzt verwendete Tab aktiv (shared-002 bleibt gueltig)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS (erste-Launch Default + Last-used-Wiederherstellung)
- [ ] Unit Tests Android (erste-Launch Default + Last-used-Wiederherstellung)

### Dokumentation
- [ ] CHANGELOG.md (user-sichtbare Aenderung)

---

## Manueller Test

1. App frisch installieren / App-Daten loeschen
2. App starten → Erwartung: Meditationen-Tab ist aktiv
3. Auf Timer-Tab wechseln, App schliessen, App neu oeffnen
4. Erwartung: Timer-Tab ist aktiv (last-used bleibt erhalten)
5. Auf Einstellungen-Tab wechseln, App schliessen, App neu oeffnen
6. Erwartung: Einstellungen-Tab ist aktiv

---

## Referenz

- iOS: Tab-Konfiguration in der Root-App-Struktur
- Android: Tab-Konfiguration im Bottom-Nav / NavHost
- shared-002 (Letzten Tab merken) — Persistenz-Mechanismus existiert bereits
- shared-061 (3-Tab-Navigation) — bestehende Tab-Architektur
- shared-071 (Tab Bibliothek → Meditationen) — aktueller Tab-Name

---

## Hinweise

- Folge-Ticket fuer Marketing-Material (App-Store-Screenshots, Website-FAQ): shared-085
- Onboarding-Texte oder Walkthroughs sind nicht betroffen — der Empty State der Meditationen-Liste uebernimmt diese Rolle
