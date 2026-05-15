# Mechanische Findings (Auto-Fix-Kandidaten)

Findings die per Pattern erkannt und mit Standard-Fix behoben werden koennen. Diese landen im Auto-Fix-Flow (siehe SKILL.md Schritt 8).

## Wann ist ein Finding "mechanisch"?

- Eindeutiges Anti-Pattern (kein Diskussionsbedarf)
- Standard-Fix ist bekannt und projektkonform
- Fix ist lokal (eine Datei, wenige Zeilen)
- Risiko des Fixes ist klein (keine Verhaltensaenderung)

Wenn auch nur einer dieser Punkte nicht stimmt → **substanzielles Finding** (einzeln nachfragen), nicht Auto-Fix.

## iOS Forbidden Patterns

Quelle: `CLAUDE.md` Abschnitt "Forbidden patterns" + Projekt-Konventionen.

### print() statt Logger

**Pattern:** `print(...)` in Produktionscode (nicht in Tests)

**Standard-Fix:** Passenden Logger-Kanal waehlen:
- `Logger.timer` - Timer/State-Machine
- `Logger.audio` - AudioService, AudioSession, Gongs, Background Sounds
- `Logger.viewModel` - ViewModels
- `Logger.error` - Fehlerpfade
- `Logger.performance` - Performance-Messung

```swift
// BAD
print("Timer started: \(duration)")

// GOOD
Logger.timer.info("Timer started: \(duration)")
```

### Force Unwrap

**Pattern:** `!` auf Optional ohne dokumentierte Begruendung

**Standard-Fix:**
- Wenn Default sinnvoll: `?? defaultValue`
- Wenn Fehler-Pfad noetig: `guard let` mit Logger.error + early return
- Wenn programmiererrror: `assertionFailure` + sicheres Fallback

```swift
// BAD
let user = currentUser!

// GOOD
guard let user = currentUser else {
    Logger.error.error("currentUser unexpectedly nil")
    return
}
```

### Fehlendes [weak self]

**Pattern:** Closure mit `self.` ohne `[weak self]` in `.sink`, `Task`, `DispatchQueue.async`, NotificationCenter-Closures

**Standard-Fix:** `[weak self]` einfuegen, `self?.` verwenden, ggf. `guard let self else { return }`

```swift
// BAD
service.publisher.sink { value in
    self.update(value)
}

// GOOD
service.publisher.sink { [weak self] value in
    self?.update(value)
}
```

### UI-Updates off Main Thread

**Pattern:** Publisher der UI-State setzt ohne `.receive(on: DispatchQueue.main)` vor `.sink`

**Standard-Fix:** `.receive(on: DispatchQueue.main)` zwischen Publisher und Sink

```swift
// BAD
service.statePublisher.sink { [weak self] state in
    self?.uiState = state
}

// GOOD
service.statePublisher
    .receive(on: DispatchQueue.main)
    .sink { [weak self] state in
        self?.uiState = state
    }
```

### Hardcoded Strings (nicht lokalisiert)

**Pattern:** `Text("...")`, `accessibilityLabel("...")`, `Button("Starten")` mit literalem deutschem/englischem String

**Standard-Fix:** `NSLocalizedString` + Eintrag in `.strings`-Dateien (de/en)

```swift
// BAD
Text("Starten")

// GOOD
Text(NSLocalizedString("timer.start", comment: "Timer start button"))
// + Eintrag in Localizable.strings
```

**Achtung:** Wenn der String dynamische Werte enthaelt, ist `String(format:)` Pflicht (keine Swift-Interpolation):

```swift
// BAD
Text("Hallo \(name)")

// GOOD
Text(String(format: NSLocalizedString("greeting", comment: ""), name))
```

### Direkte Farbwerte

**Pattern:** `.warmBlack`, `.paleApricot`, `Color(red:green:blue:)` in Views

**Standard-Fix:** Semantische Rolle aus Design-System verwenden via `@Environment(\.themeColors)`

```swift
// BAD
.foregroundColor(.warmBlack)

// GOOD
@Environment(\.themeColors) var theme
...
.foregroundColor(theme.textPrimary)
```

Verweis: `dev-docs/reference/color-system.md`

### Empty Catch / try!

**Pattern:** `try!` in Produktionscode oder `catch { }` ohne Handling

**Standard-Fix:** `try?` mit Default oder `do/catch` mit Logger.error

```swift
// BAD
try! audioSession.setActive(true)

// GOOD
do {
    try audioSession.setActive(true)
} catch {
    Logger.audio.error("Failed to activate audio session: \(error)")
}
```

## Android Forbidden Patterns

### println / Log.d statt strukturiertes Logging

**Standard-Fix:** Projekt-Logger verwenden (siehe `android/CLAUDE.md`)

### Non-Null Assertion (!!)

**Standard-Fix:** Sicheres Pattern:
- `?: defaultValue` fuer Defaults
- `?.let { }` fuer optionales Handling
- `requireNotNull` mit aussagekraeftiger Message wenn programmiererrror

### Hardcoded Strings

**Standard-Fix:** In `strings.xml` (de + en) eintragen, `stringResource(R.string.xxx)` verwenden

### Direkte Farben

**Standard-Fix:** Theme-Color aus `MaterialTheme.colorScheme` oder Projekt-Theme verwenden

## Security-Findings (mechanisch)

Klein gehaltener Security-Pass. Bei komplexeren Themen → separater `/security-review`.

### Hartkodierte Secrets / API-Keys

**Pattern:** String-Literale mit verdaechtigen Praefixen (`sk_`, `pk_`, `AKIA`, `Bearer ...`, lange Hex-Strings)

**Standard-Fix:** In Environment-Variable / Keychain / Secure-Storage verschieben. Im Code nur Reference.

**Achtung:** Niemals "schnell" eine echte Secret im Fix einbauen. Bei Funden: User informieren, ggf. Secret rotieren.

### Unsichere Pfad-Verarbeitung

**Pattern:** `FileManager` / `File()` mit String-Konkatenation aus nutzergesteuertem Input

**Standard-Fix:** URL-API mit `appendingPathComponent`, Path-Traversal verhindern durch Whitelist von erlaubten Verzeichnissen.

### Logging von Secrets

**Pattern:** `Logger.X.info("Token: \(token)")` oder aehnlich

**Standard-Fix:** Secret-Werte entfernen, nur Existenz / Laenge / Hash loggen wenn ueberhaupt.

## Was NICHT mechanisch ist

Diese Punkte sehen oberflaechlich mechanisch aus, brauchen aber Diskussion:

| Sieht mechanisch aus | Warum nicht Auto-Fix |
|---|---|
| Methode "zu lang" | Aufteilen ist Design-Entscheidung |
| Fehlender Test | Test-Setup, Mock-Wahl, Assertion-Stil sind Entscheidungen |
| Schlechter Variablenname | Domaen-Sprache, Kontext |
| Architekturverletzung | Korrekte Loesung haengt von Layer-Design ab |
| Komplexe Bedingung vereinfachen | Lesbarkeit ist subjektiv |

## Auto-Fix-Constraints

Wenn Auto-Fix ausgeloest wird (direkt im Hauptkontext via `Edit`):

1. **Surgical:** Nur die in der Liste genannten Zeilen aendern.
2. **Keine Verhaltensaenderung:** Fix darf das Beobachtungsverhalten nicht aendern (ausser bei Bug-Fixes).
3. **Stop on uncertainty:** Bei Unklarheit (z.B. welcher Logger-Kanal passt) zurueckmelden, nicht raten.
4. **Quality Gate:** Nach allen Fixes `make -C {platform} check` muss gruen sein.
5. **TDD bei Test-Findings:** Test rot → fixen → gruen.
