# Implementierungsplan: shared-076 (iOS)

Ticket: [shared-076](../shared/shared-076-gong-vibration.md)
Erstellt: 2026-03-18

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Domain/Models/GongSound.swift` | Domain | Erweitern | `vibrationId` Konstante + Vibration-Eintrag am Ende von `allSounds` und `allIntervalSounds` |
| `Infrastructure/Services/AudioService.swift` | Infrastructure | Erweitern | `import AudioToolbox`; in `playStartGong` und `playIntervalGong`: wenn `soundId == GongSound.vibrationId` → `AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)` + return |
| `Presentation/Views/Timer/GongSelectionView.swift` | Presentation | Erweitern | Vibration-Eintrag nur anzeigen wenn `GongSound.supportsVibration`; `volumeSection` ausblenden wenn Vibration gewählt |
| `Presentation/Views/Timer/IntervalGongsEditorView.swift` | Presentation | Erweitern | Vibration-Option nur anzeigen wenn `GongSound.supportsVibration`; `intervalVolumeSlider` ausblenden wenn Vibration gewählt |
| `Resources/en.lproj/Localizable.strings` | Resources | Erweitern | `"gong.vibration" = "Vibration";` |
| `Resources/de.lproj/Localizable.strings` | Resources | Erweitern | `"gong.vibration" = "Vibration";` |
| `StillMomentTests/Domain/GongSoundTests.swift` | Test | Anpassen | Count-Assertions aktualisieren (allSounds 4→5, allIntervalSounds 5→6); Vibration am Ende beider Listen verifizieren |
| `StillMomentTests/AudioServiceTests.swift` | Test | Erweitern | Tests für Vibrations-Branch in `playStartGong` und `playIntervalGong` |

## API-Recherche

- **`AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)`** aus `AudioToolbox` — funktioniert im Hintergrund wenn die App eine aktive Audio-Session hat (Background Audio Mode). **Praxistest mit Insight Timer bestätigt: Vibration auf Lock Screen ohne Notification-Banner.** Dauer ~400ms, nicht konfigurierbar.
- **Geräte-Support:** Apple-Doku: *"On the iPhone, use this constant to invoke a brief vibration. On other iOS devices, this function does nothing."* → alle iPhones, kein Alters-Cutoff. iPads: kein Vibrations-Motor. StillMoment unterstützt iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) → Vibration-Option im UI nur auf iPhone anzeigen via `UIDevice.current.userInterfaceIdiom == .phone`.
- **Kurz vs. lang (Intervall vs. Start/Ende):** Mit `AudioServicesPlaySystemSound` nicht unterscheidbar — beide ~400ms. Akzeptabel.
- **CHHapticEngine / UIImpactFeedbackGenerator:** Nur im Vordergrund — für diesen Use Case (Lock Screen) unbrauchbar.
- **Keine zusätzlichen Permissions** nötig.
- **`kSystemSoundID_Vibrate`** = 4095.

## Design-Entscheidungen

### 1. `AudioServicesPlaySystemSound` — einfach, background-kompatibel

**Entscheidung:** `AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)` direkt in `playStartGong` und `playIntervalGong`. Funktioniert im Hintergrund weil unsere App bereits Background Audio Mode aktiv hat — praxisbewiesen durch Insight Timer.

Keine Unterscheidung kurz/lang: beide ~400ms. Der Kontext macht den Unterschied für den User klar.

### 2. `supportsVibration` in Presentation-Layer — Domain bleibt UIKit-frei

StillMoment läuft auch auf iPad. iPads haben keinen Vibrations-Motor. Domain darf kein UIKit importieren — `UIDevice` gehört in die Presentation:

```swift
// In GongSelectionView und IntervalGongsEditorView
private var supportsVibration: Bool {
    UIDevice.current.userInterfaceIdiom == .phone
}
```

Die Sound-Listen (`allSounds`, `allIntervalSounds`) enthalten Vibration immer. Die Views filtern es heraus wenn `!supportsVibration`.

### 2. Vibration in `playStartGong` / `playIntervalGong`, nicht in `playGongSound`

`playGongSound` ist eine private Hilfsmethode für Audio-Playback. Vibration ist kein Audio — die Prüfung gehört in die öffentlichen Methoden, bevor `playGongSound` aufgerufen wird.

### 3. Kein separates Protocol

iOS `AudioService`-Tests sind Integration-Tests — kein Mocking nötig. Tests verifizieren dass bei soundId `"vibration"` kein AVAudioPlayer erstellt wird (kein Throw).

### 4. Vibration am Ende beider Listen — `allIntervalSounds` explizit definieren

`allIntervalSounds` ist aktuell `allSounds + [softIntervalTone]`. Mit Vibration am Ende beider Listen muss die Kurzform aufgegeben werden:

```swift
static let allSounds = [...4 Sounds..., vibrationSound]                          // Vibration am Ende ✓
static let allIntervalSounds = [...4 Sounds..., softIntervalTone, vibrationSound] // Vibration am Ende ✓
```

### 5. Kein Vibration-Preview-Button — Tap-on-Row reicht

`GongSelectionView` spielt beim Antippen bereits eine Preview ab. Für Vibration vibriert das Gerät beim Antippen — konsistent.

## Fachliche Szenarien

### AK-1: Vibration erscheint im Klang-Picker

- Gegeben: User öffnet Praxis-Editor → Gong → Klang-Auswahl
  Wenn: Liste angezeigt wird
  Dann: "Vibration" erscheint als letzter Eintrag

- Gegeben: User öffnet Intervall-Gong-Editor → Klang-Dropdown
  Wenn: Dropdown geöffnet wird
  Dann: "Vibration" erscheint als letzte Option

### AK-2: Kein Audio wenn Vibration gewählt

- Gegeben: `gongSoundId = "vibration"`
  Wenn: `audioService.playStartGong(soundId: "vibration", volume: 1.0)` aufgerufen wird
  Dann: kein `AVAudioPlayer` erstellt; `AudioServicesPlaySystemSound` ausgelöst; kein Throw

- Gegeben: `intervalSoundId = "vibration"`
  Wenn: `audioService.playIntervalGong(soundId: "vibration", volume: 0.8)` aufgerufen wird
  Dann: kein `AVAudioPlayer` erstellt; Vibration ausgelöst; kein Throw

### AK-3: Lautstärke-Slider ausgeblendet

- Gegeben: User wählt "Vibration" als Start/Ende-Gong
  Wenn: `GongSelectionView` angezeigt wird
  Dann: `volumeSection` nicht sichtbar

- Gegeben: User wählt "Vibration" als Intervall-Gong
  Wenn: `IntervalGongsEditorView` angezeigt wird
  Dann: `intervalVolumeSlider` nicht sichtbar

### AK-4: Vibration-Preview beim Antippen

- Gegeben: "Vibration" in der Gong-Auswahlliste
  Wenn: User tippt die Zeile an
  Dann: Gerät vibriert als Preview (via `playGongPreview(soundId: "vibration", ...)`)

### AK-5: Funktioniert auf Lock Screen

- Gegeben: Meditation läuft, Screen gesperrt
  Wenn: Gong-Zeitpunkt erreicht, `gongSoundId = "vibration"`
  Dann: Gerät vibriert — kein Notification-Banner sichtbar

### AK-6: `GongSound.find` / `findOrDefault` für Vibration

- `GongSound.find(byId: "vibration")` → gibt Vibration-GongSound zurück (nicht nil)
- `GongSound.findOrDefault(byId: "vibration")` → gibt Vibration-GongSound zurück (nicht defaultSound)

## Reihenfolge der Implementierung

1. **Localizable.strings** — `gong.vibration` in DE + EN
2. **GongSound** — Tests zuerst (Counts auf RED), dann Konstante + Einträge (GREEN)
3. **AudioService** — `import AudioToolbox`, Vibrations-Branch in `playStartGong` + `playIntervalGong` (Test zuerst)
4. **GongSelectionView** — `volumeSection` bedingt
5. **IntervalGongsEditorView** — `intervalVolumeSlider` bedingt

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `testAllAvailableSounds_hasFourSounds` (4) und `testAllIntervalSounds_hasFiveSounds` (5) brechen | Tests zuerst anpassen (RED), dann GongSound erweitern (GREEN) |
| `GongSound.findOrDefault(byId: "vibration")` fällt auf defaultSound zurück | Vibration in beide Listen aufnehmen; Test verifiziert Rückgabe |
| `allIntervalSounds = allSounds + [softIntervalTone]` — Vibration vor softIntervalTone | Beide Listen explizit definieren (siehe Design-Entscheidung 4) |
