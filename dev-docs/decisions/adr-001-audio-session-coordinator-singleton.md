# ADR-001: AudioSessionCoordinator als Singleton

## Status

Akzeptiert

## Kontext

Still Moment hat mehrere Audio-Quellen, die um die iOS Audio Session konkurrieren:

- **Timer-Sounds**: Start-Gong, Intervall-Gongs, Completion-Gong
- **Background Audio**: Stille Audio-Datei fuer Timer-Background-Mode
- **Guided Meditations**: MP3-Wiedergabe aus der Bibliothek

Ohne zentrale Koordination entstehen Konflikte:

- Gong unterbricht laufende Meditation
- Background Audio funktioniert nicht zuverlaessig
- Race Conditions bei gleichzeitigen Audio-Anfragen
- Unklare Ownership der `AVAudioSession`

iOS erlaubt nur eine aktive Audio-Session-Konfiguration pro App. Mehrere Services, die unkoordiniert `AVAudioSession.sharedInstance()` konfigurieren, fuehren zu unvorhersehbarem Verhalten.

## Entscheidung

`AudioSessionCoordinator` wird als **Singleton** implementiert, der alle Audio-Session-Konfigurationen zentral verwaltet.

```swift
final class AudioSessionCoordinator: AudioSessionCoordinatorProtocol {
    static let shared = AudioSessionCoordinator()
    private init() { }

    func requestAudioSession(for source: AudioSource) throws -> Bool
    func releaseAudioSession(for source: AudioSource)
    func registerConflictHandler(for source: AudioSource, handler: @escaping () -> Void)
}
```

**Ownership-Modell**: Nur eine `AudioSource` kann die Session gleichzeitig besitzen. Bei Konflikt wird der registrierte Handler der aktuellen Source aufgerufen.

## Konsequenzen

### Positiv

- **Einziger Kontrollpunkt** fuer alle Audio-Konflikte
- **Klare Ownership** der AVAudioSession zu jedem Zeitpunkt
- **Einfaches Debugging** - alle Audio-Ereignisse an einer Stelle geloggt
- **Explizite Konfliktbehandlung** ueber registrierte Handler
- **Thread-Safety** durch interne Serial Queue

### Negativ

- **Singleton erschwert Unit-Tests** - globaler State muss beruecksichtigt werden
- **Implizite Kopplung** - Services kennen den Coordinator nicht ueber DI

### Mitigationen

1. **Protocol-Abstraktion**: `AudioSessionCoordinatorProtocol` ermoeglicht Mock-Implementierungen in Tests
2. **Constructor Injection**: ViewModels erhalten den Coordinator ueber Dependency Injection
3. **Conflict Handler Pattern**: Statt direkter Kopplung registrieren Services Handler

```swift
// In Tests
let mockCoordinator = MockAudioSessionCoordinator()
let viewModel = TimerViewModel(audioCoordinator: mockCoordinator)

// In Production
let viewModel = TimerViewModel(audioCoordinator: AudioSessionCoordinator.shared)
```

## Alternativen (verworfen)

### Option A: Kein zentraler Coordinator

Jeder Service konfiguriert die Audio Session selbst. Verworfen wegen Race Conditions und unklarer Ownership.

### Option B: Dependency Injection ohne Singleton

Coordinator als normale Instanz, die durchgereicht wird. Verworfen, weil:
- Audio Session ist inherent global (eine pro App)
- Wuerde kuenstliche Komplexitaet einfuehren
- Protocol-Abstraktion bietet bereits Testbarkeit

---

**Datum**: 2026-01-11
**Autor**: Claude Code
