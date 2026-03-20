# Implementierungsplan: shared-076 (Android)

Ticket: [shared-076](../shared/shared-076-gong-vibration.md)
Erstellt: 2026-03-18

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `domain/models/GongSound.kt` | Domain | Erweitern | `VIBRATION_ID` Konstante + Vibration-Eintrag am Ende von `allSounds` und `allIntervalSounds` |
| `domain/services/VibrationServiceProtocol.kt` | Domain | Neu | Interface mit `fun vibrate()` (400ms) und `fun vibrateShort()` (150ms) |
| `infrastructure/services/VibrationService.kt` | Infrastructure | Neu | Implementierung via `context.getSystemService(Vibrator)` + `VibrationEffect.createOneShot(400/150, DEFAULT_AMPLITUDE)` |
| `infrastructure/di/AppModule.kt` | Infrastructure | Erweitern | Binding `VibrationServiceProtocol → VibrationService` |
| `infrastructure/audio/AudioService.kt` | Infrastructure | Erweitern | `VibrationServiceProtocol` injizieren; in `playGong`, `playIntervalGong`, `playGongPreview` vor Audio-Logik prüfen: wenn `soundId == VIBRATION_ID` → `vibrationService.vibrate(); return` |
| `AndroidManifest.xml` | — | Erweitern | `<uses-permission android:name="android.permission.VIBRATE" />` |
| `presentation/ui/timer/SelectGongScreen.kt` | Presentation | Erweitern | `GongVolumeSlider` nur anzeigen wenn `gongSoundId != GongSound.VIBRATION_ID` |
| `presentation/ui/timer/IntervalGongsEditorScreen.kt` | Presentation | Erweitern | `IntervalVolumeSlider` nur anzeigen wenn `intervalSoundId != GongSound.VIBRATION_ID` |
| `domain/models/GongSoundTest.kt` | Test | Anpassen | Count-Assertions aktualisieren (4→5 für allSounds, analog allIntervalSounds); Vibration-Szenarien ergänzen |
| `infrastructure/audio/AudioServiceTest.kt` | Test | Erweitern | Mock für `VibrationServiceProtocol`; Tests für Vibrations-Branch in `playGong`/`playIntervalGong`/`playGongPreview` |

## API-Recherche

- **`VibrationEffect.createOneShot(durationMs, amplitude)`** — verfügbar ab API 26 (unser minSdk). Kein Fallback nötig. Dauer frei konfigurierbar → Start/Ende: 400ms, Intervall: 150ms.
- **`VibrationEffect.DEFAULT_AMPLITUDE`** = -1, entspricht Geräte-Default.
- **`Vibrator`** via `context.getSystemService(Vibrator::class.java)` — deprecated ab API 31 zugunsten `VibratorManager`, aber `Vibrator`-Instanz funktioniert weiterhin. Für minSdk 26 ist `Vibrator` der einfachste Weg.
- **`VIBRATE` Permission** — normal permission, keine Runtime-Anfrage nötig (nur Manifest-Eintrag).
- **`LocalHapticFeedback`** (Compose) — nur für UI-Feedback in Compose-Kontext. Für Timer-Gong aus Service heraus unbrauchbar. → `VibrationService` via Context ist der richtige Weg.

## Design-Entscheidungen

### 1. Vibration als eigenständiger Protokoll-Typ, nicht als GongSound mit leerem rawResourceName

**Trade-off:** `GongSound.VIBRATION_ID = "vibration"` ist ein string sentinel. Alternative wäre ein neuer sealed class `GongSignal.Sound|Vibration` in `MeditationSettings`.

**Entscheidung:** String sentinel. `MeditationSettings.gongSoundId: String` bleibt unverändert — kein Refactoring an Persistence, Reducer, ViewModel. Der Vibrations-Eintrag erscheint als vollwertiger `GongSound` in den Listen, `rawResourceName = ""` (wird nie als Audio-Ressource aufgelöst, weil die Vibrations-Prüfung davor greift).

### 2. VibrationServiceProtocol statt Context direkt in AudioService

**Trade-off:** Ein weiteres Protocol/Interface vs. einfache Context-Nutzung.

**Entscheidung:** `VibrationServiceProtocol` — konsistent mit dem bestehenden Muster (`MediaPlayerFactoryProtocol`, `VolumeAnimatorProtocol`). Macht `AudioService`-Tests ohne Android-Runtime möglich (Mock statt echtem Vibrator).

### 3. Vibration in AudioService, nicht in TimerViewModel/ForegroundService

`AudioService.playGong()` und `playIntervalGong()` sind die zentralen Auslösepunkte. `VibrationServiceProtocol` hat zwei Methoden: `vibrate()` (lang, 400ms) und `vibrateShort()` (kurz, 150ms). `playGong` → `vibrate()`, `playIntervalGong` → `vibrateShort()`, `playGongPreview` → je nach Kontext (Intervall-Preview = `vibrateShort`, Gong-Preview = `vibrate`).

## Fachliche Szenarien

### AK-1: Vibration erscheint im Klang-Picker

- Gegeben: User öffnet Praxis-Editor → Gong → Klang-Auswahl
  Wenn: Liste wird angezeigt
  Dann: "Vibration" erscheint als Eintrag (neben den Audio-Sounds)

- Gegeben: User öffnet Intervall-Gong-Editor → Klang-Auswahl
  Wenn: Liste wird angezeigt
  Dann: "Vibration" erscheint als Eintrag

### AK-2: Kein Audio wenn Vibration gewählt

- Gegeben: `gongSoundId = "vibration"`
  Wenn: `audioService.playGong("vibration", volume)` aufgerufen wird
  Dann: kein `MediaPlayer` wird erstellt; `vibrationService.vibrate()` wird aufgerufen

- Gegeben: `intervalSoundId = "vibration"`
  Wenn: `audioService.playIntervalGong("vibration", volume)` aufgerufen wird
  Dann: kein `MediaPlayer` wird erstellt; `vibrationService.vibrate()` wird aufgerufen

### AK-3: Lautstärke-Slider ausgeblendet

- Gegeben: User hat "Vibration" als Start/Ende-Gong gewählt
  Wenn: `SelectGongScreen` angezeigt wird
  Dann: Lautstärke-Slider ist nicht sichtbar

- Gegeben: User hat "Vibration" als Intervall-Gong gewählt
  Wenn: `IntervalGongsEditorScreen` angezeigt wird
  Dann: Lautstärke-Slider ist nicht sichtbar

### AK-4: Haptic-Preview beim Antippen von "Vibration" im Picker

- Gegeben: User tippt auf den Play-Button der "Vibration"-Zeile
  Wenn: `audioService.playGongPreview("vibration", volume)` aufgerufen wird
  Dann: `vibrationService.vibrate()` wird aufgerufen; kein `MediaPlayer` erstellt

### AK-5: Persistenz — Vibration wird korrekt gespeichert und geladen

- Gegeben: User wählt "Vibration" und speichert die Praxis
  Wenn: App neu gestartet und Praxis geladen
  Dann: `gongSoundId == "vibration"` — Vibration ist noch ausgewählt

  *(Kein eigener Code nötig — DataStore speichert den String "vibration" wie jeden anderen Sound-ID. Test verifiziert nur GongSound.find/findOrDefault.)*

### AK-6: Stumm-Modus hat keinen Einfluss auf Vibration

- Gegeben: Gerät im Stumm-Modus, Vibration als Gong gewählt
  Wenn: Timer-Gong ausgelöst wird
  Dann: Vibration funktioniert weiterhin (Vibration ignoriert Stumm-Modus auf Android)

  *(Systemverhalten — kein Code nötig, nur manueller Test.)*

## Reihenfolge der Implementierung

1. **GongSound erweitern** — Domain-Grundlage; Tests zuerst (count-Assertions auf RED setzen, dann Green)
2. **VibrationServiceProtocol + VibrationService** — Domain-Interface + Infrastructure-Impl, AppModule-Binding, Manifest
3. **AudioService erweitern** — `VibrationServiceProtocol` injecten, Vibrations-Branch in `playGong` / `playIntervalGong` / `playGongPreview`; Tests zuerst
4. **SelectGongScreen** — Slider-Visibility (kein Unit-Test; visuell via Preview)
5. **IntervalGongsEditorScreen** — Slider-Visibility (kein Unit-Test; visuell via Preview)

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `GongSoundTest` hat hart-kodierte Count-Assertions (4) | Zuerst Tests auf RED bringen, dann GongSound erweitern |
| `AudioServiceTest` muss um Mock-Constructor-Parameter erweitert werden | Konstruktor-Aufruf im Test-Setup anpassen |
| `GongSound.findOrDefault("vibration")` könnte Fallback auf defaultSound liefern, wenn Vibration nicht in `allIntervalSounds` ist | Vibration explizit in beide Listen aufnehmen; Test schreibt das fest |
