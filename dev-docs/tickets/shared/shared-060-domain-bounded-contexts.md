# Ticket shared-060: Domain-Layer nach Bounded Contexts strukturieren

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~4h | Android ~4h
**Phase**: 2-Architektur

---

## Was

Die Domain-Layer beider Plattformen sollen nach fachlichen Bounded Contexts statt nach technischen Kategorien (Models/, Services/) organisiert werden. Zusaetzlich erhaelt jede Domain-Datei einen einzeiligen Docstring der ihren Zweck beschreibt.

## Warum

Domain/Models/ enthaelt 17 (iOS) bzw. 19 (Android) Dateien ohne erkennbare fachliche Zuordnung. Um herauszufinden welche Dateien zu einem Feature gehoeren, muessen mehrere Dateien geoeffnet und gelesen werden. Bei einer Struktur nach Bounded Contexts ist die Zuordnung sofort am Dateipfad erkennbar - die Verzeichnisstruktur dokumentiert sich selbst und veraltet nicht.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Identifizierte Bounded Contexts

Analyse der bestehenden 29 iOS-Dateien (17 Models + 12 Services) und 34 Android-Dateien (19 Models + 4 Repositories + 11 Services):

### 1. Timer (groesster Kontext)

State Machine, Reducer, Actions/Effects und alle zugehoerigen Konfigurationstypen.

| Datei (iOS) | Datei (Android) | Zweck |
|-------------|-----------------|-------|
| MeditationTimer.swift | MeditationTimer.kt | Session-Modell mit Dauer und Einstellungen |
| TimerState.swift | TimerState.kt | State Machine: idle → preparation → running → completed |
| TimerAction.swift | TimerAction.kt | Dispatchbare Actions an den Reducer |
| TimerEffect.swift | TimerEffect.kt | Side Effects die der Reducer produziert |
| TimerDisplayState.swift | TimerDisplayState.kt | UI-State abgeleitet aus TimerState |
| TimerReducer.swift | TimerReducer.kt | Pure Reducer fuer Timer State Management |
| MeditationSettings.swift | MeditationSettings.kt | Persistierbare Timer-Konfiguration |
| PreparationCountdown.swift | PreparationCountdown.kt | Countdown vor der Meditation |
| Introduction.swift | Introduction.kt | Optionale Einleitungs-Audio |
| IntervalMode.swift | IntervalMode.kt | Modus fuer Intervall-Gongs |
| TimerServiceProtocol.swift | — | Timer-Service Interface |
| TimerSettingsRepository.swift | TimerRepository.kt | Persistenz Timer-Einstellungen |
| ClockProtocol.swift | ProgressSchedulerProtocol.kt | Timer-Abstraktion fuer Testbarkeit |

### 2. GuidedMeditations

Import, Verwaltung und Wiedergabe gefuehrter Meditationen.

| Datei (iOS) | Datei (Android) | Zweck |
|-------------|-----------------|-------|
| GuidedMeditation.swift | GuidedMeditation.kt | Audio-Datei mit Metadaten |
| GuidedMeditationSettings.swift | GuidedMeditationSettings.kt | Wiedergabe-Einstellungen |
| EditSheetState.swift | EditSheetState.kt | Validierung beim Bearbeiten von Metadaten |
| AudioMetadata.swift | — | Aus MP3-ID3-Tags extrahierte Metadaten |
| GuidedMeditationServiceProtocol.swift | GuidedMeditationRepository.kt | Verwaltungs-Interface |
| GuidedSettingsRepository.swift | GuidedMeditationSettingsRepository.kt | Persistenz Einstellungen |
| — | GuidedMeditationGroup.kt | Gruppierung nach Lehrer (Android-only) |

### 3. Audio

Audio-Wiedergabe, Session-Koordination, Sound-Assets.

| Datei (iOS) | Datei (Android) | Zweck |
|-------------|-----------------|-------|
| BackgroundSound.swift | — | Ambient-Sound-Optionen |
| GongSound.swift | GongSound.kt | Start/Ende-Gong Konfiguration |
| AudioServiceProtocol.swift | AudioServiceProtocol.kt | Audio-Wiedergabe Interface |
| AudioPlayerServiceProtocol.swift | AudioPlayerServiceProtocol.kt | Player-Steuerung + PlaybackState |
| AudioSessionCoordinatorProtocol.swift | AudioSessionCoordinatorProtocol.kt | Zentrales Audio-Session Management |
| BackgroundSoundRepositoryProtocol.swift | — | Laden der Background-Sounds |
| NowPlayingInfoProvider.swift | — | Lock Screen / Control Center Info |
| AudioMetadataServiceProtocol.swift | — | ID3-Tag Extraktion Interface |
| — | AudioFocusManagerProtocol.kt | Audio Focus Callbacks (Android-only) |
| — | MediaPlayerProtocol.kt | MediaPlayer Abstraktion (Android-only) |
| — | MediaPlayerFactoryProtocol.kt | MediaPlayer Factory (Android-only) |
| — | VolumeAnimatorProtocol.kt | Lautstaerke-Animation (Android-only) |
| — | AudioSource.kt | Audio-Quellen Enum (Android-only, iOS nested) |

### 4. Appearance

Theme-Auswahl und Darstellungsmodus.

| Datei (iOS) | Datei (Android) | Zweck |
|-------------|-----------------|-------|
| AppearanceMode.swift | AppearanceMode.kt | System/Light/Dark Auswahl |
| ColorTheme.swift | ColorTheme.kt | Farbschema-Auswahl |
| — | SettingsRepository.kt | Persistenz aller Settings (Android-only) |

### 5. Platform (plattform-spezifische Domain-Typen)

Typen die nur auf einer Plattform existieren und keinem fachlichen Kontext angehoeren.

| Datei | Plattform | Zweck |
|-------|-----------|-------|
| AppTab.kt | Android | Tab-Navigation Enum |
| FileOpenError.kt | Android | Fehlertypen beim Datei-Oeffnen |
| LoggerProtocol.kt | Android | Logging-Abstraktion |
| TimerForegroundServiceProtocol.kt | Android | Foreground Service Interface |

---

## Zielstruktur

```
Domain/
  Timer/
    MeditationTimer.swift/.kt
    TimerState.swift/.kt
    TimerAction.swift/.kt
    TimerEffect.swift/.kt
    TimerDisplayState.swift/.kt
    TimerReducer.swift/.kt
    MeditationSettings.swift/.kt
    PreparationCountdown.swift/.kt
    Introduction.swift/.kt
    IntervalMode.swift/.kt
    TimerServiceProtocol.swift          (iOS only)
    TimerSettingsRepository.swift/.kt
    ClockProtocol.swift                 (iOS only)
    ProgressSchedulerProtocol.kt        (Android only)
  GuidedMeditations/
    GuidedMeditation.swift/.kt
    GuidedMeditationSettings.swift/.kt
    EditSheetState.swift/.kt
    AudioMetadata.swift                 (iOS only)
    GuidedMeditationServiceProtocol.swift / GuidedMeditationRepository.kt
    GuidedSettingsRepository.swift/.kt
    GuidedMeditationGroup.kt           (Android only)
  Audio/
    BackgroundSound.swift               (iOS only)
    GongSound.swift/.kt
    AudioServiceProtocol.swift/.kt
    AudioPlayerServiceProtocol.swift/.kt
    AudioSessionCoordinatorProtocol.swift/.kt
    BackgroundSoundRepositoryProtocol.swift  (iOS only)
    NowPlayingInfoProvider.swift        (iOS only)
    AudioMetadataServiceProtocol.swift  (iOS only)
    AudioFocusManagerProtocol.kt        (Android only)
    MediaPlayerProtocol.kt              (Android only)
    MediaPlayerFactoryProtocol.kt       (Android only)
    VolumeAnimatorProtocol.kt           (Android only)
    AudioSource.kt                      (Android only)
  Appearance/
    AppearanceMode.swift/.kt
    ColorTheme.swift/.kt
    SettingsRepository.kt               (Android only)
  Platform/                             (Android only)
    AppTab.kt
    FileOpenError.kt
    LoggerProtocol.kt
    TimerForegroundServiceProtocol.kt
```

---

## Offene Entscheidungen

1. **BackgroundSound nur iOS?** - Pruefen ob Android das Modell anders abbildet oder ob es fehlt
2. **AudioSource nested vs. standalone** - iOS hat AudioSource innerhalb AudioSessionCoordinatorProtocol. Soll es wie auf Android eine eigene Datei werden?
3. **Platform-Kontext noetig?** - Oder plattform-spezifische Typen direkt im fachlich passenden Kontext belassen (z.B. TimerForegroundServiceProtocol → Timer/)
4. **Repositories-Package (Android)** - Android hat ein separates `repositories/` Package. In Bounded Contexts aufloesen oder als Subpackage beibehalten?

---

## CLAUDE.md Update (Pflicht)

Nach Abschluss muessen folgende Dateien eine "Domain Bounded Contexts"-Sektion erhalten:

**Root CLAUDE.md** - Unter "Architecture Principles":
```
Domain Bounded Contexts (identisch auf beiden Plattformen):
- Timer: State Machine, Reducer, Session-Modell, Intervalle, Vorbereitung
- GuidedMeditations: Import, Metadaten, Wiedergabe-Einstellungen
- Audio: Wiedergabe, Session-Koordination, Sound-Assets
- Appearance: Theme, Dark Mode
```

**ios/CLAUDE.md + android/CLAUDE.md** - Unter "Project Structure":
```
Domain/
  Timer/         → State Machine, Reducer, alle Timer-bezogenen Modelle
  GuidedMeditations/ → Import, Metadaten, Mediathek
  Audio/         → Playback, Session-Koordination, Sounds
  Appearance/    → Theme, Dark Mode
```

Dies stellt sicher, dass AI-Assistenten bei jeder neuen Konversation sofort wissen welche Dateien zu welchem Feature gehoeren - ohne Dateien oeffnen zu muessen.

---

## Akzeptanzkriterien

### Struktur (beide Plattformen)

- [ ] Domain-Dateien sind nach den identifizierten Bounded Contexts gruppiert
- [ ] Jede Domain-Datei hat einen einzeiligen Docstring am Anfang der den Zweck beschreibt
- [ ] Die Bounded-Context-Verzeichnisnamen sind auf beiden Plattformen identisch
- [ ] Kein Dateipaar gehoert zu zwei verschiedenen Kontexten (klare Zuordnung)
- [ ] Offene Entscheidungen (s.o.) sind geloest und dokumentiert

### Dokumentation

- [ ] CLAUDE.md (Root + beide Plattformen) dokumentiert die Bounded Contexts
- [ ] dev-docs/architecture/overview.md spiegelt die neue Struktur wider
- [ ] dev-docs/reference/glossary.md enthaelt Bounded-Context-Definitionen

### Tests

- [ ] Alle bestehenden Tests laufen nach der Umstrukturierung (iOS + Android)
- [ ] Keine funktionalen Aenderungen - reines Refactoring

---

## Manueller Test

1. `make test-unit` in ios/ - alle Tests gruen
2. `make test` in android/ - alle Tests gruen
3. Stichprobe: Eine Datei aus jedem Bounded Context oeffnen, Docstring pruefen
4. Erwartung: Identische Bounded-Context-Struktur auf beiden Plattformen

---

## Hinweise

- Auf iOS muessen Xcode-Gruppen mit dem Dateisystem synchron bleiben (pbxproj aktualisieren)
- **Erst nach Abschluss der Refactoring-Kette (shared-054 bis shared-059) umsetzen.** Die Refactoring-Tickets aendern Domain-Dateien im Timer-Kontext — parallele Arbeit erzeugt unnoetige Merge-Konflikte
- Test-Dateien muessen ggf. ihre Imports anpassen (Package-Pfade aendern sich auf Android)
- iOS: Swift-Imports aendern sich nicht (flacher Namespace), aber Xcode-Gruppen muessen stimmen
