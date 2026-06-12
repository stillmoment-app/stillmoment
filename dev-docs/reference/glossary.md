# Domain Glossar

<!--
CLAUDE-OPTIMIZED: Strukturiert fuer schnelles AI-Nachschlagen
- Quick Reference fuer Uebersicht
- Detailsektionen nach Domain gruppiert (aus User-Perspektive)
- Jeder Eintrag mit Cross-Platform Dateireferenzen

Last Updated: 2026-06-11
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
| `SoundscapeResolver` | Protocol | Timer | Loest Soundscape-IDs transparent auf (built-in oder custom) |
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
| Trim-Punkte (`trimStart`/`trimEnd`) | Attribute | Guided Meditations | Optionale Start-/Endpunkte pro Meditation; Wiedergabe laeuft nur im effektiven Bereich |
| Wellenform (`MeditationWaveform`) | Value Object | Guided Meditations | Vorberechnete Amplituden-Darstellung (220 Peaks) fuer den Trim-Editor |
| Wiedergabe-Bereich | Konzept | Guided Meditations | Das Trim-Punkte-Paar als begrenzter Wiedergabe-Bereich (nicht-destruktiv) |

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
| `running` | Timer laeuft, stille Meditationsphase aktiv |
| `endGong` | Timer bei 0, Completion-Gong spielt. Ring voll, 00:00 angezeigt. Wechsel zu `completed` erst nach Audio-Callback (`endGongFinished`). |
| `completed` | Timer abgelaufen, Meditation beendet |

**State Machine:**

```
idle --> preparation --> startGong --> running --> endGong --> completed
  |                        ^
  |                        |
  +------------------------+

Pfade:
- Voll: idle → preparation → startGong → running → endGong → completed
- Ohne Vorbereitung: idle → startGong → running → endGong → completed
- Start-Gong spielt im startGong-State; Hintergrund-Audio startet erst beim Uebergang zu running
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
| `startGongFinished` | Start-Gong fertig abgespielt, stille Meditation beginnt |
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
| Sound Effects | `playStartGong`, `playIntervalGong(soundId:volume:)`, `playCompletionSound` |
| Timer Service | `startTimer(durationMinutes:)`, `resetTimer`, `beginRunningPhase` |
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

**Implementierungen:**
- iOS: `ios/StillMoment/Infrastructure/Services/UserDefaultsPraxisRepository.swift` (JSON in UserDefaults)

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Services/PraxisRepository.swift`

---

### SoundscapeResolver

**Typ:** Protocol + Implementation
**Pattern:** Unified Audio Resolution (Domain Protocol + Infrastructure Implementation)

**Beschreibung:**
Loest Soundscape-Audio-IDs transparent auf — unabhaengig davon, ob die ID auf einen Built-in-Katalog-Eintrag (`BackgroundSound`) oder eine importierte Custom-Datei (`CustomAudioFile`) zeigt. Die spezielle ID `"silent"` gibt `nil` zurueck.

**Methoden:**

| Methode | Beschreibung |
|---------|--------------|
| `resolve(id:)` | Gibt `ResolvedSoundscape?` zurueck (Name) |
| `resolveAudioURL(id:)` | Gibt die Playback-URL zurueck |
| `allAvailable()` | Alle verfuegbaren Soundscapes (built-in + custom) |

**Datei-Referenzen:**
- iOS Protocol: `ios/StillMoment/Domain/Services/SoundscapeResolverProtocol.swift`
- iOS Implementation: `ios/StillMoment/Infrastructure/Services/SoundscapeResolver.swift`
- Android Protocol: `android/app/src/main/kotlin/com/stillmoment/domain/services/SoundscapeResolverProtocol.kt`
- Android Implementation: `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/SoundscapeResolver.kt`

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
| `duration` | TimeInterval | Dateilaenge in Sekunden |
| `teacher` | String | Lehrer (aus ID3 oder user-editiert; einzige Wahrheit seit shared-103) |
| `name` | String | Name (aus ID3 oder user-editiert; einzige Wahrheit seit shared-103) |
| `trimStart` | TimeInterval? | Optionaler Startpunkt der Wiedergabe (shared-105; nil = Dateianfang) |
| `trimEnd` | TimeInterval? | Optionaler Endpunkt der Wiedergabe (shared-105; nil = Dateiende) |
| `gongEnabled` | Bool | Gong am Anfang und Ende der Wiedergabe (shared-106; Default false) |
| `dateAdded` | Date | Hinzugefuegt am |

**Computed Properties:**

| Property | Beschreibung |
|----------|--------------|
| `effectiveStart` | trimStart ?? 0 — wo die Wiedergabe tatsaechlich beginnt |
| `effectiveEnd` | trimEnd ?? duration — wo die Wiedergabe tatsaechlich endet |
| `effectiveDuration` | effectiveEnd − effectiveStart — die Zeit, die der User tatsaechlich meditiert |
| `formattedDuration` | Effektive Dauer als MM:SS oder HH:MM:SS (Library + Player) |
| `formattedFileDuration` | Volle Dateilaenge als MM:SS oder HH:MM:SS (Datei-Info im Edit-Sheet) |

**Trim-Punkte (shared-105):**
Nicht-destruktiv — die Audio-Datei wird nie veraendert. Playback startet bei `effectiveStart`,
endet bei `effectiveEnd` (gleicher Completion-Pfad wie ein natuerliches Dateiende, auch auf dem
Lock Screen). Seek/Skip clampen auf den effektiven Bereich. Legacy-Eintraege ohne Trim-Keys
laden unveraendert (`decodeIfPresent`).

**Start-/End-Gong (shared-106):**
`startGongEnabled` und `endGongEnabled` rahmen die Wiedergabe unabhaengig voneinander mit
einem Gong: Start-Gong → kurze Atempause (2 s) → Audio; am effektiven Ende spielt der
End-Gong vollstaendig aus, bevor die Audio-Session freigegeben wird (Lock-Screen-sicher).
Der Klang ist pro Meditation waehlbar und gilt fuer beide Gongs (`gongSoundId`,
`GongSound.allMeditationGongSounds` — gleiche Gongs wie der Timer, ohne Vibration); die
Lautstaerke folgt den Timer-Einstellungen (`Praxis.gongVolume`).
Wiedergabe via `MeditationGongPlayerProtocol` (Domain) / `MeditationGongPlayer` (Infrastructure).
Legacy-Eintraege ohne Keys laden als `false` bzw. Standard-Gong; das fruehere kombinierte
`gongEnabled`-Flag laedt mit beiden Gongs aktiviert.

**Datei-Referenzen:**
- iOS: `ios/StillMoment/Domain/Models/GuidedMeditation.swift`
- Android: `android/app/src/main/kotlin/com/stillmoment/domain/models/GuidedMeditation.kt`

**Siehe auch:** `AudioMetadata`, `EditSheetState`, Wiedergabe-Bereich, Wellenform

---

### Wiedergabe-Bereich

**Typ:** Konzept (UI-Begriff fuer das Trim-Punkte-Paar)
**Pattern:** Non-destructive Range

**Beschreibung:**
Der User-sichtbare Begriff fuer den durch `trimStart`/`trimEnd` (shared-105) begrenzten
Wiedergabe-Bereich einer Meditation. Im Edit-Sheet ersetzt die Karte "Wiedergabe-Bereich"
(shared-107) die frueheren mm:ss-Textfelder und oeffnet einen Vollbild-Wellenform-Editor, in
dem zwei ziehbare Griffe Anfang und Ende setzen. Die Abspielposition (Playhead) hat dort eine
eigene Lane in Salbeigruen oberhalb der Wellenform; Beruehrungen auf der Spur werden rein
geometrisch aufgeloest (`TrimHitTesting`: oben Playhead, unten Marken, im Cluster gewinnt die
aktive Marke). Nicht-destruktiv: die Audio-Datei bleibt
unveraendert, der Bereich ist jederzeit aenderbar oder entfernbar. Zwischen Anfang und Ende
gilt ein Mindestabstand von 25 s; ist der Bereich praktisch die ganze Datei (start <= 1 s und
end >= Dauer − 1 s), wird kein Zuschnitt gespeichert. Die effektive Wiedergabe-Logik selbst
lebt in `GuidedMeditation.effectiveStart`/`effectiveEnd`/`effectiveDuration`.

**Datei-Referenzen:**
- iOS Editor-State: `ios/StillMoment/Domain/Models/TrimEditorState.swift`
- iOS Editor-UI: `ios/StillMoment/Presentation/Views/GuidedMeditations/TrimEditor/`
- Android: noch offen (shared-105 Android Voraussetzung)

**Siehe auch:** `GuidedMeditation` (Trim-Punkte), Wellenform, `EditSheetState`

---

### Wellenform

**Typ:** Value Object (`MeditationWaveform`)
**Pattern:** Precomputed, cached Representation

**Beschreibung:**
Vorberechnete, normalisierte Amplituden-Darstellung einer Meditation fuer den Trim-Editor
(shared-107). Haelt eine feste Anzahl Peak-Werte (`barCount` = 220), jeweils normalisiert auf
`[0, 1]`, fuer die Balken-Darstellung der Wellenform. In der Wellenform heben sich dichte
Sprach-Bloecke (Einleitung, Schlussworte) sichtbar von der stillen Meditation ab. Die Daten
sind klein (~220 Floats), werden beim Import im Hintergrund berechnet und pro Meditation
gecacht; fehlen sie (Bestands-Meditation nach Update), werden sie beim ersten Oeffnen einmalig
berechnet. Da die Audio-Datei nie veraendert wird (nicht-destruktive Invariante), braucht der
Cache keine Invalidierung. Schlaegt die Dekodierung fehl, zeigt der Editor statt Balken eine
schlichte Linie — die Funktion bleibt erhalten.

**Datei-Referenzen:**
- iOS Modell: `ios/StillMoment/Domain/Models/MeditationWaveform.swift`
- iOS Provider/Cache/Generierung: `ios/StillMoment/Domain/Services/WaveformProviderProtocol.swift`, `WaveformCacheServiceProtocol.swift`, `WaveformGenerationServiceProtocol.swift`
- Android: noch offen (shared-105 Android Voraussetzung)

**Siehe auch:** Wiedergabe-Bereich, `GuidedMeditation`

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
| `editedTrimStartText` | String | Trim-Start als Text (m:ss, h:mm:ss oder Minuten; leer = kein Trim) |
| `editedTrimEndText` | String | Trim-Ende als Text (m:ss, h:mm:ss oder Minuten; leer = kein Trim) |
| `editedGongEnabled` | Bool | Bearbeiteter Gong-Schalter (shared-106) |

**Computed Properties:**

| Property | Beschreibung |
|----------|--------------|
| `hasChanges` | Aenderungen vorhanden (inkl. Trim-Punkte)? |
| `isValid` | Eingaben gueltig (Pflichtfelder + Trim-Konsistenz)? |
| `isTrimInputValid` | Trim-Felder parsen und beschreiben einen Bereich innerhalb der Datei? |
| `trimStartValue` / `trimEndValue` | Geparste Trim-Werte in Sekunden (nil bei leer/unparsebar) |

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
| `nounVerbed` | `preparationFinished`, `timerCompleted`, `endGongFinished` | System-Event |
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
