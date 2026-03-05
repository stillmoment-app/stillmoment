# Ticket shared-074: Einheitliche Audio-Resolver fuer Einstimmung und Klangatmosphaere

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: iOS ~4h | Android ~4h
**Phase**: 2-Architektur

---

## Was

Built-in und importierte Audio-Dateien (Einstimmungen und Klangatmosphaeren) sollen fuer alle Konsumenten transparent aufloesbarsein — unabhaengig davon, ob die ID auf einen Katalog-Eintrag oder eine importierte Datei zeigt.

## Warum

Aktuell muss jeder Konsument (Timer, Reducer, Pill-Anzeige, Playback-Service) selbst wissen, dass eine Audio-ID entweder ein Katalog-Eintrag oder eine UUID aus dem Custom-Audio-Repository sein kann. Das fuehrt zu wiederkehrenden Bugs:

- **Timer-Reducer** prueft nur den Built-in-Katalog → custom Einstimmungen werden nicht abgespielt
- **Pill-Anzeige** prueft nur den Built-in-Katalog → custom Einstimmungen nicht angezeigt
- **Dieselbe Gefahr besteht bei Klangatmosphaeren** — dort ist der Lookup zwar aktuell verdrahtet, aber die duale Logik ist ueber mehrere Schichten dupliziert

Jede neue Stelle, die eine Audio-ID aufloesen muss, kann denselben Bug einfuehren.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] Ein `AttunementResolver` loest jede Einstimmungs-ID transparent auf — egal ob built-in oder importiert
- [ ] Ein `SoundscapeResolver` loest jede Klangatmosphaeren-ID transparent auf — egal ob built-in oder importiert
- [ ] Der Timer-Reducer entscheidet korrekt, ob eine Einstimmung abgespielt wird (built-in UND custom)
- [ ] Die Konfigurationspills zeigen den korrekten Namen fuer built-in UND custom Einstimmungen
- [ ] Die Konfigurationspills zeigen den korrekten Namen fuer built-in UND custom Klangatmosphaeren
- [ ] Playback funktioniert fuer beide Quellen identisch (kein stilles Fehlschlagen)
- [ ] Kein Konsument prueft mehr direkt `Introduction.find()`, `Introduction.isAvailableForCurrentLanguage()` oder `SoundCatalog.findById()` — alle gehen ueber den Resolver

### Tests

- [ ] Unit Tests iOS: Resolver loest built-in und custom IDs korrekt auf
- [ ] Unit Tests Android: Resolver loest built-in und custom IDs korrekt auf
- [ ] Regressionstests: Custom Einstimmung wird abgespielt und als Pill angezeigt
- [ ] Regressionstests: Custom Klangatmosphaere wird abgespielt und als Pill angezeigt

### Dokumentation

- [ ] CHANGELOG.md (Bug Fix: Custom Audio korrekt aufgeloest)
- [ ] GLOSSARY.md: AttunementResolver, SoundscapeResolver

---

## Manueller Test

### Einstimmung
1. Eigene MP3 als Einstimmung importieren
2. Im Praxis-Editor auswaehlen und aktivieren
3. Zurueck zum Timer
4. Erwartung: Einstimmungs-Pill zeigt den Dateinamen, Mindestdauer passt sich an
5. Timer starten
6. Erwartung: Einstimmung wird nach dem Start-Gong abgespielt, danach Background-Audio

### Klangatmosphaere
1. Eigene MP3 als Klangatmosphaere importieren
2. Im Praxis-Editor auswaehlen
3. Zurueck zum Timer
4. Erwartung: Klangatmosphaeren-Pill zeigt den Dateinamen
5. Timer starten
6. Erwartung: Klangatmosphaere wird waehrend der Meditation abgespielt

---

## Hinweise

- iOS hat das Playback-Problem im Reducer (`hasActiveIntroduction` prueft nur Built-in), umgeht es aber durch separaten Playback-Code im ViewModel. Der Reducer-Bug existiert aber auch dort.
- Die Resolver-Protokolle gehoeren in den Domain-Layer, die Implementierung (mit Katalog + CustomAudioRepository) in den Infrastructure-Layer.
- Bestehende `Introduction.isAvailableForCurrentLanguage()` Aufrufe im Reducer muessen durch den Resolver ersetzt werden.
- `customIntroDurationSeconds` als separates Feld in MeditationSettings koennte durch den Resolver obsolet werden (Resolver liefert Duration direkt mit).

---
