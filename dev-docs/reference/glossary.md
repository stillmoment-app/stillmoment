# Domain Glossar

<!--
CLAUDE-OPTIMIZED: Strukturiert fuer schnelles AI-Nachschlagen
- Quick Reference fuer Uebersicht
- Detailsektionen nach Domain gruppiert (aus User-Perspektive)
- Jeder Eintrag mit Cross-Platform Dateireferenzen

Last Updated: 2026-02-23
-->

## Quick Reference

| Begriff | Typ | Domain | Beschreibung |
|---------|-----|--------|--------------|
| `AudioMetadata` | Value Object | Guided Meditations | Metadaten aus Audio-Dateien (ID3 Tags) |
| `AppearanceMode` | Enum | App-wide | Darstellungsmodus (system, light, dark) |
| `ColorTheme` | Enum | App-wide | Farbthema-Auswahl (candlelight, forest, moon) |
| `Soundscape` | Value Object | Timer | Hintergrundgeraeusch (Beiwerk zum Timer) |
| `GongSound` | Value Object | Timer | Konfigurierbarer Gong-Ton (Start/Ende, Intervall) |
| `IntervalMode` | Enum | Timer | Intervallmodus (REPEATING, AFTER_START, BEFORE_END) |
| `IntervalSettings` | Value Object | Timer | Intervall-Gong-Konfiguration fuer tick() |
| `EditSheetState` | Value Object | Guided Meditations | Zustand und Validierung beim Editieren |
| `GuidedMeditation` | Entity | Guided Meditations | Gefuehrte Meditation (Audio ist Hauptfeature) |
| `Attunement` | Value Object | Timer | Optionale Einstimmung (z.B. Atemuebung) vor stiller Meditation. Im Code aktuell noch `Introduction` (Rename-Ticket pending). |
| `GuidedMeditationSettings` | Value Object | Guided Meditations | Player-Einstellungen (Vorbereitungszeit) |
| `PreparationCountdownState` | Enum | Guided Meditations | Zustandsautomat fuer Vorbereitungs-Countdown |
| `LocalizedString` | Value Object | Timer | Lokalisierter String fuer Soundscape |
| `MeditationSettings` | Value Object | Timer | Benutzereinstellungen |
| `MeditationTimer` | Value Object | Timer | Zentrales Timer-Modell |
| `Praxis` | Value Object | Timer | Benannte, speicherbare Timer-Konfiguration |
| `PraxisRepository` | Protocol | Timer | CRUD-Protokoll fuer Praxis-Persistenz |
| `TimerAction` | Enum | Timer | Benutzer-Aktionen und System-Events |
| `TimerEffect` | Enum | Timer | Side Effects des Reducers |
| `TimerEvent` | Enum | Timer | Domain Events aus tick() (preparationCompleted, meditationCompleted, intervalGongDue) |
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
| `startGong` | Start-Gong spielt, Meditation-Countdown laeuft bereits |
| `introduction` | Einstimmungs-Audio spielt (z.B. Atemuebung), Meditation-Countdown laeuft bereits |
| `running` | Timer laeuft, stille Meditationsphase aktiv |
| `endGong` | Timer bei 0, Completion-Gong spielt. Ring voll, 00:00 angezeigt. Wechsel zu `completed` erst nach Audio-Callback (`endGongFinished`). |
| `completed` | Timer abgelaufen, Meditation beendet |

**State Machine:**

```
idle --> preparation --> startGong --> introduction --> running --> endGong --> completed
  |                        |              |               ^
  |                        |              +---------------+
  |                        |              (no attunement)
  +------------------------+--------------+

Pfade:
- Voll: idle → preparation → startGong → introduction → running → endGong → completed
- Ohne Einstimmung: idle → preparation → startGong → running → endGong → completed
- Ohne Vorbereitung: idle → startGong → introduction → running → endGong → completed
- Minimal: idle → startGong → running → endGong → completed
- Start-Gong spielt im startGong-State; Einstimmung wartet auf startGongFinished
- Einstimmungs-Audio startet erst nach dem Start-Gong (sequenziell via startGongFinished)
- Hintergrund-Audio startet erst beim Uebergang zu running (nach Einstimmung)
- Einstimmungs-Timer zaehlt zur Gesamtmeditationszeit
- Running wechselt zu endGong (Timer bei 0), endGong wechselt zu completed (Audio-Callback)
- endGong: Completion-Gong spielt, UI zeigt 00:00 mit vollem Ring, Keep-Alive bleibt aktiv
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
| `startPressed` | Start-Button gedrueckt |
| `resetPressed` | Reset-Button gedrueckt |

**System-Events (Verb + Past Participle):**

| Event | Beschreibung |
|-------|--------------|
| `preparationFinished` | Vorbereitung abgeschlossen |
| `startGongFinished` | Start-Gong fertig abgespielt, Einstimmungs-Audio kann starten |
| `introductionFinished` | Einstimmungs-Audio beendet, stille Meditation beginnt |
| `timerCompleted` | Timer bei 0 angekommen, wechselt zu endGong-Phase |
| `endGongFinished` | Completion-Gong fertig abgespielt (Audio-Callback), wechselt zu completed |
| `intervalGongTriggered` | Intervall-Gong soll spielen (ausgeloest durch TimerEvent.intervalGongDue) |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerAction.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerAction.kt`

**Siehe auch:** TimerReducer (Pattern in `../architecture/ddd.md`)

---

### TimerEvent

**Typ:** Enum
**Pattern:** Domain Event

**Beschreibung:**
Domain Events, die von `MeditationTimer.tick()` emittiert werden. Druecken aus, was waehrend eines Ticks passiert ist. Das ViewModel verarbeitet Events direkt statt Transitions via `previousState`-Vergleich zu erkennen.

**Events:**

| Event | Beschreibung |
|-------|--------------|
| `preparationCompleted` | Vorbereitung abgeschlossen, StartGong-Phase beginnt |
| `meditationCompleted` | Timer bei 0, EndGong-Phase beginnt |
| `intervalGongDue` | Intervall-Gong ist faellig (tick() hat lastIntervalGongAt intern markiert) |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerEvent.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerEvent.kt`

**Siehe auch:** `MeditationTimer.tick()`, `IntervalSettings`

---

### IntervalSettings

**Typ:** Value Object
**Pattern:** Configuration Object

**Beschreibung:**
Konfiguration fuer Intervall-Gong-Erkennung, die an `MeditationTimer.tick(intervalSettings:)` uebergeben wird. Wird aus `MeditationSettings` aufgebaut wenn Intervall-Gongs aktiviert sind, sonst `nil`.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `intervalMinutes` | Int | Intervall in Minuten (z.B. 5 fuer alle 5 Minuten) |
| `mode` | IntervalMode | Intervallmodus (repeating, afterStart, beforeEnd) |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/IntervalSettings.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/IntervalSettings.kt`

**Siehe auch:** `IntervalMode`, `MeditationSettings.intervalMinutes`

---

### TimerEffect

**Typ:** Enum
**Pattern:** Effect (Side Effects)

**Kategorien:**

| Kategorie | Effects |
|-----------|---------|
| Session Lifecycle | `activateTimerSession`, `deactivateTimerSession` |
| Background Audio | `startBackgroundAudio(soundId:volume:)`, `stopBackgroundAudio` |
| Sound Effects | `playStartGong`, `playIntroduction(introductionId:)`, `stopIntroduction`, `playIntervalGong(soundId:volume:)`, `playCompletionSound` |
| Timer Service | `startTimer(durationMinutes:)`, `resetTimer`, `beginIntroductionPhase`, `endIntroductionPhase` |
| State Transitions | `transitionToCompleted`, `clearTimer` |
| Persistence | `saveSettings(MeditationSettings)` |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/TimerEffect.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerEffect.kt`

**Pattern-Dokumentation:** `../architecture/ddd.md` (Effect Pattern)

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
| `silentPhaseStartRemaining` | Int? | Verbleibende Sekunden beim Start der stillen Phase (Baseline fuer Intervall-Gongs) |
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
| `tick(intervalSettings:)` | Neue Instanz mit Zeit-1 und Domain Events `(MeditationTimer, [TimerEvent])` |
| `withState(_:)` | Neue Instanz mit neuem State |
| `startPreparation()` | Neue Instanz im Vorbereitungsmodus |
| `endIntroduction()` | Neue Instanz im Running-State nach Einstimmung, setzt `silentPhaseStartRemaining` |
| `markIntervalGongPlayed()` | Neue Instanz mit Gong-Marker |
| `shouldPlayIntervalGong(intervalMinutes:mode:)` | Prueft ob Gong faellig |
| `reset()` | Zurueckgesetzter Timer |

**Invarianten:**
- durationMinutes: 1...60
- remainingSeconds: 0...totalSeconds
- Alle Aenderungen erzeugen neue Instanzen (immutabel)

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/MeditationTimer.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/MeditationTimer.kt`

---

### MeditationSettings

**Typ:** Value Object
**Pattern:** Configuration Object

**Properties:**

| Property | Typ | Default | Beschreibung |
|----------|-----|---------|--------------|
| `intervalGongsEnabled` | Bool | false | Intervall-Gongs aktiviert? |
| `intervalMinutes` | Int | 5 | Intervall in Minuten (1-60) |
| `intervalMode` | IntervalMode | REPEATING | Intervallmodus (REPEATING, AFTER_START, BEFORE_END) |
| `intervalSoundId` | String | "soft-interval" | Sound ID fuer Intervallklaenge |
| `intervalGongVolume` | Float | 0.75 | Lautstaerke fuer Intervallklaenge (0.0-1.0) |
| `backgroundSoundId` | String | "silent" | Hintergrund-Sound ID |
| `durationMinutes` | Int | 10 | Zuletzt gewaehlte Dauer |
| `preparationTimeEnabled` | Bool | true | Vorbereitungszeit aktiviert? |
| `preparationTimeSeconds` | Int | 15 | Vorbereitungszeit in Sekunden (5, 10, 15, 20, 30, 45) |
| `gongSoundId` | String | "temple-bell" | Gong-Ton ID (Start/Ende) |
| `introductionId` | String? | nil | Einstimmungs-ID (nil = keine Einstimmung) |

**Validierung:**
- `validateInterval(_:)` - Clamps zu 1-60
- `validateDuration(_:)` - Clamps zu 1-60
- `validatePreparationTime(_:)` - Clamps zu naechstem gueltigen Wert (5, 10, 15, 20, 30, 45)

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/MeditationSettings.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/MeditationSettings.kt`

---

### Praxis

**Typ:** Value Object (immutabel)
**Pattern:** Configuration Object with Identity

**Beschreibung:**
Eine benannte, speicherbare Timer-Konfiguration. "Praxis" (meditierte Praxis) repraesentiert eine vollstaendige Sammlung von Timer-Einstellungen, die gespeichert, abgerufen und wiederverwendet werden kann. Mehrere Praxen ermoeglichen schnelles Umschalten zwischen verschiedenen Meditationskonfigurationen.

Praxis-Felder sind 1:1 identisch mit den bestehenden MeditationSettings-Feldern — keine neuen Konfigurationsoptionen.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `id` | UUID | Eindeutige ID |
| `name` | String | Anzeigename (z.B. "Standard", "Morgenmeditation") |
| `durationMinutes` | Int | Vorbelegte Dauer (1-60) — session-only anpassbar |
| `preparationTimeEnabled` | Bool | Vorbereitungszeit aktiviert? |
| `preparationTimeSeconds` | Int | Vorbereitungszeit (5, 10, 15, 20, 30, 45s) |
| `startGongSoundId` | String | Gong-Ton ID fuer Start/Ende |
| `gongVolume` | Float | Gong-Lautstaerke (0.0-1.0) |
| `introductionId` | String? | Einstimmungs-ID (nil = keine) |
| `intervalGongsEnabled` | Bool | Intervall-Gongs aktiviert? |
| `intervalMinutes` | Int | Intervall in Minuten (1-60) |
| `intervalMode` | IntervalMode | Intervallmodus |
| `intervalSoundId` | String | Sound ID fuer Intervall-Gong |
| `intervalGongVolume` | Float | Lautstaerke Intervall-Gong (0.0-1.0) |
| `backgroundSoundId` | String | Hintergrund-Sound ID |
| `backgroundSoundVolume` | Float | Hintergrund-Lautstaerke (0.0-1.0) |

**Computed Properties:**

| Property | Beschreibung |
|----------|--------------|
| `shortDescription` | Kurzbeschreibung (z.B. "10 Min · Stille · Tempelglocke · 15s Vorbereitung") |

**Invarianten:**
- Mindestens eine Praxis muss immer existieren (PraxisRepository verhindert Loeschen der letzten)
- durationMinutes: 1...60
- Alle Volumes: 0.0...1.0
- Alle Aenderungen erzeugen neue Instanzen (immutabel)

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/Praxis.swift`

**Siehe auch:** `MeditationSettings`, `PraxisRepository`

---

### PraxisRepository

**Typ:** Protocol
**Pattern:** Repository

**Beschreibung:**
CRUD-Protokoll fuer Praxis-Persistenz. Implementierungen verbergen den Speichermechanismus. Invariante: Mindestens eine Praxis muss immer existieren.

**Methoden:**

| Methode | Beschreibung |
|---------|--------------|
| `loadAll()` | Alle Praxen laden (erstellt Default bei Erstinstallation/Migration) |
| `load(byId:)` | Praxis per ID laden |
| `save(_:)` | Praxis speichern (erstellen oder aktualisieren) |
| `delete(id:)` | Praxis loeschen (throws wenn letzte) |
| `activePraxisId` | Aktive Praxis-ID (nil wenn nicht gesetzt) |
| `setActivePraxisId(_:)` | Aktive Praxis-ID setzen |

**Fehler:**

| Fehler | Beschreibung |
|--------|--------------|
| `cannotDeleteLastPraxis` | Letzte Praxis kann nicht geloescht werden |
| `praxisNotFound(UUID)` | Praxis mit dieser ID nicht gefunden |

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Services/PraxisRepository.swift`
- iOS (Impl): `ios/StillMoment/Infrastructure/Services/UserDefaultsPraxisRepository.swift`

---

### Attunement / Einstimmung

**Typ:** Value Object
**Pattern:** Static Registry
**Code-Name (aktuell):** `Introduction` — Rename zu `Attunement` als eigenes Ticket geplant.

**Beschreibung:**
Optionales Einstimmungs-Audio (z.B. gefuehrte Atemuebung), das nach dem Start-Gong und vor der stillen Meditationsphase abgespielt wird. Einstimmungen spielen einmalig und bereiten den Meditierenden auf die stille Phase vor. Sie sind fest in der App gebundelt, sprachspezifisch und ueber die Timer-Einstellungen konfigurierbar. Die Einstimmungszeit zaehlt zur Gesamtmeditationszeit.

**Abgrenzung zu Soundscape:** Einstimmungen spielen **einmalig vor** der stillen Phase. Soundscapes spielen **als Loop waehrend** der stillen Phase.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `id` | String | Sprachuebergreifend konstante ID (z.B. "breath") |
| `name` | LocalizedString | Lokalisierter Anzeigename (DE/EN) |
| `durationSeconds` | Int | Dauer des Einstimmungs-Audios in Sekunden |
| `availableLanguages` | [String] | Sprachcodes fuer die Audio-Dateien vorhanden sind |
| `filenamePattern` | String | Dateiname-Muster mit `{lang}` Platzhalter |

**Registry:**

| ID | DE Label | EN Label | Dauer | Sprachen |
|----|----------|----------|-------|----------|
| `breath` | Atemuebung | Breathing Exercise | 1:35 (95s) | de |

**Methoden:**

| Methode | Beschreibung |
|---------|--------------|
| `audioFilename(for:)` | Gibt Dateinamen fuer eine Sprache zurueck |
| `availableForCurrentLanguage()` | Filtert nach Geraetesprache |
| `find(byId:)` | Sucht Einstimmung per ID |
| `isAvailableForCurrentLanguage(_:)` | Prueft Verfuegbarkeit fuer aktuelle Sprache |

**Audio-Dateinamen-Konvention:** `intro-{id}-{sprache}.mp3` (z.B. `intro-breath-de.mp3`)

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/Introduction.swift` (Rename zu `Attunement.swift` geplant)
- Android: (geplant)

**Siehe auch:** `MeditationSettings.introductionId`, `TimerState.introduction`, `TimerEffect.playIntroduction` (Code-Rename geplant)

---

### Soundscape

**Typ:** Value Object
**Pattern:** Localized Content

**Beschreibung:**
Optionales Hintergrundgeraeusch waehrend der Timer-Meditation. Beiwerk zum Timer, kein eigenstaendiges Feature. Im Code als `BackgroundSound` implementiert, UI-Label ist "Soundscape" / "Klangkulisse".

---

### GongSound

**Typ:** Value Object
**Pattern:** Localized Content

**Beschreibung:**
Konfigurierbarer Gong-Ton fuer Start/Ende-Gong und Intervall-Gong. Immutables Value Object mit ID, Audio-Ressource und lokalisiertem Namen.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `id` | String | Eindeutige ID (z.B. "temple-bell") |
| `rawResId` / `filename` | Int / String | Audio-Ressource (plattformspezifisch) |
| `localizedName` | String | Lokalisierter Name (DE/EN) |

**Verfuegbare Sounds (Start/Ende-Gong):**

| ID | EN Label | DE Label |
|----|----------|----------|
| `temple-bell` | Temple Bell | Tempelglocke |
| `classic-bowl` | Classic Bowl | Klassisch |
| `deep-resonance` | Deep Resonance | Tiefe Resonanz |
| `clear-strike` | Clear Strike | Klarer Anschlag |

**Zusaetzlicher Sound (nur Intervall-Gong):**

| ID | EN Label | DE Label |
|----|----------|----------|
| `soft-interval` | Soft Interval Tone | Sanfter Intervallton |

**Default (Start/Ende):** `temple-bell`
**Default (Intervall):** `soft-interval`

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/GongSound.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/GongSound.kt`

**Siehe auch:** `MeditationSettings.gongSoundId`, `MeditationSettings.intervalSoundId`

---

### IntervalMode

**Typ:** Enum
**Pattern:** Strategy

**Beschreibung:**
Definiert wie Intervallklaenge waehrend der Meditation ausgeloest werden.

**Werte:**

| Wert | Beschreibung |
|------|--------------|
| `REPEATING` | Gongs bei jedem vollen Intervall vom Start |
| `AFTER_START` | Genau 1 Gong X Minuten nach Start |
| `BEFORE_END` | Genau 1 Gong X Minuten vor Ende |

**Default:** `REPEATING`

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/IntervalMode.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/IntervalMode.kt`

**Algorithmus-Details:** `../architecture/ddd.md` (Flexible Intervall-Modi)

**Siehe auch:** `MeditationTimer.shouldPlayIntervalGong()`, `MeditationSettings.intervalMode`

---

### LocalizedString

**Typ:** Value Object
**Pattern:** Nested Value Object

**Beschreibung:**
Lokalisierter String fuer Soundscape Namen und Beschreibungen.

**Properties:**

| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `de` | String | Deutscher Text |
| `en` | String | Englischer Text |

**Datei-Referenzen:**
- iOS: nested in `BackgroundSound.swift`
- Android: nested in `sounds.json` Schema

---

## App-wide Domain

App-weite Konzepte die beide Tabs betreffen.

### ColorTheme

**Typ:** Enum (Domain)
**Pattern:** Configuration Value

**Beschreibung:**
Farbthema-Auswahl. Jedes Theme hat eine Light- und Dark-Variante die automatisch dem System-Setting folgt.

**Werte:**

| Wert | Beschreibung |
|------|--------------|
| `candlelight` | Kerzenschein — warm/sand (Default) |
| `forest` | Wald — warm-neutral, natuerlich |
| `moon` | Mond — silber/indigo, naechtlich |

**Persistence:** `@AppStorage("selectedTheme")` via `ThemeManager`

**Architektur-Kette:**
```
ColorTheme (Domain) → ThemeManager (Presentation) → ThemeRootView → ThemeColors → @Environment(\.themeColors)
```

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/ColorTheme.swift`
- Farb-System Doku: `dev-docs/reference/color-system.md`

---

### AppearanceMode

**Typ:** Enum (Domain)
**Pattern:** Configuration Value

**Beschreibung:**
Darstellungsmodus-Auswahl. Ermoeglicht dem User, Light/Dark Mode unabhaengig vom System-Setting zu erzwingen.

**Werte:**

| Wert | Beschreibung |
|------|--------------|
| `system` | Folgt dem Geraete-Setting (Default) |
| `light` | Erzwingt Light Mode |
| `dark` | Erzwingt Dark Mode |

**Persistence:** `@AppStorage("appearanceMode")` via `ThemeManager`

**Architektur-Kette:**
```
AppearanceMode (Domain) → ThemeManager (Presentation) → ThemeRootView → .preferredColorScheme()
```

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/AppearanceMode.swift`

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

### GuidedMeditationSettings

**Typ:** Value Object
**Pattern:** Configuration Object

**Beschreibung:**
Benutzereinstellungen fuer den Guided Meditation Player. Analog zu `MeditationSettings` fuer den Timer.

**Properties:**

| Property | Typ | Default | Beschreibung |
|----------|-----|---------|--------------|
| `preparationTimeSeconds` | Int? | nil | Vorbereitungszeit vor MP3-Start (nil = deaktiviert) |

**Gueltige Werte:**
- `nil` (Aus), 5, 10, 15, 20, 30, 45 Sekunden

**Validierung:**
- `validatePreparationTime(_:)` - Gibt nil fuer nil zurueck, sonst naechsten gueltigen Wert

**Persistence:**
- UserDefaults Key: `guidedMeditation.preparationTimeSeconds`
- Wert 0 bedeutet deaktiviert (nil)

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/GuidedMeditationSettings.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/GuidedMeditationSettings.kt` (geplant)

**Siehe auch:** `MeditationSettings` (Timer-Pendant)

---

### PreparationCountdownState

**Typ:** Enum
**Pattern:** State Machine

**Beschreibung:**
Zustandsautomat fuer den Vorbereitungs-Countdown vor dem Start einer gefuehrten Meditation. Analog zu `TimerState.preparation` fuer den Timer, aber einfacher (nur 3 Zustaende).

**Werte:**

| Wert | Beschreibung |
|------|--------------|
| `idle` | Kein Countdown aktiv |
| `preparation(remainingSeconds:)` | Countdown laeuft, zeigt verbleibende Sekunden |
| `finished` | Countdown abgeschlossen, MP3 startet |

**State Machine:**

```
idle --> preparation --> finished --> (MP3 playback)
```

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Application/ViewModels/GuidedMeditationPlayerViewModel.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/player/` (geplant)

**Siehe auch:** `TimerState` (Timer-Pendant mit `preparation` State)

---

## Namenskonventionen

### Actions (TimerAction)

| Pattern | Beispiel | Verwendung |
|---------|----------|------------|
| `verbPressed` | `startPressed`, `resetPressed` | Benutzer-Interaktion |
| `nounVerbed` | `preparationFinished`, `introductionFinished` (= Einstimmung fertig), `timerCompleted`, `endGongFinished` | System-Event |
| `nounVerbTriggered` | `intervalGongTriggered` | Internes Event (von TimerEvent ausgeloest) |

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

Technische Koordinations-Konzepte (z.B. AudioSource) gehoeren in `../architecture/audio-system.md`.

### Review-Checkliste

Bei Code Reviews pruefen:
- [ ] Neue Domain-Begriffe im Glossar?
- [ ] Konsistente Benennung cross-platform?
- [ ] Namenskonventionen eingehalten?

---

**Pattern-Dokumentation:** `../architecture/ddd.md`
