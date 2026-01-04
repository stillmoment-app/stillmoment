# Ticket ios-028: Intervall-Gong spielt nur einmal

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 1-Quick Fix

---

## Was

Bei aktivierten Intervall-Gongs spielt waehrend der Meditation nur der erste Gong. Weitere Intervall-Gongs werden nicht ausgeloest.

## Warum

User erwartet regelmaessige akustische Orientierung waehrend der Meditation. Ohne wiederholte Gongs fehlt diese Orientierung nach dem ersten Intervall.

---

## Akzeptanzkriterien

- [x] Roter Test: Test schlaegt fehl bei aktuellem Code
- [x] Fix: Intervall-Gong-Zyklus vollstaendig implementiert (siehe DDD_GUIDE.md)
- [x] Gruener Test: Test ist gruen nach dem Fix
- [x] Android-Verhalten als Referenz (funktioniert korrekt)

---

## Manueller Test

1. Timer-Einstellungen: 10 Minuten, Intervall-Gongs aktiviert (3 Min)
2. Timer starten
3. Erwartung: Start-Gong, Intervall bei 3 Min, Intervall bei 6 Min, Intervall bei 9 Min, End-Gong

---

## Referenz

- Dokumentation: `dev-docs/DDD_GUIDE.md` (Abschnitt "Intervall-Gong-Zyklus")
- Android-Implementierung funktioniert korrekt als Referenz

---

## Hinweise

Der Intervall-Gong-Zyklus erfordert zwei State-Tracking-Mechanismen die beide korrekt zurueckgesetzt werden muessen. Details siehe DDD_GUIDE.md.
