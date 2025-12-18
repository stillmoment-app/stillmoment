# Ticket iOS-001: Play/Pause über kabelgebundene Kopfhörer

**Status**: [ ] TODO
**Priorität**: MITTEL
**Aufwand**: Klein (~15 min)
**Abhängigkeiten**: Keine

---

## Beschreibung

Bei Guided Meditations funktioniert Play/Pause über kabelgebundene Apple-Kopfhörer (EarPods) nicht. Der Mittelbutton am Kabel sendet den `togglePlayPauseCommand`, der aktuell nicht konfiguriert ist.

**Aktuell konfigurierte Commands:**
- `playCommand` ✅
- `pauseCommand` ✅
- `changePlaybackPositionCommand` ✅
- `skipForwardCommand` ✅
- `skipBackwardCommand` ✅

**Fehlend:**
- `togglePlayPauseCommand` ❌

---

## Akzeptanzkriterien

- [ ] `togglePlayPauseCommand` im Remote Command Center konfiguriert
- [ ] Play/Pause über EarPods-Mittelbutton funktioniert
- [ ] Play/Pause über andere kabelgebundene Kopfhörer funktioniert
- [ ] Bestehende Lock Screen Controls weiterhin funktional

### Dokumentation
- [ ] CHANGELOG.md: Bug-Fix Eintrag

---

## Betroffene Dateien

### Zu ändern:
- `ios/StillMoment/Infrastructure/Services/AudioPlayerService.swift`
  - Methode: `setupRemoteCommandCenter()` (Zeile 169-218)

---

## Technische Details

### Ursache

Kabelgebundene Apple-Kopfhörer (EarPods) senden beim Drücken des Mittelbuttons den `togglePlayPauseCommand`, nicht separate `playCommand`/`pauseCommand`. Der aktuelle Code konfiguriert nur letztere.

### Lösung

In `setupRemoteCommandCenter()` den `togglePlayPauseCommand` hinzufügen:

```swift
func setupRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()

    // ... bestehende Commands ...

    // Toggle Play/Pause command (für kabelgebundene Kopfhörer)
    commandCenter.togglePlayPauseCommand.isEnabled = true
    commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
        guard let self else { return .commandFailed }

        if self.state.value == .playing {
            self.pause()
        } else {
            try? self.play()
        }
        return .success
    }
}
```

### Auch in `disableRemoteCommandCenter()` ergänzen:

```swift
private func disableRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()

    // ... bestehende Deaktivierungen ...

    commandCenter.togglePlayPauseCommand.isEnabled = false
    commandCenter.togglePlayPauseCommand.removeTarget(nil)
}
```

---

## Testanweisungen

```bash
# Unit Tests (bestehende sollten weiterhin grün sein)
cd ios && make test-unit
```

### Manueller Test:
1. Kabelgebundene Apple EarPods anschließen
2. Guided Meditation starten
3. Mittelbutton drücken → Audio sollte pausieren
4. Mittelbutton erneut drücken → Audio sollte fortsetzen
5. Lock Screen Controls testen → sollten weiterhin funktionieren
6. Bluetooth-Kopfhörer testen → sollten weiterhin funktionieren

---

## Hintergrund

Der `togglePlayPauseCommand` ist der primäre Command für:
- Kabelgebundene Kopfhörer mit Inline-Remote
- Einige ältere Bluetooth-Geräte
- CarPlay (in manchen Konfigurationen)

Moderne AirPods und die meisten Bluetooth-Kopfhörer senden separate `playCommand`/`pauseCommand`, weshalb das Problem dort nicht auftritt.

---

## iOS-Dokumentation

- [MPRemoteCommandCenter.togglePlayPauseCommand](https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter/1618989-toggleplaypausecommand)
