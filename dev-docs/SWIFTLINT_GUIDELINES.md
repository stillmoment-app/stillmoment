# SwiftLint Guidelines

Best Practices für den Umgang mit SwiftLint-Regeln im Still Moment Projekt.

## function_body_length

**Regel:** Funktionen sollten maximal 40 Zeilen haben (exkl. Kommentare/Whitespace).

### Wann die Regel greift

```swift
// SwiftLint meldet: Function body should span 40 lines or less
func setupRemoteCommands() {
    // 50 Zeilen Code...
}
```

### Falsche Reaktion: Ausnahme hinzufügen

```swift
// swiftlint:disable:next function_body_length
func setupRemoteCommands() {
    // Problem: Erklärt nicht WARUM das okay ist
    // Hinterlässt schlechtes Gefühl beim nächsten Leser
}
```

### Richtige Frage stellen

> Ist das hier eine **Operation** oder eine **Konfiguration**?

**Operation** = Entscheidungslogik, Geschäftsregeln, komplexe Abläufe
→ Funktion ist tatsächlich zu komplex → Aufteilen

**Konfiguration/Wiring** = Setup, Registrierung, Initialisierung
→ Code ist lang, aber nicht komplex → Semantisch extrahieren

### Richtige Lösung: Semantisch extrahieren

```swift
// VORHER: Eine lange Funktion
func setupRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()

    // Play command (10 Zeilen)
    commandCenter.playCommand.isEnabled = true
    commandCenter.playCommand.addTarget { ... }

    // Pause command (10 Zeilen)
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.pauseCommand.addTarget { ... }

    // Toggle command (10 Zeilen)
    commandCenter.togglePlayPauseCommand.isEnabled = true
    commandCenter.togglePlayPauseCommand.addTarget { ... }

    // Skip commands (20 Zeilen)
    commandCenter.skipForwardCommand.isEnabled = true
    ...
}

// NACHHER: Klare Verantwortlichkeiten
func setupRemoteCommandCenter() {
    let commandCenter = MPRemoteCommandCenter.shared()
    setupPlayPauseCommands(commandCenter)
    setupSeekCommands(commandCenter)
    setupSkipCommands(commandCenter)
}

private func setupPlayPauseCommands(_ commandCenter: MPRemoteCommandCenter) {
    // play, pause, togglePlayPause
}

private func setupSeekCommands(_ commandCenter: MPRemoteCommandCenter) {
    // changePlaybackPosition
}

private func setupSkipCommands(_ commandCenter: MPRemoteCommandCenter) {
    // skipForward, skipBackward
}
```

**Vorteile:**
- Keine SwiftLint-Ausnahme nötig
- Jede Funktion hat einen klaren Zweck
- Lesbarkeit steigt
- Einfacher zu testen und zu warten

### Wann eine Ausnahme wirklich gerechtfertigt ist

1. **Framework-required Signatures**
   ```swift
   // swiftlint:disable:next function_body_length
   // UIKit lifecycle: cannot split without breaking framework contract
   func application(_ app: UIApplication,
                    didFinishLaunchingWithOptions opts: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       // ...
   }
   ```

2. **Generated/Adapter Code**
   - Code-generierte Dateien
   - Adapter für externe APIs

3. **Bewusst monolithische Operationen**
   - Wenn Aufteilung die Lesbarkeit verschlechtern würde
   - **Mit Begründung dokumentieren:**
   ```swift
   // swiftlint:disable:next function_body_length
   // Monolithic by design: transaction must be atomic, splitting would obscure the flow
   func performDatabaseMigration() {
       // ...
   }
   ```

### Warnsignal erkennen

Wenn du merkst:
1. Tool meldet ein Problem
2. Du widersprichst intuitiv
3. Du willst das Tool "ruhigstellen"

→ **Stopp!** Prüfe zuerst, ob das Design verbessert werden kann.

"Logisch zusammengehörig" ist **keine** gute Begründung für eine Ausnahme.
Die richtige Frage ist: **Kann ich das semantisch aufteilen?**

## implicitly_unwrapped_optional

**In Tests akzeptiert:**
```swift
class SomeTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var sut: SystemUnderTest!  // Standard XCTest-Pattern

    override func setUp() {
        sut = SystemUnderTest()
    }
}
```

**In Production-Code vermeiden:**
- Verwende optionals mit guard/if let
- Verwende throwing initializers
- Verwende dependency injection

## file_length / type_body_length

**In Tests oft akzeptiert:**
- Test-Dateien haben viele Testmethoden
- Jeder Test ist eine eigene, isolierte Einheit

**In Production-Code:**
- Zeichen für zu viele Verantwortlichkeiten
- Klasse aufteilen (Single Responsibility Principle)
- Extensions in separate Dateien auslagern

---

## Zusammenfassung

| Situation | Reaktion |
|-----------|----------|
| Funktion zu lang, ist Wiring-Code | Semantisch extrahieren |
| Funktion zu lang, ist komplex | Logisch aufteilen |
| Framework erfordert lange Funktion | Ausnahme mit Begründung |
| Test-Datei zu lang | Akzeptabel (viele Tests) |
| Production-Klasse zu lang | Aufteilen (SRP) |

**Goldene Regel:** SwiftLint ist dein Freund, nicht dein Gegner. Wenn du eine Ausnahme brauchst, erkläre **warum** - nicht als Entschuldigung, sondern als Dokumentation.
