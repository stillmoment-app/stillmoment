# Changelog

All notable changes to Still Moment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2026-04-10

### Fixed (iOS)
- **Tab-Bar aktiver Tab besser erkennbar** - Inaktive Tabs erhalten explizite Farbe (textSecondary@50% Opacity) statt iOS-System-Default. Aktiver Tab ist jetzt auf allen Themes (Light + Dark) sofort erkennbar. UIKit-Bridge wird bei Theme-Wechsel korrekt aktualisiert (Ticket: ios-038)

### Changed (iOS)
- **Legacy Timer-Settings-Store aufgeraeumt** - `UserDefaultsTimerSettingsRepository` ist jetzt read-only (nur Migration). `save()`, `TimerSettingsRepository`-Protocol, `TimerEffect.saveSettings` und tote `hasSeenSettingsHint`-Tests entfernt. `PraxisRepository` ist alleinige Quelle fuer Timer-Settings. (Ticket: ios-039)
- **AudioService als einzelne geteilte Instanz** - `TimerViewModel`, `GuidedMeditationsListViewModel` und `PraxisEditorViewModel` teilen sich jetzt eine `AudioService`-Instanz statt je eine eigene zu erstellen. Behebt strukturelle Bugs: falscher Session-Release durch fremde Instanz und Conflict-Handler-Überschreibung im `AudioSessionCoordinator`. `StillMomentApp` erstellt die Instanz einmalig in `init()` und gibt sie per Constructor-Injection weiter. (Ticket: ios-040)

### Added (iOS)
- **Vibration als Gong-Signal** - "Vibration" ist jetzt als Gong-Option auswaehlbar (Start/Ende-Gong und Intervall-Gong). Bei aktiver Vibrations-Option wird kein Ton abgespielt, der Lautstaerke-Slider wird ausgeblendet. Funktioniert auch auf dem Lock Screen (aktive AVAudioSession durch Keep-Alive). Antippen der Option loest eine Haptic-Vorschau aus. (Ticket: shared-076)
- **Share Sheet Import** - Audio-Dateien (MP3, M4A) koennen ueber das System-Share-Sheet direkt an Still Moment gesendet werden — aus Safari, Mail, WhatsApp oder anderen Apps. Die App oeffnet sich, zeigt die Import-Typ-Auswahl und importiert die Datei in die Bibliothek. Bei URL-Shares (z.B. direkter MP3-Link aus Safari) wird die Datei automatisch heruntergeladen. Duplikate werden mit Titel und Lehrername erkannt (Ticket: shared-046)
- **Long-Press Preview in der Meditations-Bibliothek** - Play-Icon in der Meditationsliste kann lang gedrueckt werden, um eine Audio-Vorschau abzuspielen. Loslassen stoppt die Wiedergabe mit kurzem Fade-out. Visuelles Feedback (Scale-Effekt) und haptisches Feedback beim Start (Ticket: shared-075)

### Added (Android)
- **Vibration als Gong-Signal** - "Vibration" ist jetzt als Gong-Option auswaehlbar (Start/Ende-Gong und Intervall-Gong). Bei aktiver Vibrations-Option wird kein Ton abgespielt, der Lautstaerke-Slider wird ausgeblendet. (Ticket: shared-076)
- **Long-Press Preview in der Meditations-Bibliothek** - Play-Icon in der Meditationsliste kann lang gedrueckt werden (~0.5s), um eine Audio-Vorschau abzuspielen. Tippen auf das Stop-Icon beendet die Wiedergabe mit kurzem Fade-out (~0.3s). Haptisches Feedback beim Start. (Ticket: shared-075)

## [2.0.0] - 2026-03-05

### Fixed (Android)
- **Custom Audio korrekt aufgeloest** - Custom Einstimmungen und Klangatmosphaeren wurden in Pills, Editor und TimerReducer nicht erkannt, weil nur der Built-in-Katalog geprueft wurde. Neue AttunementResolver und SoundscapeResolver loesen IDs transparent auf — egal ob built-in oder importiert (Ticket: shared-074)
- **Custom Einstimmung im Timer** - Custom Einstimmung (Attunement) wurde als "No introduction" angezeigt, weil TimerViewModel parallel von SettingsDataStore und PraxisDataStore las und SettingsDataStore custom UUIDs herausfilterte. PraxisDataStore ist jetzt Single Source of Truth fuer Timer-Settings (Ticket: android-074)
- **Custom Audio Resolution** - Einheitliche Resolver (`AttunementResolver`, `SoundscapeResolver`) fuer transparente Aufloesung von Built-in und importierten Audio-IDs. Infrastructure-Implementierungen mit Hilt DI, Test-Mocks und Unit-Tests (Ticket: shared-074)

### Fixed (iOS)
- **Custom Audio Resolution** - Einheitliche Resolver (`AttunementResolver`, `SoundscapeResolver`) fuer transparente Aufloesung von Built-in und importierten Audio-IDs. Timer-Reducer, Pill-Anzeige und Playback nutzen jetzt zentrale Resolver statt duplizierter Katalog-Lookups. Behebt: Custom Einstimmungen wurden im Reducer nicht erkannt, Pill-Labels zeigten Fallback-Text (Ticket: shared-074)
- **Custom Soundscape Playback** - `AudioService` convenience init fehlte `CustomAudioRepository`, eigene Soundscapes spielten nicht ab (Ticket: shared-065)

### Changed (iOS)
- **Datei-Import mit Typ-Auswahl** - Beim Teilen einer Audio-Datei mit der App erscheint ein Auswahl-Sheet mit drei Optionen: Gefuehrte Meditation, Klangkulisse oder Einstimmung. Nach der Auswahl navigiert die App zur passenden Stelle und oeffnet die Edit-View. Laufende Meditationen (Timer und Gefuehrte) werden automatisch beendet (Ticket: shared-073)
- **Einstimmung Toggle statt Picker-Option** - Einstimmungs-Auswahl im Praxis-Editor nutzt jetzt ein Toggle-Pattern (an/aus) mit bedingter Liste statt einer Picker-Option "Ohne Einstimmung", konsistent mit dem Vorbereitungszeit-Muster (Ticket: shared-072)
- **Sound-Auswahl UX-Konsistenz** - Hintergrundklang- und Einstimmungs-Listen mit Overflow-Menue (3 Punkte) fuer Custom Audio, permanenten Icons links mit farblicher Hervorhebung bei Auswahl, und Hoerprobe fuer Einstimmungen beim Antippen (Ticket: shared-069)
- **Guided-Meditation-Einstellungen in globale Settings verschoben** - Vorbereitungszeit ist jetzt im Settings-Tab unter "Geführte Meditationen" konfigurierbar (Ticket: shared-070)
  - Settings-Button in der Bibliotheks-Navigationsleiste entfernt
  - Import-Button (Plus) rechtsbündig in der Navigationsleiste
  - Settings-Tab-Icon durch Guided-Meditations-Icon (`music.note.list`) ersetzt
- **Tab "Bibliothek" umbenannt zu "Meditationen"** - Tab-Label und Accessibility-Label aktualisiert, Icon von `music.note.list` auf `waveform` geaendert (Ticket: shared-071)
- **Praxis vereinfacht zu Einzelkonfiguration** - Kein Pill-Button, kein Auswahl-Sheet, keine benannten Presets mehr; stattdessen zeigt der Timer-Screen unter dem Duration-Picker tappbare Konfigurationspills, die direkt in den Editor fuehren (Ticket: shared-068)
  - Konfigurationspills zeigen: Vorbereitung, Start-Gong, Hintergrundklang, Einstimmung (falls aktiv), Intervall-Gong-Status
  - Antippen oeffnet den Praxis-Editor via Push-Navigation (kein Sheet)
  - Editor ohne Name-Feld und ohne Loeschen-Button
  - PraxisRepository vereinfacht auf `load()`/`save()`, Migration aus altem Multi-Praxis-Format erhalten
- **Praxis-Editor ersetzt Settings-Sheet** - Alle Timer-Konfigurationen leben jetzt im Praxis-Editor statt im alten Settings-Sheet (Ticket: shared-064)
- **Settings-Gear-Button entfernt** - Timer-Screen zeigt keinen Zahnrad-Button mehr

### Added (iOS)
- **Timer Completion Screen** – Nach Ablauf des Meditationstimers erscheint ein warmherziger Danke-Screen mit Herz-Icon statt der leeren 00:00-Anzeige, sanfter Slide-in-Animation und "Zurueck"-Button (Ticket: shared-052)
- **Zen-Modus** – Tab-Bar wird bei laufender Meditation fliessend ausgeblendet (Timer und Geführte Meditationen), maximale Immersion ohne ablenkende UI-Elemente (Ticket: shared-066)
- **Custom Audio Import** - Eigene Audio-Dateien (MP3, M4A, WAV) als Soundscapes und Einstimmungen importieren (Ticket: shared-065)
  - "Eigene Datei importieren" in Soundscape- und Einstimmungs-Subscreens
  - Sektion "Meine Klaenge" / "Meine Einstimmungen" mit Auswahl und Loeschen
  - Bestaetigungsdialog mit Praxis-Verwendungswarnung beim Loeschen
  - Betroffene Praxis-Presets fallen nach Loeschen auf Stille/Keine Einstimmung zurueck
  - Dauer-Erkennung automatisch; bei Fehler "Unbekannt"
- **Fullscreen Praxis-Editor** - Neuer Editor mit Sektionen fuer Vorbereitung, Audio und Gongs (Ticket: shared-064)
  - Einleitungs-, Hintergrund-Sound-, Gong- und Intervall-Gong-Subscreens im Praxis-Editor
- **Praxis-Auswahl auf Timer Screen** - Pill-Button zeigt aktive Praxis und öffnet Auswahl-Sheet mit allen gespeicherten Praxis-Presets (Ticket: shared-063)
  - Pill-Button "Praxis: [Name]" im Idle-Zustand oberhalb des Titels
  - Bottom Sheet mit allen Praxis-Presets, Checkmark bei aktiver Praxis
  - Kontextmenü pro Eintrag (Bearbeiten, Löschen mit Bestätigung)
  - "Neue Praxis erstellen" Button am Ende der Liste
  - Auswahl lädt Konfiguration (Gong, Hintergrund, Dauer etc.) und schließt Sheet
  - TimerViewModel: neue `applyPraxis()` Methode und `displayPraxisName` Computed Property
- **Geführte Meditation Abschluss-Screen** - Nach natürlichem Audio-Ende erscheint ein Completion-Screen statt der Player-Controls (Ticket: shared-053)
  - Herz-Icon (gefüllt, Indigo-Ton) in kreisförmigem Container als visuelles Zentrum
  - Headline "Vielen Dank" (DE) / "Thank you" (EN), zentriert
  - Untertitel "Schön, dass du dir diese Zeit genommen hast." (DE/EN)
  - Einziger Button "Zurück" – schliesst den Player, kehrt zur Bibliothek zurück
  - Slide-in-from-Bottom Animation mit Fade-in beim Übergang
  - Player-Controls, Slider, Zeitanzeige und X-Button im Completion-Zustand ausgeblendet
  - Kein Meditationstitel im Completion-Zustand (Stille nach der Praxis)
  - Bei manuellem Schliessen (X-Button während Playback) kein Completion-Screen
  - Visuell konsistent mit Timer-Completion-Screen (shared-052)
  - Lokalisiert (DE + EN)
- **Praxis-Datenmodell** - Neues Domain-Modell für benannte, speicherbare Timer-Konfigurationen (Ticket: shared-062)
  - `Praxis`: Immutables Value Object mit UUID, Name und allen Timer-Feldern (1:1 zu MeditationSettings)
  - `PraxisRepository`-Protokoll: CRUD-Operationen, aktive Praxis-ID, Mindestens-eine-Praxis-Invariante
  - Migration-Initializer: `Praxis(migratingFrom: MeditationSettings)` für spätere Settings-Migration
  - `shortDescription`: Berechnete Kurzbeschreibung (z.B. "10 Min · Stille · Tempelglocke · 15s Vorbereitung")
  - `UserDefaultsPraxisRepository`: JSON-basierte Persistenz in UserDefaults mit automatischer Migration bestehender MeditationSettings
- **Einstellungen-Tab** - Neuer dritter Tab mit App-weiten Einstellungen (Ticket: shared-061)
  - Tab-Bar zeigt 3 Tabs: Timer, Bibliothek, Einstellungen (`gearshape`-Icon)
  - Einstellungen-Tab: Sektion "Erscheinungsbild" (Theme, Darstellungsmodus)
  - Einstellungen-Tab: Sektion "Info & Rechtliches" (Klang-Nachweise, Datenschutz, App-Version)
  - Theme und Darstellungsmodus aus Timer-Settings-Sheet entfernt (leben nur noch im Einstellungen-Tab)
  - Klang-Nachweise: Statischer Screen mit Pixabay-Quellen aller Sounds
  - Datenschutz: Link zur App-Website
  - Tab-Auswahl wird persistiert (letzter Tab bei Neustart wiederhergestellt)

### Changed (iOS)
- **TimerDisplayState eliminiert** - Computed Properties (`formattedTime`, `isPreparation`, `isRunning`) als Extensions auf `MeditationTimer` statt eigener DisplayState-Struct
  - ViewModel haelt direkt `MeditationTimer?` (nil = idle) statt `TimerDisplayState`
  - Reducer vereinfacht zum reinen Effect Mapper: `(Action, TimerState, Settings) -> [TimerEffect]` (kein State-Return mehr)
  - `.tick`-Action im Reducer entfaellt, kein Felder-Kopieren mehr
  - State-Transitions (endGong→completed, reset→nil) als Effects modelliert — alle Entscheidungen zentral im Reducer
  - `currentAffirmationIndex` und `errorMessage` verbleiben im ViewModel (UI-only State)
  - Ticket: shared-057

### Changed (Android)
- **Datei-Import mit Typ-Auswahl** - Beim Teilen einer Audio-Datei mit der App erscheint ein Auswahl-Sheet mit drei Optionen: Gefuehrte Meditation, Klangkulisse oder Einstimmung. Laufende Meditationen werden automatisch beendet (Ticket: shared-073)
- **PraxisEditor Auto-Save** - Änderungen werden beim Zurücknavigieren automatisch gespeichert, ohne explizite Abbrechen/Fertig-Buttons (Ticket: android-073)
  - TopAppBar zeigt Zurück-Pfeil statt Cancel/Done-Buttons
  - System-Back und Zurück-Pfeil speichern Änderungen implizit (iOS Settings-Pattern)
- **Dauer-Picker aus PraxisEditor entfernt** - Die Dauer wird nur noch auf dem Timer-Hauptscreen eingestellt, nicht mehr redundant im Editor (Ticket: android-065)
- **Sound-Auswahl UX-Konsistenz** - Hintergrundklang- und Einstimmungs-Listen mit Overflow-Menue (3 Punkte) fuer Custom Audio, permanenten Icons links mit farblicher Hervorhebung bei Auswahl, und Hoerprobe fuer Einstimmungen beim Antippen (Ticket: shared-069)
- **Guided-Meditation-Einstellungen in globale Settings verschoben** - Vorbereitungszeit ist jetzt im Settings-Tab unter "Geführte Meditationen" konfigurierbar (Ticket: shared-070)
  - Settings-Button in der Bibliotheks-Navigationsleiste entfernt
  - Import-Button (Plus) rechtsbündig in der Navigationsleiste
- **Tab "Bibliothek" umbenannt zu "Meditationen"** - Tab-Label aktualisiert, Icon von `LibraryMusic` auf `GraphicEq` (Waveform) geaendert (Ticket: shared-071)
- **Einstimmungs-Einstellung als Toggle** – Statt Picker mit "Keine"-Option zeigt die Einstimmungs-Sektion jetzt einen Toggle (an/aus) mit bedingtem Inhalts-Picker, konsistent mit dem Vorbereitungszeit-Pattern (Ticket: shared-072)
- **Zen-Modus** - Bottom Navigation Bar gleitet bei laufender Meditation fliessend nach unten aus dem Bildschirm (350ms EaseInOut-Animation statt abruptem Ein-/Ausblenden) (Ticket: shared-066)
- **TimerDisplayState eliminiert** - ViewModel haelt direkt `MeditationTimer?` statt `TimerDisplayState` Data Class
  - Reducer vereinfacht zum reinen Effect Mapper: `(Action, TimerState, Int, Settings) -> List<TimerEffect>` (kein State-Return mehr)
  - `.tick`-Action und `.selectDuration`-Action aus Reducer entfernt, kein Felder-Kopieren mehr
  - State-Transitions (StartGong->Running, EndGong->Completed) als Effects modelliert
  - `currentAffirmationIndex` und `errorMessage` verbleiben im ViewModel (UI-only State)
  - Ticket: shared-057

### Added (Android)
- **Background Sound Library erweitert** - Sound-Katalog von 2 auf 5+ Optionen erweitert (Wald, Regen, Ozean, Voegel), Architektur auf datengetriebenes JSON-Muster umgestellt analog zu iOS (Ticket: android-072)
- **Timer Completion Screen** - Nach Ablauf des Meditationstimers erscheint ein warmherziger Danke-Screen mit Herz-Icon, sanfter Slide-in-Animation und "Zurueck"-Button statt der leeren 00:00-Anzeige (Ticket: shared-052)
- **Geführte Meditation Abschluss-Screen** – Nach natürlichem Audio-Ende erscheint ein Completion-Screen: Herz-Icon, "Vielen Dank", Untertitel, "Zurück"-Button mit Slide-in-Animation. Player-Controls, Slider und X-Button im Completion-Zustand ausgeblendet. Visuell konsistent mit Timer-Completion-Screen (Ticket: shared-053)
- **Fullscreen Praxis-Editor** - Neuer Editor mit Sektionen fuer Vorbereitung, Audio und Gongs (Ticket: shared-064)
  - Einleitungs-, Hintergrund-Sound-, Gong- und Intervall-Gong-Subscreens
  - Settings-Zahnrad auf Timer-Screen durch Konfigurationspills ersetzt
  - TimerViewModel laedt Konfiguration aus PraxisRepository statt SettingsRepository
- **Custom Audio Import** - Eigene Audio-Dateien (MP3, M4A, WAV) als Soundscapes und Einstimmungen importieren (Ticket: shared-065)
  - "Eigene Datei importieren" in Soundscape- und Einstimmungs-Subscreens via SAF File Picker
  - Sektion "Meine Klaenge" / "Meine Einstimmungen" mit Auswahl und Loeschen
  - Overflow-Menue (3 Punkte) pro Custom-Audio-Eintrag mit Loeschen-Option
  - Bestaetigungsdialog mit Praxis-Verwendungswarnung beim Loeschen
  - Betroffene Praxis faellt nach Loeschen auf Stille/Keine Einstimmung zurueck
  - Dauer-Erkennung automatisch via MediaMetadataRetriever; bei Fehler "Unbekannt"
  - AudioService: `startBackgroundAudioFromFile()` und `playIntroductionFromFile()` fuer Custom-Audio-Wiedergabe

### Changed (iOS & Android)
- **tick() emittiert Domain Events** - `MeditationTimer.tick()` gibt jetzt `(MeditationTimer, [TimerEvent])` zurueck statt nur `MeditationTimer`
  - Neues `TimerEvent`-Enum: `.preparationCompleted`, `.meditationCompleted`, `.intervalGongDue`
  - Neues `IntervalSettings`-Struct/Data Class fuer Intervall-Gong-Konfiguration an tick()
  - Intervall-Gong-Erkennung ins Domain-Modell verschoben (vorher im ViewModel)
  - ViewModel: `previousState`, `handlePhaseTransitions()`/`handleStateTransition()`, `checkIntervalGongs()`/`checkIntervalGong()` entfernt
  - `intervalGongPlayedForCurrentInterval` aus TimerDisplayState entfernt
  - `.intervalGongPlayed` Action entfernt, `markIntervalGongPlayed()` aus TimerServiceProtocol/TimerRepository entfernt
  - Ticket: shared-056

### Changed (iOS & Android)
- **EndGong-Phase im Timer-Zustandsautomaten** - Wenn der Timer 0 erreicht, wechselt er in `.endGong` statt direkt nach `.completed`
  - Completion-Gong spielt vollstaendig aus bevor die "Meditation beendet"-Ansicht erscheint
  - iOS: Audio-Session bleibt waehrend des End-Gongs aktiv (Keep-Alive)
  - Android: Foreground Service bleibt waehrend des End-Gongs aktiv (Notification sichtbar)
  - Neuer Zustand `.endGong` und neue Action `.endGongFinished` (Audio-Callback)
  - Neues Computed Property `isActive` auf `TimerDisplayState` (schliesst EndGong ein)
  - Ticket: shared-055

### Changed (iOS & Android)
- **Preview-Audio von Timer-Lifecycle getrennt** - Gong- und Hintergrund-Vorhoeren nutzt eigene Audio-Session (.preview / PREVIEW) statt Timer-Session
  - Kein Session-Lifecycle-Leck mehr (Preview gibt Session nach Abschluss frei)
  - Preview startet kein Keep-Alive
  - Bei Timer-Start wird laufendes Preview via Conflict Handler gestoppt
  - Ticket: shared-054
- **Keep-Alive strukturell abgesichert** - Lautlose Audio-Datei laeuft jetzt durchgehend von Timer-Start bis Timer-Ende
  - Neue API: `activateTimerSession()` / `deactivateTimerSession()` statt verstreuter Start/Stop-Aufrufe
  - Keep-Alive wird nicht mehr bei Audio-Transitions gestoppt/gestartet (Always-On)
  - Nach Audio-Unterbrechung (Anruf, Siri): Keep-Alive wird automatisch neu gestartet
  - Verhindert App-Suspension bei Audio-Transitions (bekannte Bugs Nov 2025 - Feb 2026)
  - Ticket: shared-059

### Added (iOS & Android)
- **Optionale Einleitung fuer Meditationstimer** - Gefuehrte Einleitung (z.B. Atemuebung) vor der stillen Meditation
  - Neue Section "Einleitung" in den Timer-Einstellungen (zwischen Gong und Intervallklaenge)
  - Erste Einleitung: "Atemuebung" (ID: breath, Dauer: 1:35, Deutsch)
  - Einleitung startet erst nach dem Start-Gong (sequenziell, nicht gleichzeitig)
  - Einleitungszeit zaehlt zur Gesamtmeditationszeit
  - Hintergrund-Sound und Intervall-Gongs starten erst nach der Einleitung
  - Section wird nur angezeigt wenn Einleitungen fuer die Geraetesprache verfuegbar sind
  - Bei Sprachwechsel: Fallback auf "Keine" wenn Einleitung nicht mehr verfuegbar
  - Lokalisiert (DE + EN)
  - Ticket: shared-050

## [1.10.0] - 2026-02-12

### Added (iOS & Android)
- **Flexible Intervallklänge** - Intervallklänge frei konfigurierbar (1-60 Min.)
  - Drei Modi: Regelmäßig, Nach Start, Vor Ende
  - Eigener Sound für Intervallklänge (5 Optionen inkl. "Sanfter Intervallton")
  - Stepper (1-60 Min.) statt fester 3/5/10-Auswahl
  - Eigene Lautstärkeregelung und Sound-Vorschau
  - Dynamische Beschreibung zeigt aktuelle Konfiguration
  - Eigene Settings-Section (getrennt von Gong-Section)
  - 5-Sekunden-Schutz verhindert Kollision mit Ende-Gong
  - Bestehende Einstellungen migrieren automatisch
  - Lokalisiert (DE + EN)
  - Ticket: shared-049

### Removed (iOS & Android)
- **Timer Pause-Button entfernt** - Meditation Timer hat keinen Pause/Resume-Button mehr
  - Laufende Meditation kann nur ueber Close (X) beendet werden
  - State Machine vereinfacht: Running geht nur noch zu Completed oder Idle
  - Guided Meditation Player behaelt Play/Pause (Audio-Steuerung, nicht Meditation-Pause)
  - Nicht mehr benoetigte Lokalisierungs-Strings entfernt (DE + EN)
  - Ticket: shared-048

### Improved (Android)
- **Semantische Farben in Views** - Alle Views nutzen jetzt die eigenen semantischen Farbrollen statt Material3-Defaults
  - Timer-Ring: `progress`-Farbe statt `primary`
  - Toggle/Slider inaktiver Track: `controlTrack`-Farbe (WCAG >= 3:1)
  - Card-Hintergruende: `cardBackground` statt `surfaceVariant`
  - Dark Mode: Cards zeigen subtilen Border (`cardBorder`), Light Mode: transparent
  - Betrifft: TimerFocusScreen, SettingsSheet, GuidedMeditationSettingsSheet, GuidedMeditationPlayerScreen, MeditationListItem, GeneralSettingsSection
  - Ticket: android-063

### Improved (iOS)
- **Theme-Picker Icons + Haptic Feedback** - SF-Symbol-Icons (flame, leaf.fill, moon.fill) fuer visuelle Theme-Orientierung im Picker + Haptic Feedback bei Theme-Wechsel
  - Ticket: shared-034
- **Card Visual Separation** - Meditations-Cards heben sich visuell klar vom Gradient-Hintergrund ab
  - Light Mode: weicher Drop-Shadow fuer moderne Tiefenwirkung
  - Dark Mode: subtiler Border (0.5pt, aufgehellt) fuer klare Kartengrenzen
  - Neue semantische Farbrolle `cardBorder` und Opacity-Token `opacityCardShadow`
  - Einheitlicher `cardRowBackground()` ViewModifier fuer alle Listen-Views
  - Ticket: ios-035

### Fixed (iOS)
- **Toggle/Slider Theme-Sichtbarkeit** - WCAG-konforme Kontrastfarben fuer Toggle- und Slider-Controls
  - Neue semantische Farbrolle `controlTrack` fuer inaktive Control-Tracks (>= 3:1 Kontrast gegen cardBackground)
  - Custom ToggleStyle mit Theme-Farben (On = `interactive`, Off = `controlTrack`)
  - UISlider maximumTrackTintColor folgt dem Theme via UIAppearance
  - Betrifft Timer-Settings (2 Toggles, Volume-Slider) und Guided-Meditation-Settings (1 Toggle)
  - Ticket: ios-036
- **Picker-Label Theme-Farben** - Alle Picker-Labels in den Settings nutzen jetzt das Typography-System
  - Labels "Dauer", "Gong-Ton", "Intervall", "Klang", "Farbthema" sind in allen Themes gut lesbar
  - Settings-Hint-Tooltip Shadow nutzt Theme-Farbe statt hardcodiertem Schwarz
  - Ticket: ios-034

### Added (iOS)
- **File Association ("Oeffnen mit")** - MP3- und M4A-Dateien koennen aus der Files-App direkt mit Still Moment geoeffnet werden
  - Long-Press auf Audio-Datei → "Oeffnen mit" → Still Moment
  - Import ueber bestehenden Flow (Datei kopieren, Metadaten extrahieren, Library aktualisieren)
  - Duplikat-Erkennung ueber Dateiname + Dateigroesse
  - Fehlermeldungen fuer korrupte Dateien und nicht unterstuetzte Formate
  - Lokalisiert (DE + EN)
  - Ticket: shared-045

### Improved (iOS & Android)
- **Settings Appearance Section** - Section-Header von "Allgemein" zu "Erscheinungsbild" umbenannt
  - Sichtbares Label "Darstellung" ueber dem System/Hell/Dunkel-Picker
  - Ticket: shared-042

### Added (iOS & Android)
- **Appearance Mode Selection** - Darstellungsmodus (System / Hell / Dunkel) in den Einstellungen
  - Segmented Control in der Erscheinungsbild-Section neben dem Theme-Picker
  - "System" folgt dem Geraete-Setting (bisheriges Verhalten, Default)
  - "Hell"/"Dunkel" erzwingt den jeweiligen Modus unabhaengig vom System
  - Auswahl wird persistent gespeichert und wirkt sofort
  - Lokalisiert (DE + EN)
  - Ticket: shared-041

### Added (iOS & Android)
- **Customizable Color Themes** - 3 Farbthemen (Candlelight, Forest, Moon) mit automatischem Light/Dark Mode
  - 6 Paletten (3 Themes x light/dark), Farben folgen dem System-Setting
  - Theme-Auswahl in beiden Settings-Sheets (Timer + Library)
  - Wiederverwendbare "Allgemein"-Section fuer app-weite Einstellungen
  - Sofortiger Farbwechsel bei Theme-Auswahl (Gradient, Buttons, Text, TabBar)
  - Theme-Wahl wird persistent gespeichert (iOS: @AppStorage, Android: DataStore)
  - Lokalisiert (DE + EN)
  - Ticket: shared-032
- **Finalisierte Dark Mode Paletten** - Alle 6 Paletten mit echten, abgestimmten Farbwerten
  - Candlelight: Morning Glow (light) / Evening Cocoa (dark)
  - Forest: Woodland Floor (light) / Deep Woods (dark)
  - Moon: Sterling Silver (light) / Midnight Shimmer (dark)
  - Visuell konsistent zwischen iOS und Android (identische RGB-Werte)
  - WCAG 2.1 AA Kontrast validiert (alle Kombinationen ≥ 4.5:1)
  - Ticket: shared-033, shared-035

### Technical (iOS & Android)
- **Zentrales Typography System** - Semantische Typografie-Rollen mit automatischer Dark Mode Halation-Kompensation
  - 20 TypographyRole-Rollen (Timer, Headings, Body, Settings, Player, List, Edit)
  - Font Weight wird im Dark Mode automatisch eine Stufe schwerer (verhindert optisch duennere Schrift)
  - iOS: `.themeFont(.screenTitle)` ViewModifier mit `@Environment`-Integration
  - Android: `TypographyRole.ScreenTitle.textStyle()` Composable mit Nunito Variable Font
  - Unit Tests fuer Halation-Kompensation und Rollen-Eindeutigkeit
  - Ticket: shared-037

### Technical (iOS)
- **UIKit-Control-Rebuild** - Slider und Picker(.segmented) werden bei Theme-Wechsel via `.id(theme)` neu erstellt, damit UIAppearance-Aenderungen greifen
- **Theme-Architektur** - Migration von statischen Color-Properties zu @Environment-basiertem ThemeColors-System
  - ThemeColors struct + EnvironmentKey fuer reaktive Farben
  - ThemeRootView resolved Theme + colorScheme und injiziert in Environment
  - ViewModifier-Bridge fuer ButtonStyle/Font+Theme (Call Sites unveraendert)
  - Asset Catalog Colorsets durch Inline-RGB in ThemeColors+Palettes ersetzt

### Technical (Android)
- **Theme-Architektur** - Material3 ColorScheme-Mapping fuer 3 Themes
  - 6 ColorSchemes mit resolveColorScheme() Funktion
  - Dynamische StatusBar/NavigationBar-Farben via SideEffect
  - GeneralSettingsSection als wiederverwendbare Compose-Component

## [1.9.1] - 2026-01-23 (iOS Bugfix)

### Added (iOS)
- **Fastlane deliver für App Store** - Automatisierte Store-Uploads
  - `deliver` Lane für Metadata und Screenshots konfiguriert
  - Metadata-Verzeichnis mit Beschreibungen (DE, EN-GB)
  - Release und TestFlight Upload Lanes
  - Setup-Anleitung in `dev-docs/guides/fastlane-ios.md`
  - Ticket: shared-026

### Fixed (iOS)
- **App-Suspendierung bei Vorbereitungszeit** - App bleibt jetzt im Hintergrund aktiv
  - Bug: Bei geführten Meditationen mit Vorbereitungszeit wurde die App suspendiert, wenn der Bildschirm während des Countdowns gesperrt wurde
  - Ursache: silence.m4a wurde vom System nicht als legitime Audio-Wiedergabe erkannt
  - Lösung: silence.mp3 Format + Repository-basierter Lookup für Audio-Dateinamen

- **Countdown-Timer bei gesperrtem Bildschirm** - Guided Meditation startet jetzt zuverlässig
  - Bug: Bei geführten Meditationen mit Vorbereitungszeit startete die MP3 nicht, wenn der Bildschirm während des Countdowns gesperrt wurde
  - Ursache: `Timer.publish(on: .main, in: .common)` wird von iOS pausiert bei gesperrtem Bildschirm
  - Lösung: `DispatchSourceTimer` statt `Timer.publish` in `SystemClock.swift` - läuft auf DispatchQueue und ist von RunLoop-Mode unabhängig

### Technical (iOS)
- Screenshot-Tests verwenden jetzt Launch Arguments statt ScreenshotSettingsConfigurer
  - `-DisablePreparation` Flag für konsistente Screenshots
  - Ticket: ios-030

## [1.9.0] - 2026-01-17

### Added (iOS & Android)
- **Vorbereitungszeit für geführte Meditationen** - Countdown vor MP3-Start
  - Settings-Button (⚙) in Library-Toolbar öffnet Settings-Sheet
  - Toggle für Vorbereitungszeit + Picker für Dauer (5s, 10s, 15s, 20s, 30s, 45s)
  - Countdown-Ring ersetzt Controls während Ablauf
  - Progress-Slider und Zeit-Labels bleiben während Countdown sichtbar
  - Nach Countdown: Stiller Übergang direkt zur MP3 (kein Gong)
  - Einstellung persistent (bleibt für alle MP3s erhalten)
  - Lokalisiert (DE + EN)
  - Unit Tests für State-Machine und Persistence
  - Ticket: shared-023

- **Intervall-Gong-Lautstärkeregler** - Separate Lautstärke für Intervall-Gong
  - Slider erscheint nur wenn Intervall-Gong aktiviert ist
  - Default: 75% (unabhängig von Start/Ende-Gong Lautstärke)
  - Persistiert in MeditationSettings
  - Lokalisiert (DE + EN)
  - Unit Tests für Domain Model
  - Ticket: shared-022

### Added (Shared)
- **Release Notes Skill** - `/release-notes` generiert App Store Release Notes
  - Liest [Unreleased] aus CHANGELOG.md, filtert user-facing Einträge
  - Übersetzt automatisch nach DE + EN
  - Schreibt in Fastlane-Struktur für beide Plattformen
  - Zeichenlimit-Prüfung (Android 500, iOS 4000)
  - Versions-Vorschlag nach Semantic Versioning
  - Aktualisiert CHANGELOG.md nach Bestätigung
  - Ticket: shared-030

### Added (Android)
- **Fastlane supply für Play Store** - Automatisierte Store-Uploads
  - `supply` Lane für AAB/APK Upload konfiguriert
  - Metadata-Verzeichnis mit Beschreibungen (DE, EN)
  - Screenshots-Integration aus Screengrab
  - Ticket: shared-027

### Changed (Android)
- **Screenshot-Migration** - Paparazzi → Fastlane Screengrab
  - Bessere Zuverlässigkeit und Performance
  - Konsistent mit iOS Screenshot-Workflow
  - `make screenshots` für automatische Generierung

### Added (Website)
- **Android Beta Page** - Installationsanleitung für Android Beta
  - Download-Link für APK
  - Schritt-für-Schritt Anleitung
- **Back-to-Home Links** - Navigation auf allen Unterseiten

## [1.8.0] - 2026-01-10 (Settings-Entdeckbarkeit)

### Added (iOS & Android)
- **Neues Settings-Icon** - Intuitiveres Slider-Icon ersetzt Kebab-Menü
  - iOS: `slider.horizontal.3` SF Symbol
  - Android: `Tune` Material Icon
  - Bessere Affordance für Einstellungen
  - Ticket: shared-021

- **Onboarding-Hint für Erstnutzer** - Dezenter Hinweis auf Settings
  - Erscheint beim ersten App-Start mit Fade-Animation
  - Verschwindet nach Antippen des Settings-Icons
  - Persistenz via @AppStorage (iOS) / DataStore (Android)
  - Lokalisiert: "Tippe hier für Einstellungen" / "Tap here for settings"
  - Unit Tests für Hint-State Persistenz
  - Ticket: shared-021

### Changed (Shared)
- **Dokumentation reorganisiert** - Release-Docs in eigenem Ordner
  - `dev-docs/release/` für alle Release-Dokumente
  - Bessere Übersichtlichkeit

### Changed (iOS)
- **App Store Screenshots aktualisiert** - Neue Screenshots für iPhone 17 Pro Max

## [1.7.0] - 2026-01-09 (Gong-Auswahl & Lautstärkeregler)

### Added (iOS & Android)
- **Wählbare Gong-Klänge** - 4 verschiedene Töne für Start, Ende und Intervall
  - Temple Bell, Classic Bowl, Deep Resonance, Clear Strike
  - `GongSound` Domain Model mit lokalisierten Namen (DE/EN)
  - Settings Picker mit automatischer Sound-Vorschau
  - Persistent via `MeditationSettings.startGongSoundId`
  - Vollständige Accessibility Labels und Hints
  - Ticket: shared-016

- **Background-Sound Lautstärkeregler** - Slider zur Anpassung der Hintergrund-Lautstärke
  - Slider erscheint unterhalb der Sound-Auswahl (nur wenn nicht "Stille" gewählt)
  - Slider-Bereich: 0% bis 100%, Standard: 15%
  - Preview in Settings spielt mit aktueller Slider-Lautstärke
  - Lokalisiert: "Volume" / "Lautstärke"
  - Ticket: shared-019

- **Gong-Lautstärkeregler** - Slider zur Anpassung der Gong-Lautstärke
  - Slider immer sichtbar in Gong-Sektion
  - Eine globale Einstellung für alle Gong-Typen (Start, Ende, Intervall)
  - Slider-Bereich: 0% bis 100%, Standard: 100%
  - Lautstärke bleibt bei Sound-Wechsel erhalten
  - Ticket: shared-020

- **Sound-Vorschau in Einstellungen** - 3-Sekunden-Preview mit Fade-Out
  - Preview bei Auswahl von Background-Sounds und Gong-Klängen
  - Gegenseitiges Stoppen (nur ein Preview gleichzeitig)
  - Preview stoppt automatisch beim Schliessen der Settings
  - Ticket: shared-017

- **Konfigurierbare Vorbereitungszeit** - Einstellbare Dauer vor Meditationsbeginn
  - Wählbar: 10, 15, 20 oder 30 Sekunden (Standard: 15)
  - Toggle zum Aktivieren/Deaktivieren
  - Visueller Countdown mit rotierenden Affirmationen
  - Accessibility-Announcements für Dauer
  - Ticket: ios-029, android-057

- **Lock Screen Artwork** - App-Icon bei geführten Meditationen
  - iOS: `LockScreenArtwork` Image Asset, `MPMediaItemPropertyArtwork`
  - Android: `METADATA_KEY_ART` in `MediaSessionManager`
  - Ticket: shared-018

### Changed (Android)
- **Settings Card Layout** - Verbessertes Settings-Design
  - Card-basierte Gruppierung mit visueller Hierarchie
  - Section-Titel außerhalb der Cards
  - Warm Dropdown Styling mit abgerundeten Ecken
  - Ticket: android-059, android-060

- **Sofortiges Settings-Speichern** - Änderungen werden sofort übernommen
  - Kein Save-Button mehr nötig
  - Callback-System für sofortige UI-Updates
  - Ticket: android-058

### Fixed (iOS)
- **Intervall-Gong spielt jetzt mehrfach** - Bug behoben bei dem nur der erste Intervall-Gong spielte
  - `TimerServiceProtocol.markIntervalGongPlayed()` hinzugefügt
  - `TimerViewModel` ruft nach jedem Gong beide State-Tracking-Mechanismen auf
  - Regressionstest `testIntervalGongPlaysMultipleTimes_NotJustOnce` hinzugefügt

### Fixed (Android)
- **Detekt Lint Issues** - Code-Qualitätsprobleme behoben
  - Timer Views und Code-Generierung korrigiert

### Changed (Shared)
- **Ubiquitous Language Alignment** - Einheitliche Begriffe auf beiden Plattformen
  - `countdown` → `preparation` (Vorbereitungszeit)
  - `background_sound` → `soundscape` (Klanglandschaft)
  - Lokalisierungs-Keys vereinheitlicht

## [1.4.0] - 2025-12-26 (Deine Meditations-Bibliothek)

### Added (Android)
- **MediaSession Lock Screen Controls** - Lock Screen und Notification Controls für Guided Meditations
  - `MediaSessionManager` mit MediaSessionCompat für System-Integration
  - `MeditationNotificationManager` für Media-Notifications mit Play/Pause Controls
  - `MeditationPlayerForegroundService` für Background-Playback
  - Now Playing Info auf Lock Screen (Titel, Artist)
  - Play/Pause Controls in Notification und auf Lock Screen
  - Bluetooth/Headphone Button Support (inkl. kabelgebundene Kopfhörer mit ACTION_PLAY_PAUSE)
  - Feature-Parität mit iOS MediaSession

- **Audio Player Screen UI** - Full-screen Player für Guided Meditations
  - `GuidedMeditationPlayerScreen` Composable mit Progress Ring
  - Play/Pause Button mit Icon-Toggle
  - Seek Slider mit Position/Duration Anzeige
  - Skip Forward/Backward (±10 Sekunden)
  - Meditation-Info Header (Teacher, Name)
  - Back Navigation
  - Vollständige Accessibility Labels (DE + EN)

- **TabView Navigation** - Bottom Navigation mit zwei Tabs
  - Tab 1: Timer (Icon: Timer)
  - Tab 2: Library (Icon: LibraryMusic)
  - Separate Navigation pro Tab mit State-Erhaltung
  - Bottom Bar wird im Player ausgeblendet
  - Accessibility Labels für Tab-Navigation (DE + EN)
  - Feature-Parität mit iOS TabView

- **Audio Session Coordinator** - Exklusive Audio-Verwaltung zwischen Features
  - `AudioSource` Enum für Timer und Guided Meditation
  - `AudioSessionCoordinatorProtocol` Interface in Domain Layer
  - `AudioSessionCoordinator` Singleton-Implementierung mit Hilt DI
  - Conflict Handler Pattern für sauberen Audio-Wechsel zwischen Features
  - `AudioService` integriert den Coordinator
  - Unit Tests für alle Coordinator-Funktionen
  - Feature-Parität mit iOS Audio-Koordination

### Changed (Android)
- **Player UI vereinfacht** - Progress-Ring aus Guided Meditation Player entfernt
  - Redundantes UI-Element entfernt (Ring zeigte gleiche Info wie Slider)
  - Zeit-Labels zeigen nun Position und verbleibende Zeit (wie iOS)
  - Layout konsistent mit iOS Player Design

### Fixed (Android)
- **setDataSource Fix** - Guided Meditations spielen nach App-Neustart ab
  - `AudioPlayerService.play()` verwendet nun FileDescriptor statt URI
  - `GuidedMeditationsListScreen` nimmt persistable Permission im Activity Context
  - SAF (Storage Access Framework) URIs behalten Berechtigung über App-Neustart
  - Spezifische Fehlerbehandlung für SecurityException und FileNotFoundException
  - Aussagekräftige Fehlermeldungen bei Berechtigungs- oder Dateiproblemen

- **Affirmationen i18n** - Deutsche Nutzer sehen nun deutsche Affirmationen
  - Hardcoded englische Strings aus `TimerViewModel` entfernt
  - Affirmationen werden via `getString(R.string.affirmation_*)` geladen
  - Strings waren bereits in `strings.xml` und `strings-de.xml` definiert

### Changed (iOS)
- **Timer View Responsive Layout** - Bessere Anpassung an kleine Bildschirme
  - Start-Button auf iPhone SE vollständig sichtbar
  - Flexible `Spacer(minLength:)` statt fester Mindesthöhen
  - Proportionale Größen für Bild, Picker und Timer-Kreis
  - Keine visuellen Regressionen auf größeren Geräten

## [1.3.0] - 2025-12-21 (iOS Polish & UX Improvements)

### Added (iOS)
- **Ambient Sound Fade In** - Sanftes Einblenden des Hintergrundtons beim Timer-Start
  - 3 Sekunden Fade In beim Start und Resume
  - Sofortiger Stop bei Pause, Reset und Timer-Ende
  - Native `AVAudioPlayer.setVolume(_:fadeDuration:)` API

- **Remember Last Tab** - App merkt sich zuletzt verwendeten Tab
  - Timer oder Library Tab wird gespeichert
  - Beim nächsten Start automatisch wiederhergestellt

- **Delete Confirmation Dialog** - Bestätigungsdialog vor dem Löschen
  - Verhindert versehentliches Löschen von Meditationen
  - Zeigt Meditation-Namen im Dialog
  - Roter "Löschen"-Button für destruktive Aktion

- **Play-Icon in Meditation List** - Visueller Hinweis auf Abspielen
  - Dezentes Play-Icon links vom Titel
  - Verbessert Affordance (macht klar, dass Zeile tappbar ist)

- **Simplified Empty State** - Minimalistischer Library-Leerstand
  - Icon/Emoji entfernt, nur Text + Import-Button

- **Timer Text Adjustments** - Verbesserte Textinhalte
  - Completion-Text: "danke dir" / "thank you" statt "fertig"
  - Neue Affirmation: "Du machst das wunderbar" / "You are doing wonderfully"
  - Lock Screen Hint entfernt

- **Overflow Menu** - Modernere Listenaktionen
  - ⋮ Menü statt Edit-Icon in Meditationsliste
  - Menü enthält "Bearbeiten" und "Löschen"

- **Hands-Heart Image** - Eigenes Bild im Timer Idle-State
  - Ersetzt Emoji durch 150x150pt Bild
  - Passt zum warmherzigen Design

- **Automated Screenshots** - Automatische Screenshot-Generierung
  - XCUITest-basiert mit Fastlane Snapshot
  - Generiert App Store Screenshots (6.7" iPhone)
  - Screenshots für DE + EN via `make screenshots`

### Changed (iOS)
- **Player Skip Duration** - 10 statt 15 Sekunden Skip
  - Konsistent mit Android und anderen Meditations-Apps
  - Icons: `gobackward.10` / `goforward.10`

- **Player Stop Button Removed** - Modernere UI
  - Stop-Button entfernt (Pause + Close reichen aus)
  - Konsistent mit modernen Audio-Playern

- **Timer Reducer Architecture** - Verbesserte Architektur
  - Unidirectional Data Flow (UDF) Pattern
  - State-Übergänge in Pure Function zentralisiert
  - Side Effects von State-Logik getrennt
  - Bessere Testbarkeit

### Fixed (iOS)
- **Edit Sheet Accessibility** - VoiceOver-Verbesserungen
  - Accessibility Hints für alle Formularfelder
  - "Original"-Hinweis entfernt wenn nicht relevant
  - Verbesserte Navigation mit Screen Reader

- **Library Accessibility** - Verbesserte Identifier
  - accessibilityIdentifier und Hints für Library-Elemente
  - Bessere VoiceOver-Unterstützung

## [1.2.0] - 2025-12-18 (iOS 16 Support & Bugfixes)

### Added
- **iOS 16 Support** - Erweiterte Geräte-Kompatibilität
  - Deployment Target von iOS 17.0 auf iOS 16.0 gesenkt
  - App läuft jetzt auf Geräten mit iOS 16.0+
  - Erreicht mehr Nutzer mit älteren iPhones (iPhone 8+)

### Fixed
- **Kopfhörer Play/Pause** - Kabelgebundene Kopfhörer (EarPods) funktionieren jetzt
  - `togglePlayPauseCommand` im Remote Command Center hinzugefügt
  - Play/Pause über Mittelbutton am Kabel funktioniert bei Guided Meditations
  - Betrifft auch ältere Bluetooth-Geräte und manche CarPlay-Konfigurationen

## [1.1.0] - 2025-12-14 (Verbesserungen & Bugfixes)

### Added
- **Teacher Name Autocomplete** - Schnellere Metadaten-Eingabe
  - Autovervollständigung beim Bearbeiten von Lehrer-Namen
  - Zeigt Vorschläge aus bestehenden Lehrern in der Bibliothek
  - Maximale 5 Vorschläge, case-insensitiv
  - Neue `AutocompleteTextField`-Komponente mit Unit Tests

- **Localization Automation** - Qualitätskontrolle für UI-Strings
  - `scripts/check-localization.sh` - Findet hardcodierte UI-Strings (CI-blocking)
  - `scripts/validate-localization.sh` - Validiert .strings Dateien mit Apple's `plutil`
  - Makefile-Targets: `make check-localization` und `make validate-localization`
  - Schutz gegen String-Interpolation-Bug in SwiftUI Text()

- **Localization Keys** - Neue UI-Elemente
  - 7 neue Keys für häufige UI-Patterns (common.error, common.ok, etc.)
  - Alle Keys in Deutsch und Englisch vorhanden
  - Total: 111 Lokalisierungs-Keys (100% Coverage)

### Changed
- **Responsive Layout** - Bessere Darstellung auf allen Geräten
  - GeometryReader für dynamische Spacer-Größen
  - Optimiert für iPhone SE bis iPhone 15 Pro Max
  - Deterministische Layout-Berechnung

- **Semantic Color System** - Konsistentes Farbsystem
  - Einheitliche Farbverwendung über alle Views
  - `.textPrimary`, `.textSecondary`, `.interactive` Rollen
  - Verbesserte Wartbarkeit des Designs

### Fixed
- **UI Layout** - TabBar-Überlappung behoben
  - Buttons überlappen nicht mehr mit TabBar auf kleinen Geräten
  - Minimum-Abstände garantiert (40pt zum TabBar)
  - Getestet auf iPhone 13 mini

- **GuidedMeditationEditSheet** - String-Interpolation-Bug
  - "Original:"-Label zeigte Lokalisierungs-Key statt Übersetzung
  - Korrigiert mit `String(format: NSLocalizedString(...), value)`

- **Localization** - Vollständige Lokalisierung
  - Alle UI-Strings in TimerView, GuidedMeditationsListView, etc. lokalisiert
  - Accessibility-Labels für VoiceOver korrigiert
  - Keine hardcodierten Strings mehr im Code

## [0.5.0] - 2025-11-07 (Multi-Feature Architecture mit TabView)

### Changed
- **Navigation Architecture** - Equal feature status
  - Replaced single-view app with TabView navigation
  - Two tabs: Timer and Library (Bibliothek)
  - Each tab has independent NavigationStack
  - Removed toolbar button navigation from Timer view
  - Tab labels localized in German and English
  - Full accessibility support for tab navigation

- **File Organization** - Feature-based structure
  - Reorganized Presentation/Views into feature directories:
    - `Views/Timer/` - Timer feature (TimerView, SettingsView)
    - `Views/GuidedMeditations/` - Library feature (List, Player, Edit views)
    - `Views/Shared/` - Shared UI components (ButtonStyles, Color+Theme)
  - Maintains Clean Architecture layer separation
  - Better scalability for adding 1-2 more features

### Fixed
- **TabBar Layout** - Button overlap on small devices
  - Fixed control buttons overlapping with TabBar on iPhone 13 mini
  - Replaced flexible Spacer layout with GeometryReader
  - Background gradient respects Safe Area properly
  - Minimum spacing (40pt) between buttons and TabBar
  - Deterministic layout prevents UI issues on smaller screens

### Technical
- TabView with SF Symbol icons (timer, music.note.list)
- NavigationStack (iOS 16+) for each feature tab
- GeometryReader for responsive layout across device sizes
- Tab labels use NSLocalizedString for i18n
- Accessibility labels for VoiceOver support
- Git history preserved for all moved files

### Benefits
- Timer and Library are now visually equal features
- Clearer separation of concerns
- Easier to add new features (just add new tabs)
- Better user discoverability (no hidden toolbar buttons)
- Standard iOS navigation pattern
- Consistent layout across all iPhone models

## [0.4.0] - 2025-10-26 (Geführte Meditationen)

### Added
- **Guided Meditations Feature** - Complete meditation library management
  - Import MP3 files from Files App (iCloud Drive, local storage, etc.)
  - Automatic ID3 tag extraction (Artist → Teacher, Title → Name)
  - Security-scoped bookmarks for external file access
  - List view grouped by teacher, alphabetically sorted
  - Full-featured audio player with background support
  - Edit metadata (teacher and meditation name) after import
  - Swipe-to-delete meditations from library
  - UserDefaults persistence for meditation library

- **Audio Player** - Professional playback experience
  - Play/Pause/Stop controls
  - Seek slider with real-time progress
  - Skip forward/backward (±15 seconds)
  - Current time and remaining time display
  - Background audio playback (continues when app is backgrounded)
  - Lock screen controls (play, pause, seek)
  - Now Playing metadata on lock screen
  - Audio session interruption handling (phone calls, etc.)

- **Navigation** - Seamless integration
  - Toolbar button in Timer view (music note icon)
  - Sheet-based navigation to meditation library
  - Full German/English localization
  - Warm earth tone design consistent with v0.3

- **Architecture** - Clean implementation
  - 15 new files following Clean Architecture
  - Domain: GuidedMeditation, AudioMetadata models + 3 service protocols
  - Infrastructure: AudioMetadataService, GuidedMeditationService, AudioPlayerService
  - Application: 2 ViewModels (List, Player)
  - Presentation: 3 Views (List, Player, Edit Sheet)
  - Logger extensions (Logger.guidedMeditation, Logger.audioPlayer)

### Technical
- AVFoundation for audio playback and metadata extraction
- AVPlayer with periodic time observer for progress tracking
- MediaPlayer framework for lock screen integration (MPRemoteCommandCenter, MPNowPlayingInfoCenter)
- URL bookmarkData API for security-scoped file access
- Combine publishers for reactive audio state management
- @MainActor for thread-safe ViewModel updates

## [0.3.0] - 2025-10-26 (Warmherziges Design & Internationalisierung)

### Added
- **Internationalization** - Full German and English support
  - Localized UI text (German and English)
  - Localized affirmations for countdown and running states
  - Automatic language switching based on system settings
  - Localized accessibility labels and hints
- **Warm Earth Tone Design** - Complete visual redesign
  - New color palette: Warm Cream, Warm Sand, Pale Apricot, Terracotta
  - Warm gradient backgrounds across all screens
  - SF Pro Rounded font throughout the app
  - Custom button styles with shadows and rounded corners
- **Rotating Affirmations** - Warmhearted messages
  - 4 countdown affirmations (rotates each session)
  - 5 running affirmations including silence option
  - German: "Atme sanft", "Alles darf sein", "Du bist hier, das reicht", etc.
  - English: "Breathe softly", "All is welcome", "You're here, that's enough", etc.
- **New UI Elements**
  - 🤲 Emoji on setup screen
  - "Du verdienst diese Pause" / "You deserve this pause" footer text
  - "Der Bildschirm darf ruhen 💫" / "The screen may rest 💫" during meditation
  - New color theme files (Color+Theme.swift, ButtonStyles.swift)

### Changed
- **Welcome Message** - Changed from "Still Moment" to warmhearted greeting
  - German: "Schön, dass du da bist"
  - English: "Lovely to see you"
- **Setup Screen**
  - Question: "Wie viel Zeit schenkst du dir?" / "How much time do you want to gift yourself?"
  - Redesigned with warm gradient background
  - SF Pro Rounded font for all text
- **Timer Display**
  - Thinner ring (20pt → 8pt) for elegance
  - Terracotta progress color with subtle glow effect
  - Warm sand background ring
- **Buttons**
  - Primary buttons: Terracotta with shadow (Start, Resume)
  - Secondary buttons: Warm sand background (Pause, Reset)
  - Button text: "Kurze Pause" / "Brief pause", "Neu beginnen" / "Start over"
  - Press animations (scale effect)
- **Settings Icon** - Changed from gear to ellipsis (rotated 90°)
- **All Text** - SF Pro Rounded design system-wide
  - Headings: 28-34pt, light weight
  - Body: 16pt, regular weight
  - Captions: 13-15pt, light weight
  - Buttons: 18pt, medium weight

### Technical
- Created Localizable.strings for de (German) and en (English)
- Automatic language detection from system settings
- Updated all views to use NSLocalizedString
- Added localization support to ViewModels
- Updated unit tests for new features
- Updated UI tests for localized content
- Maintained 85%+ test coverage

### Design
- Color palette based on 2024-2025 warm minimalism trend
- WCAG AA compliant contrast ratios (4.5:1+)
- warmBlack on warmCream: 10.5:1 (AAA)
- warmGray on warmCream: 4.8:1 (AA)
- Consistent spacing and padding throughout
- Smooth animations and transitions

## [0.2.0] - 2025-10-26 (Enhanced Background Audio & Interval Gongs)

### Added
- **15-Second Countdown** - Visual countdown before meditation starts
  - Countdown state in TimerState enum
  - Large countdown display in UI
  - Smooth transition to running state
- **Start Gong** - Tibetan singing bowl marks meditation beginning
  - Plays when countdown completes (countdown→running transition)
  - New `playStartGong()` method in AudioService
- **Interval Gongs** - Optional periodic reminders during meditation
  - Configurable intervals: 3, 5, or 10 minutes
  - Toggle in settings to enable/disable
  - Smart tracking to prevent duplicate gongs
  - New `playIntervalGong()` method in AudioService
  - `shouldPlayIntervalGong()` logic in MeditationTimer
- **Background Audio Modes** - Apple Guidelines compliant
  - **Silent Mode**: Volume 0.15 (15% of system volume) - keeps app active, clearly audible
  - **Forest Ambience Mode**: Volume 0.15 (15% of system volume) - audible focus aid
  - Continuous loop during meditation legitimizes background mode
  - New `BackgroundAudioMode` enum in Domain
- **Settings UI** - Configure meditation preferences
  - New `SettingsView` with Form-based UI
  - Background audio mode picker
  - Interval gongs toggle + interval picker
  - Accessible via gear icon in TimerView
  - Settings persisted to UserDefaults
- **MeditationSettings Model** - User preferences management
  - `intervalGongsEnabled: Bool`
  - `intervalMinutes: Int` (3/5/10)
  - `backgroundAudioMode: BackgroundAudioMode`
  - Codable for persistence
  - Load/save via UserDefaults

### Changed
- **AudioService** - Enhanced with multiple audio streams
  - Separate players for gongs and background audio (forest ambience)
  - Volume control based on background mode
  - No longer uses `.mixWithOthers` (primary audio)
- **TimerService** - Now handles countdown state
  - Countdown starts at 15 seconds before timer begins
  - Tick logic handles both countdown and running states
- **TimerViewModel** - State transition management
  - Detects countdown→running transition for start gong
  - Starts background audio when meditation begins
  - Stops background audio on completion/reset
  - Settings load/save management
  - Interval gong timing logic
- **Info.plist** - Background audio mode re-enabled
  - UIBackgroundModes: audio (now legitimized by continuous audio)
  - NSUserNotificationsUsageDescription for notifications

### Fixed
- Background mode now Apple Guidelines compliant
  - Added legitimate audible content (start/interval/completion gongs)
  - Continuous background audio legitimizes background mode

### Technical
- Extended AudioServiceProtocol with new methods
- Added countdown tracking to MeditationTimer
- Interval gong timing with lastIntervalGongAt property
- Settings persistence via UserDefaults
- State transition detection in ViewModel
- Updated all tests to match new protocol

## [0.1.0] - Quality Improvements

### Added
- **SwiftLint Integration** - Automated code quality checks with 50+ rules
- **SwiftFormat Integration** - Automated code formatting for consistency
- **GitHub Actions CI/CD Pipeline** - Automated testing, building, and deployment
  - Continuous Integration workflow for all pushes and PRs
  - Code coverage reporting with 80% threshold
  - Automated UI tests
  - Static code analysis
  - Coverage report comments on Pull Requests
  - Automated release workflow for tagged versions
- **Pre-commit Hooks** - Automated quality checks before each commit
  - SwiftFormat auto-formatting
  - SwiftLint validation
  - Secret detection
  - YAML validation
- **OSLog Logging Framework** - Production-ready structured logging
  - Categorized loggers (timer, audio, notifications, viewModel, etc.)
  - Performance monitoring helpers
  - Metadata support
  - Debug/Info/Warning/Error/Critical levels
- **Comprehensive Test Coverage** (~85% total)
  - AudioService unit tests (15 test cases)
  - NotificationService unit tests (15 test cases)
  - Extended domain model tests
- **Accessibility Support**
  - VoiceOver labels for all interactive elements
  - Semantic hints for buttons
  - Time announcements in natural language
  - State descriptions
- **Setup Scripts**
  - `scripts/setup-hooks.sh` - One-command development setup
  - `scripts/generate-coverage-report.sh` - Local coverage reports

### Changed
- **MeditationTimer Init** - Changed from `precondition` to throwing `init`
  - Safer error handling without runtime crashes
  - Testable validation logic
  - Added `MeditationTimerError` enum
- **Error Handling** - Replaced print statements with OSLog
  - TimerService now uses structured logging
  - AudioService logs all operations
  - ViewModel logs user interactions
- **Test Structure** - Updated all tests to handle throwing init
  - Added edge case tests for invalid durations
  - Improved test coverage for error paths

### Removed
- **ContentView.swift** - Removed unused Xcode-generated boilerplate

### Fixed
- Potential runtime crashes from invalid timer durations
- Missing test coverage for service layers
- Inconsistent code formatting

### Documentation
- Added comprehensive `IMPROVEMENTS.md` detailing all changes
- Added `CHANGELOG.md` (this file)
- Enhanced inline documentation with OSLog usage examples

## [0.1.0] - 2025-10-26 (MVP)

### Added
- Initial MVP release
- Core meditation timer functionality
  - 1-60 minute duration selection
  - Start/Pause/Resume/Reset controls
  - Circular progress indicator
  - Time display in MM:SS format
- Background audio support
  - Timer continues when screen is locked
  - Audio session configured for background playback
- Completion sound playback
  - Custom MP3 sound files
  - Tibetan singing bowl sound
- Local notifications
  - Notification on timer completion
  - Custom sound support
- Clean Architecture implementation
  - Domain Layer (business logic)
  - Application Layer (ViewModels)
  - Presentation Layer (SwiftUI Views)
  - Infrastructure Layer (services)
- MVVM architecture
- Protocol-based service design
- Combine reactive updates
- Basic unit tests
  - Domain model tests
  - ViewModel tests
  - Service tests
- UI tests for critical flows
- SwiftUI Previews for all states

### Technical Stack
- iOS 16+
- Swift 5.9+
- SwiftUI
- AVFoundation
- UserNotifications
- Combine
- XCTest

---

## Version History Summary

### v1.8.0 (Current) - Settings-Entdeckbarkeit
Neues Settings-Icon (Slider statt Kebab-Menü), Onboarding-Hint für Erstnutzer.

### v1.7.0 - Gong-Auswahl & Lautstärkeregler
Wählbare Gong-Klänge, Lautstärkeregler für Sounds und Gongs, Sound-Vorschau, konfigurierbare Vorbereitungszeit, Lock Screen Artwork.

### v1.4.0 - Deine Meditations-Bibliothek
MediaSession Lock Screen Controls, Audio Player UI, TabView Navigation, Audio Session Coordinator.

### v1.3.0 - iOS Polish & UX Improvements
Ambient Sound Fade In, Remember Last Tab, Delete Confirmation, Overflow Menu, Automated Screenshots.

### v1.2.0 - iOS 16 Support & Bugfixes
iOS 16 Support, Kopfhörer Play/Pause Fix.

### v1.1.0 - Verbesserungen & Bugfixes
Teacher Name Autocomplete, Localization Automation, Responsive Layout, Semantic Color System.

---

## How to Contribute

1. Check the [DEVELOPMENT.md](DEVELOPMENT.md) for development guidelines
2. See [IMPROVEMENTS.md](IMPROVEMENTS.md) for architecture details
3. Run `./scripts/setup-hooks.sh` to set up your environment
4. Follow the existing code style (enforced by SwiftLint/SwiftFormat)
5. Write tests for new features
6. Ensure CI passes before submitting PRs

---

## Links

- [Repository](https://github.com/stillmoment-app/stillmoment)
- [Issues](https://github.com/stillmoment-app/stillmoment/issues)
- [Development Guide](DEVELOPMENT.md)
- [Improvements Documentation](IMPROVEMENTS.md)
