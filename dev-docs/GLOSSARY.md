# Domain Glossar

<!--
CLAUDE-OPTIMIZED: Strukturiert fuer schnelles AI-Nachschlagen
- Quick Reference fuer Uebersicht
- Detailsektionen nach Domain gruppiert (aus User-Perspektive)
- Jeder Eintrag mit Cross-Platform Dateireferenzen

Last Updated: 2026-01-07
-->

## Quick Reference

| Begriff | Typ | Domain | Beschreibung |
|---------|-----|--------|--------------|
| `AudioMetadata` | Value Object | Guided Meditations | Metadaten aus Audio-Dateien (ID3 Tags) |
| `BackgroundSound` | Value Object | Timer | Hintergrundgeraeusch (Beiwerk zum Timer) |
| `EditSheetState` | Value Object | Guided Meditations | Zustand und Validierung beim Editieren |
| `GuidedMeditation` | Entity | Guided Meditations | Gefuehrte Meditation (Audio ist Hauptfeature) |
| `LocalizedString` | Value Object | Timer | Lokalisierter String fuer BackgroundSound |
| `MeditationSettings` | Value Object | Timer | Benutzereinstellungen |
| `MeditationTimer` | Value Object | Timer | Zentrales Timer-Modell |
| `TimerAction` | Enum | Timer | Benutzer-Aktionen und System-Events |
| `TimerDisplayState` | Value Object | Timer | Aggregierter UI-Zustand |
| `TimerEffect` | Enum | Timer | Side Effects des Reducers |
| `TimerState` | Enum | Timer | Zustandsautomat (Idle/Running/etc.) |

---

## Timer Domain

Die Timer Domain ist der Kern der Applikation. Der Timer ist das Hauptfeature, Hintergrund-Sounds sind optionales Beiwerk.

### TimerState

**Typ:** Enum
**Pattern:** State Machine

**Werte:**

| Wert | Beschreibung |
|------|--------------|
| `idle` | Timer bereit zum Start |
| `preparation` | Vorbereitungsphase vor Meditation (konfigurierbar) |
| `running` | Timer laeuft, Meditation aktiv |
| `paused` | Timer pausiert, kann fortgesetzt werden |
| `completed` | Timer abgelaufen, Meditation beendet |

**State Machine:**

```
idle --> preparation --> running --> completed
  |                        ^  |  ^
  |                        |  v  |
  +------------------------+ paused

Pfade:
- Mit Vorbereitung: idle → preparation → running
- Ohne Vorbereitung: idle → running (direkt)
- Start-Gong spielt bei BEIDEN Pfaden beim Übergang zu running
```

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerState.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerState.kt`

---

### TimerAction

**Typ:** Enum
**Pattern:** Command/Event

**Benutzer-Aktionen (Verb + Pressed):**

| Action | Beschreibung |
|--------|--------------|
| `selectDuration(minutes:)` | Dauer gewaehlt |
| `startPressed` | Start-Button gedrueckt |
| `pausePressed` | Pause-Button gedrueckt |
| `resumePressed` | Fortsetzen-Button gedrueckt |
| `resetPressed` | Reset-Button gedrueckt |

**System-Events (Verb + Past Participle):**

| Event | Beschreibung |
|-------|--------------|
| `tick(...)` | Timer-Tick mit aktualisierten Werten |
| `preparationFinished` | Vorbereitung abgeschlossen |
| `timerCompleted` | Timer bei 0 angekommen |
| `intervalGongTriggered` | Intervall-Gong soll spielen |
| `intervalGongPlayed` | Intervall-Gong wurde gespielt |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerAction.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerAction.kt`

**Siehe auch:** TimerReducer (Pattern in DDD_GUIDE.md)

---

### TimerEffect

**Typ:** Enum
**Pattern:** Effect (Side Effects)

**Kategorien:**

| Kategorie | Effects |
|-----------|---------|
| Audio Session | `configureAudioSession` |
| Background Audio | `startBackgroundAudio(soundId:)`, `stopBackgroundAudio`, `pauseBackgroundAudio`, `resumeBackgroundAudio` |
| Sound Effects | `playStartGong`, `playIntervalGong`, `playCompletionSound` |
| Timer Service | `startTimer(durationMinutes:)`, `pauseTimer`, `resumeTimer`, `resetTimer` |
| Persistence | `saveSettings(MeditationSettings)` |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerEffect.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerEffect.kt`

**Pattern-Dokumentation:** `dev-docs/DDD_GUIDE.md` (Effect Pattern)

---

### MeditationTimer

**Typ:** Value Object (immutabel)
**Pattern:** Value Object mit Domain Logic

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `durationMinutes` | Int | Gesamtdauer (1-60) |
| `remainingSeconds` | Int | Verbleibende Zeit |
| `state` | TimerState | Aktueller Zustand |
| `remainingPreparationSeconds` | Int | Verbleibende Vorbereitungszeit |
| `preparationTimeSeconds` | Int | Konfigurierte Vorbereitungszeit |
| `lastIntervalGongAt` | Int? | Zeitpunkt letzter Gong |

**Computed Properties:**

| Property | Beschreibung |
|----------|--------------|
| `totalSeconds` | Gesamtdauer in Sekunden |
| `progress` | Fortschritt 0.0-1.0 |
| `isCompleted` | Timer abgelaufen? |

**Methoden:**

| Methode | Beschreibung |
|---------|--------------|
| `tick()` | Neue Instanz mit Zeit-1 |
| `withState(_:)` | Neue Instanz mit neuem State |
| `startPreparation()` | Neue Instanz im Vorbereitungsmodus |
| `markIntervalGongPlayed()` | Neue Instanz mit Gong-Marker |
| `shouldPlayIntervalGong(intervalMinutes:)` | Prueft ob Gong faellig |
| `reset()` | Zurueckgesetzter Timer |

**Invarianten:**
- durationMinutes: 1...60
- remainingSeconds: 0...totalSeconds
- Alle Aenderungen erzeugen neue Instanzen (immutabel)

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/MeditationTimer.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/MeditationTimer.kt`

---

### TimerDisplayState

**Typ:** Value Object
**Pattern:** Aggregated View State

**Beschreibung:**
Aggregiert alle UI-relevanten Daten fuer die Timer-Ansicht. Enthaelt computed properties fuer UI-Logik.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `timerState` | TimerState | Aktueller Zustand |
| `selectedMinutes` | Int | Gewaehlte Dauer |
| `remainingSeconds` | Int | Verbleibende Zeit |
| `totalSeconds` | Int | Gesamtzeit |
| `remainingPreparationSeconds` | Int | Verbleibende Vorbereitungszeit |
| `progress` | Double | Fortschritt 0.0-1.0 |
| `currentAffirmationIndex` | Int | Aktuelle Affirmation |
| `intervalGongPlayedForCurrentInterval` | Bool | Gong bereits gespielt? |

**Computed Properties:**

| Property | Beschreibung |
|----------|--------------|
| `isPreparation` | In Vorbereitung? |
| `canStart` | Start moeglich? |
| `canPause` | Pause moeglich? |
| `canResume` | Fortsetzen moeglich? |
| `formattedTime` | Formatierte Anzeige (MM:SS) |

**Factory:**
- `TimerDisplayState.initial` - Startzustand
- `TimerDisplayState.withDuration(minutes:)` - Mit gespeicherter Dauer

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerDisplayState.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerDisplayState.kt`

---

### MeditationSettings

**Typ:** Value Object
**Pattern:** Configuration Object

**Properties:**

| Property | Typ | Default | Beschreibung |
|----------|-----|---------|--------------|
| `intervalGongsEnabled` | Bool | false | Intervall-Gongs aktiviert? |
| `intervalMinutes` | Int | 5 | Intervall in Minuten (3, 5, 10) |
| `backgroundSoundId` | String | "silent" | Hintergrund-Sound ID |
| `durationMinutes` | Int | 10 | Zuletzt gewaehlte Dauer |
| `preparationTimeEnabled` | Bool | true | Vorbereitungszeit aktiviert? |
| `preparationTimeSeconds` | Int | 15 | Vorbereitungszeit in Sekunden (5, 10, 15, 20, 30, 45) |

**Validierung:**
- `validateInterval(_:)` - Clamps zu 3, 5 oder 10
- `validateDuration(_:)` - Clamps zu 1-60
- `validatePreparationTime(_:)` - Clamps zu naechstem gueltigen Wert (5, 10, 15, 20, 30, 45)

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/MeditationSettings.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/MeditationSettings.kt`

---

### BackgroundSound

**Typ:** Value Object
**Pattern:** Localized Content

**Beschreibung:**
Optionales Hintergrundgeraeusch waehrend der Timer-Meditation. Beiwerk zum Timer, kein eigenstaendiges Feature.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `id` | String | Eindeutige ID |
| `filename` | String | Audio-Dateiname |
| `name` | LocalizedString | Lokalisierter Name (DE/EN) |
| `description` | LocalizedString | Lokalisierte Beschreibung |
| `iconName` | String | SF Symbol Name |
| `volume` | Float | Lautstaerke (0.0-1.0) |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/BackgroundSound.swift`
- Android: via `sounds.json`

**Siehe auch:** `LocalizedString`, `MeditationSettings.backgroundSoundId`

---

### LocalizedString

**Typ:** Value Object
**Pattern:** Nested Value Object

**Beschreibung:**
Lokalisierter String fuer BackgroundSound Namen und Beschreibungen.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `de` | String | Deutscher Text |
| `en` | String | Englischer Text |

**Datei-Referenzen:**
- iOS: nested in `BackgroundSound.swift`
- Android: nested in `sounds.json` Schema

---

## Guided Meditations Domain

Eigenstaendiges Feature zum Abspielen von Audio-Dateien. Das Audio ist hier das Hauptfeature, nicht Beiwerk.

### GuidedMeditation

**Typ:** Entity (hat ID)
**Pattern:** Rich Domain Model

**Beschreibung:**
Eine vom User importierte gefuehrte Meditation. Das Abspielen der Audio-Datei ist das Hauptfeature.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `id` | UUID | Eindeutige ID |
| `localFilePath` | String? | Relativer Pfad |
| `fileName` | String | Original-Dateiname |
| `duration` | TimeInterval | Dauer in Sekunden |
| `teacher` | String | Lehrer (aus ID3) |
| `name` | String | Name (aus ID3) |
| `customTeacher` | String? | Benutzerdefinierter Lehrer |
| `customName` | String? | Benutzerdefinierter Name |
| `dateAdded` | Date | Hinzugefuegt am |

**Computed Properties:**

| Property | Beschreibung |
|----------|--------------|
| `effectiveTeacher` | customTeacher ?? teacher |
| `effectiveName` | customName ?? name |
| `formattedDuration` | MM:SS oder HH:MM:SS |
| `fileURL` | Vollstaendiger Pfad |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/GuidedMeditation.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/GuidedMeditation.kt`

**Siehe auch:** `AudioMetadata`, `EditSheetState`

---

### AudioMetadata

**Typ:** Value Object
**Pattern:** Transfer Object

**Beschreibung:**
Metadaten aus ID3-Tags einer Audio-Datei. Wird beim Import einer GuidedMeditation ausgelesen.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `artist` | String? | Artist (ID3 Tag) |
| `title` | String? | Titel (ID3 Tag) |
| `duration` | TimeInterval | Dauer in Sekunden |
| `album` | String? | Album (optional) |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/AudioMetadata.swift`
- Android: nicht vorhanden (direkt in Repository)

---

### EditSheetState

**Typ:** Value Object
**Pattern:** Editor State

**Beschreibung:**
Kapselt Zustand und Validierungslogik fuer das Editieren von GuidedMeditation-Metadaten.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `originalMeditation` | GuidedMeditation | Original |
| `editedTeacher` | String | Bearbeiteter Teacher |
| `editedName` | String | Bearbeiteter Name |

**Computed Properties:**

| Property | Beschreibung |
|----------|--------------|
| `hasChanges` | Aenderungen vorhanden? |
| `isValid` | Eingaben gueltig? |

**Methoden:**

| Methode | Beschreibung |
|---------|--------------|
| `applyChanges()` | Erzeugt aktualisierte GuidedMeditation |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/EditSheetState.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/EditSheetState.kt`

---

## Namenskonventionen

### Actions (TimerAction)

| Pattern | Beispiel | Verwendung |
|---------|----------|------------|
| `verbPressed` | `startPressed`, `pausePressed` | Benutzer-Interaktion |
| `verb(param:)` | `selectDuration(minutes:)` | Benutzer-Auswahl |
| `nounVerbed` | `preparationFinished`, `timerCompleted` | System-Event |
| `nounVerbTriggered` | `intervalGongTriggered` | Internes Event |
| `nounVerbPlayed` | `intervalGongPlayed` | Bestaetigung |

### Effects (TimerEffect)

| Pattern | Beispiel | Verwendung |
|---------|----------|------------|
| `configureNoun` | `configureAudioSession` | Setup |
| `verbNoun` | `startBackgroundAudio`, `playStartGong` | Aktion ausfuehren |
| `saveNoun(data)` | `saveSettings(MeditationSettings)` | Persistenz |

---

## Wartungshinweise

### Neuen Begriff hinzufuegen

1. **Quick Reference aktualisieren** - Alphabetisch einsortieren
2. **Detail-Eintrag erstellen** in passender Domain-Sektion
3. **Datei-Referenzen angeben** fuer beide Plattformen
4. **Cross-Referenzen pruefen** - Siehe auch, Pattern-Links
5. **Last Updated anpassen** im Header

### Domain-Zuordnung

Bei neuen Begriffen aus User-Perspektive zuordnen:
- **Timer Domain**: Alles rund um den Meditation-Timer (inkl. Beiwerk wie BackgroundSound)
- **Guided Meditations Domain**: Alles rund um importierte Audio-Dateien

Technische Koordinations-Konzepte (z.B. AudioSource) gehoeren in `dev-docs/AUDIO_ARCHITECTURE.md`.

### Review-Checkliste

Bei Code Reviews pruefen:
- [ ] Neue Domain-Begriffe im Glossar?
- [ ] Konsistente Benennung cross-platform?
- [ ] Namenskonventionen eingehalten?

---

**Pattern-Dokumentation:** `dev-docs/DDD_GUIDE.md`
