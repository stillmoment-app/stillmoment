# ADR-001: AudioSessionCoordinator als Singleton

## Status

Akzeptiert (aktualisiert 2026-10-11: seit ios-055 bekommen die Audio-Dienste den Koordinator per Initializer aus der Composition Root; seit ios-058 arbeiten Tests mit eigener Instanz. Die Singleton-Entscheidung wurde in ios-058 bestätigt.)

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

`AudioSessionCoordinator` wird als **Singleton** implementiert, der alle Audio-Session-Konfigurationen zentral verwaltet. Die Schnittstelle (Session anfordern, freigeben, Konflikt-Handler registrieren) definiert `AudioSessionCoordinatorProtocol`.

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

### Mitigationen

1. **Protocol-Abstraktion**: `AudioSessionCoordinatorProtocol` ermoeglicht Mock-Implementierungen in Tests
2. **Constructor Injection**: Nur die Composition Root (`AppDependencies.live()`) liest `shared` und reicht die Instanz an die Audio-Dienste durch; kein Dienst greift selbst global zu
3. **Eigene Instanz in Tests**: Tests mit echtem Koordinator erzeugen ihren eigenen statt `shared` zu teilen (ios-058)
4. **Conflict Handler Pattern**: Statt direkter Kopplung registrieren Services Handler

## Alternativen (verworfen)

### Option A: Kein zentraler Coordinator

Jeder Service konfiguriert die Audio Session selbst. Verworfen wegen Race Conditions und unklarer Ownership.

### Option B: Dependency Injection ohne Singleton

Coordinator als normale Instanz, die durchgereicht wird. Verworfen, weil:
- Audio Session ist inherent global (eine pro App)
- Wuerde kuenstliche Komplexitaet einfuehren
- Protocol-Abstraktion bietet bereits Testbarkeit
- Mehrere Instanzen koennten dieselbe Session unabhaengig voneinander steuern; Keep-Alive und Gongs bei gesperrtem Bildschirm haengen aber daran, dass genau ein Koordinator die Session besitzt (in ios-058 erneut abgewogen und bestaetigt)

---

**Datum**: 2026-01-11
**Autor**: Claude Code
