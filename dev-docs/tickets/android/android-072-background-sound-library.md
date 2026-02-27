# Ticket android-072: Background Sound Library erweitern

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Gross
**Abhaengigkeiten**: android-070 (Sound-Lokalisierung aus Domain) — empfohlen, nicht blockierend
**Phase**: 2-Features

---

## Was

Die Background-Sound-Bibliothek von aktuell 2 Optionen (Stille, Wald) auf dieselbe Anzahl wie iOS erweitern. Gleichzeitig wird die Architektur auf ein datengetriebenes Muster umgestellt: Android liest Sounds aus einer `sounds.json` (analog zu iOS), statt sie im `companion object` von `BackgroundSound.kt` hartzucodieren.

## Warum

iOS und Android haben aktuell dieselben 2 Sounds — aber beide Plattformen sollen erweitert werden. Das `companion object`-Muster mischt Daten mit Logik und macht das Hinzufügen neuer Sounds zu einer Code-Änderung statt einer Daten-Änderung. Ein JSON-basierter Katalog ist wartbarer, konform mit iOS, und skaliert ohne Kotlin-Änderungen.

---

## Akzeptanzkriterien

### Architektur
- [x] `sounds.json` im Android-Assets-Verzeichnis als Single Source of Truth für den Sound-Katalog
- [x] `BackgroundSound.kt` companion object (`allSounds`, `nameEnglish`, `nameGerman`) entfernt — Daten kommen aus JSON
- [x] JSON-Struktur identisch zu iOS (`id`, `filename`, `name.en`, `name.de`, `description.en`, `description.de`, `volume`)
- [x] Gleiche Sound-IDs wie iOS (Kompatibilität mit gespeicherten Einstellungen)

### Feature
- [x] Mindestens dieselben Sounds wie iOS verfuegbar (Sounddateien aus iOS-Bundle uebernehmen oder neu beschaffen)
- [x] Background-Sound-Dropdown zeigt alle verfuegbaren Sounds
- [x] Ausgewaehlter Sound mit korrekter Datei verknuepft
- [x] 3-Sekunden-Preview funktioniert fuer alle neuen Sounds
- [x] Fade-in (10s) beim Meditationsstart funktioniert fuer alle neuen Sounds

### Tests
- [x] Unit-Test: Sound-Katalog hat mehr als 2 Eintraege
- [x] Unit-Test: JSON wird korrekt geparst (alle Pflichtfelder vorhanden)
- [x] `make test` gruen

### Dokumentation
- [x] `android/CLAUDE.md` hat keinen Abschnitt mehr, der das alte companion-object-Muster beschreibt (bereits erledigt)

---

## Manueller Test

1. Settings oeffnen, Hintergrund-Sektion
2. Dropdown oeffnen
3. Erwartung: Mindestens 5 Sounds sichtbar (inkl. Stille)
4. Jeden Sound per Preview-Button testen
5. Meditation mit neuem Sound starten: Fade-in und Wiedergabe korrekt

---

## Referenz

- iOS JSON-Struktur: `ios/StillMoment/Resources/BackgroundAudio/sounds.json`
- iOS Audio-Dateien: `ios/StillMoment/Resources/BackgroundAudio/`
- Android Domain-Modell: `android/.../domain/models/BackgroundSound.kt`
- Android UI: `android/.../ui/timer/SettingsSheet.kt` — `BackgroundSoundSection`
