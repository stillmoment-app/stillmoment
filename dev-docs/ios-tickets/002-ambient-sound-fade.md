# Ticket iOS-002: Ambient Sound Fade In/Out

**Status**: [ ] TODO
**Priorität**: MITTEL
**Aufwand**: Mittel (~2-3h)
**Abhängigkeiten**: Keine

---

## Beschreibung

Der Ambient Sound (Background Audio) beim Meditation Timer startet und stoppt abrupt. Für ein sanfteres Meditationserlebnis soll der Sound langsam ein- und ausgeblendet werden (Fade In/Out).

**Anwendungsfälle:**
1. **Timer Start**: Sound fadet sanft ein (nach Countdown)
2. **Timer Ende**: Sound fadet sanft aus (vor Completion Gong)
3. **Pause ("Brief Pause")**: Sound fadet sanft aus
4. **Resume**: Sound fadet sanft ein

---

## Akzeptanzkriterien

- [ ] Fade In beim Start des Background Audio (Dauer: ~1.5 Sekunden)
- [ ] Fade Out beim Stop des Background Audio (Dauer: ~1.5 Sekunden)
- [ ] Neue Methode `pauseBackgroundAudio()` mit Fade Out
- [ ] Neue Methode `resumeBackgroundAudio()` mit Fade In
- [ ] Protocol `AudioServiceProtocol` erweitert
- [ ] TimerViewModel nutzt pause/resume bei "Brief Pause"
- [ ] Fade-Dauer konfigurierbar (Konstante)
- [ ] Unit Tests für Fade-Verhalten
- [ ] Manuelle Prüfung: Sanftes Ein-/Ausblenden hörbar

### Dokumentation
- [ ] CHANGELOG.md: Feature-Eintrag für Ambient Sound Fade

---

## Betroffene Dateien

### Zu ändern:
- `ios/StillMoment/Domain/Services/AudioServiceProtocol.swift`
- `ios/StillMoment/Infrastructure/Services/AudioService.swift`
- `ios/StillMoment/Application/ViewModels/TimerViewModel.swift`

### Tests:
- `ios/StillMomentTests/AudioServiceTests.swift`

---

## Technische Details

### AudioServiceProtocol erweitern:

```swift
protocol AudioServiceProtocol {
    // ... bestehende Methoden ...

    /// Pausiert Background Audio mit Fade Out
    func pauseBackgroundAudio()

    /// Setzt Background Audio mit Fade In fort
    func resumeBackgroundAudio()
}
```

### Fade-Implementierung in AudioService:

```swift
final class AudioService: AudioServiceProtocol {

    // Fade-Konstante
    private let fadeDuration: TimeInterval = 1.5

    func startBackgroundAudio(soundId: String) throws {
        // ... bestehender Code bis play() ...

        // Start mit Volume 0, dann Fade In
        self.backgroundAudioPlayer?.volume = 0
        self.backgroundAudioPlayer?.play()
        self.fadeIn(player: self.backgroundAudioPlayer, to: sound.volume)

        Logger.audio.info("Background audio started with fade in")
    }

    func stopBackgroundAudio() {
        Logger.audio.debug("Stopping background audio with fade out")

        guard let player = self.backgroundAudioPlayer else { return }

        // Fade Out, dann Stop
        self.fadeOut(player: player) { [weak self] in
            player.stop()
            self?.backgroundAudioPlayer = nil
            self?.deactivateAudioSessionIfIdle()
        }
    }

    func pauseBackgroundAudio() {
        Logger.audio.debug("Pausing background audio with fade out")

        guard let player = self.backgroundAudioPlayer else { return }

        self.fadeOut(player: player) {
            player.pause()
        }
    }

    func resumeBackgroundAudio() {
        Logger.audio.debug("Resuming background audio with fade in")

        guard let player = self.backgroundAudioPlayer else { return }

        player.volume = 0
        player.play()
        self.fadeIn(player: player, to: self.targetVolume)
    }

    // MARK: - Private Fade Helpers

    private var targetVolume: Float = 0.15

    private func fadeIn(player: AVAudioPlayer?, to targetVolume: Float) {
        guard let player else { return }

        self.targetVolume = targetVolume
        player.volume = 0

        let steps = 15
        let stepDuration = fadeDuration / Double(steps)
        let volumeStep = targetVolume / Float(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                player.volume = min(volumeStep * Float(i), targetVolume)
            }
        }
    }

    private func fadeOut(player: AVAudioPlayer?, completion: @escaping () -> Void) {
        guard let player else {
            completion()
            return
        }

        let startVolume = player.volume
        let steps = 15
        let stepDuration = fadeDuration / Double(steps)
        let volumeStep = startVolume / Float(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                player.volume = max(startVolume - volumeStep * Float(i), 0)

                if i == steps {
                    completion()
                }
            }
        }
    }
}
```

### TimerViewModel anpassen:

```swift
// Bei Pause
func pauseTimer() {
    // ... bestehender Code ...
    audioService.pauseBackgroundAudio()  // Statt: bleibt laufen
}

// Bei Resume
func resumeTimer() {
    // ... bestehender Code ...
    audioService.resumeBackgroundAudio()  // NEU
}

// Bei Reset (bleibt stopBackgroundAudio mit Fade)
func resetTimer() {
    // ... bestehender Code ...
    audioService.stopBackgroundAudio()  // Hat jetzt Fade Out
}
```

---

## Alternative: Timer-basierter Fade

Für präziseres Timing könnte `Timer` statt `DispatchQueue.asyncAfter` verwendet werden:

```swift
private func fadeIn(player: AVAudioPlayer?, to targetVolume: Float) {
    guard let player else { return }

    player.volume = 0
    let steps = 30
    let interval = fadeDuration / Double(steps)
    let volumeStep = targetVolume / Float(steps)

    Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
        if player.volume >= targetVolume - volumeStep {
            player.volume = targetVolume
            timer.invalidate()
        } else {
            player.volume += volumeStep
        }
    }
}
```

---

## Testanweisungen

```bash
# Unit Tests
cd ios && make test-unit

# Manueller Test:
# 1. Timer starten → Sound fadet sanft ein nach Countdown
# 2. "Brief Pause" drücken → Sound fadet sanft aus
# 3. "Resume" drücken → Sound fadet sanft ein
# 4. Timer laufen lassen bis Ende → Sound fadet aus vor Gong
# 5. Timer resetten → Sound fadet aus
```

---

## UX-Überlegungen

- **Fade-Dauer**: 1.5 Sekunden ist ein guter Kompromiss (nicht zu lang, nicht zu kurz)
- **Gong-Timing**: Completion Gong sollte NACH dem Fade Out starten
- **Interruption**: Bei App-Unterbrechung (Anruf) ist kein Fade nötig (iOS pausiert sofort)
