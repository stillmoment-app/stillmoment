# Ticket ios-001: Play/Pause ueber kabelgebundene Kopfhoerer

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Klein (~15 min)
**Abhaengigkeiten**: Keine
**Phase**: 1-Quick Fix

---

## Beschreibung

Bei Guided Meditations funktioniert Play/Pause ueber kabelgebundene Apple-Kopfhoerer (EarPods) nicht. Der Mittelbutton am Kabel sendet den `togglePlayPauseCommand`, der aktuell nicht konfiguriert ist.

**Aktuell konfigurierte Commands:**
- `playCommand`
- `pauseCommand`
- `changePlaybackPositionCommand`
- `skipForwardCommand`
- `skipBackwardCommand`

**Fehlend:**
- `togglePlayPauseCommand`

---

## Akzeptanzkriterien

- [ ] `togglePlayPauseCommand` im Remote Command Center konfiguriert
- [ ] Play/Pause ueber EarPods-Mittelbutton funktioniert
- [ ] Play/Pause ueber andere kabelgebundene Kopfhoerer funktioniert
- [ ] Bestehende Lock Screen Controls weiterhin funktional

### Dokumentation
- [ ] CHANGELOG.md: Bug-Fix Eintrag

---

## Betroffene Dateien

### Zu aendern:
- `ios/StillMoment/Infrastructure/Services/AudioPlayerService.swift`
  - Methode: `setupRemoteCommandCenter()` (Zeile 169-218)

---

## Technische Details

### Ursache

Kabelgebundene Apple-Kopfhoerer (EarPods) senden beim Druecken des Mittelbuttons den `togglePlayPauseCommand`, nicht separate `playCommand`/`pauseCommand`. Der aktuelle Code konfiguriert nur letztere.

### Loesung

In `setupRemoteCommandCenter()` den `togglePlayPauseCommand` hinzufuegen:

```swift
func setupRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()

    // ... bestehende Commands ...

    // Toggle Play/Pause command (fuer kabelgebundene Kopfhoerer)
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

### Auch in `disableRemoteCommandCenter()` ergaenzen:

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
# Unit Tests (bestehende sollten weiterhin gruen sein)
cd ios && make test-unit
```

### Manueller Test:
1. Kabelgebundene Apple EarPods anschliessen
2. Guided Meditation starten
3. Mittelbutton druecken → Audio sollte pausieren
4. Mittelbutton erneut druecken → Audio sollte fortsetzen
5. Lock Screen Controls testen → sollten weiterhin funktionieren
6. Bluetooth-Kopfhoerer testen → sollten weiterhin funktionieren

---

## Hintergrund

Der `togglePlayPauseCommand` ist der primaere Command fuer:
- Kabelgebundene Kopfhoerer mit Inline-Remote
- Einige aeltere Bluetooth-Geraete
- CarPlay (in manchen Konfigurationen)

Moderne AirPods und die meisten Bluetooth-Kopfhoerer senden separate `playCommand`/`pauseCommand`, weshalb das Problem dort nicht auftritt.

---

## Referenzen

- [MPRemoteCommandCenter.togglePlayPauseCommand](https://developer.apple.com/documentation/mediaplayer/mpremotecommandcenter/1618989-toggleplaypausecommand)
- Siehe auch: android-010 (MediaSession Lock Screen Controls)
