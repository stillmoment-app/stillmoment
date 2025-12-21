# Ticket ios-023: Screenshot Test-Fixtures für Guided Meditations

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Ein separates Xcode Target "StillMoment-Screenshots" erstellen, das beim Start automatisch 5 Test-Meditations in der Library hat - mit funktionierendem Playback.

## Warum

Der aktuelle Screenshot-Prozess erfordert manuelle MP3-Imports, damit die Library nicht leer ist. Fuer automatisierte Screenshots brauchen wir vorinstallierte Test-Meditations mit realistischen Daten.

---

## Akzeptanzkriterien

- [x] Xcode Target `StillMoment-Screenshots` existiert (via Ruby-Skript)
- [x] 5 Test-MP3s im Bundle (nur Screenshots-Target, nicht im Release)
- [x] Library zeigt beim Start 5 Meditations (gruppiert nach 3 Lehrern)
- [x] Player spielt Test-Meditations ab (Playback funktioniert)
- [x] Haupt-Target (StillMoment) ist unverändert - keine Test-Fixtures
- [x] Release-Build enthält keine Test-Dateien
- [x] Pre-commit Hook synchronisiert Targets automatisch
- [x] Build und manueller Test erfolgreich

---

## Manueller Test

1. `StillMoment-Screenshots` Target auf Simulator starten
2. Library Tab oeffnen
3. Erwartung: 5 Meditations sichtbar, gruppiert nach 3 Lehrern
4. Eine Meditation auswaehlen → Player oeffnet sich
5. Play druecken → Playback startet (Stille, aber Progress-Bar laeuft)
6. `StillMoment` (Haupt-Target) starten → Library ist leer

---

## Referenz

- `ios/StillMoment/Application/ViewModels/GuidedMeditationPlayerViewModel.swift` - URL-Aufloesung (Bundle-Check)
- `ios/StillMoment/StillMomentApp.swift` - Seeding-Aufruf (`#if SCREENSHOTS_BUILD`)
- `ios/StillMoment-Screenshots/TestFixtureSeeder.swift` - Seeding-Logik
- `ios/StillMoment-Screenshots/Resources/TestFixtures/*.mp3` - Test-MP3s
- `ios/scripts/create-screenshots-target.rb` - Target-Erstellung
- `ios/scripts/sync-screenshots-target.rb` - Target-Synchronisation
- `.pre-commit-config.yaml` - Pre-commit Hook Konfiguration

---

## Hinweise

### Separates Target (nicht Build Configuration)

- Klare Trennung: Screenshots-Target hat Fixtures, Haupt-Target nicht
- Kein Launch Argument noetig - Target selbst ist der Trigger
- Versehentlicher Release mit Test-Daten unmoeglich
- Wartung: Bei neuen Dateien Target Membership pruefen

### Ordnerstruktur

```
ios/
├── StillMoment/                    # Main target (shared)
├── StillMoment-Screenshots/        # Screenshots-only files
│   ├── TestFixtureSeeder.swift     # Seeds library on first launch
│   └── Resources/
│       └── TestFixtures/           # 5 silent test MP3s
└── StillMoment.xcodeproj
```

- Dateien in `StillMoment-Screenshots/` nur im Screenshots-Target
- Dateien in `StillMoment/` in BEIDEN Targets
- Pre-commit Hook haelt Targets synchron

### Bundle-Ressourcen

- MP3s im Screenshots-Target Bundle (StillMoment-Screenshots/Resources/TestFixtures/)
- Dateien sind automatisch bei App-Installation dabei
- Bookmarks fuer Bundle-URLs erstellen (funktioniert)

### Security-Scoped Access Anpassung

- `startAccessingSecurityScopedResource()` gibt `false` fuer Bundle-URLs zurueck
- Loesung: Pruefen ob URL im Bundle liegt, dann Skip Security-Check
- Das ist kein Test-Hack sondern korrektes URL-Handling (auch fuer Documents-Ordner nuetzlich)

### Test-Fixtures

| Lehrer | Meditation | Laenge |
|--------|------------|--------|
| Sarah Kornfield | Mindful Breathing | 7:33 |
| Sarah Kornfield | Body Scan for Beginners | 15:42 |
| Tara Goldstein | Loving Kindness | 12:17 |
| Tara Goldstein | Evening Wind Down | 19:05 |
| Jon Salzberg | Present Moment Awareness | 25:48 |

- Lehrer-Namen: Kombinationen bekannter Meditations-Lehrer
- MP3s: Stille mit realistischer Laenge, minimale Dateigroesse (~8kbps mono)
- Generieren mit ffmpeg: `ffmpeg -f lavfi -i anullsrc=r=22050:cl=mono -t {sekunden} -b:a 8k {name}.mp3`

### Compiler Flag

- `SCREENSHOTS_BUILD=1` im Screenshots-Target setzen
- Seeding-Code mit `#if SCREENSHOTS_BUILD` wrappen

### Automation Scripts

| Script | Zweck |
|--------|-------|
| `ios/scripts/create-screenshots-target.rb` | Erstellt Target (einmalig, xcodeproj gem) |
| `ios/scripts/sync-screenshots-target.rb` | Synchronisiert Dateien zwischen Targets |

Pre-commit Hook in `.pre-commit-config.yaml`:
- Trigger: Aenderungen an `ios/StillMoment/**/*.swift`
- Aktion: Fuehrt `sync-screenshots-target.rb` aus
- Ergebnis: Screenshots-Target hat alle Source Files vom Main-Target

---

<!--
Dieses Ticket enthaelt bewusst mehr Implementierungshinweise als ueblich,
da die Loesungsansaetze in einer ausfuehrlichen Analyse erarbeitet wurden.
-->
