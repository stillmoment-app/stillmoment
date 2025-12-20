# Testabdeckung

Sind die WICHTIGEN Pfade getestet? Nicht: Ist alles getestet?

## Kernfrage

Wenn jemand diesen Code aendert - welche Tests wuerden ihm sagen, dass er etwas kaputt gemacht hat?

## Was getestet sein MUSS

### Geschaeftslogik
- Kern-Algorithmen und Berechnungen
- State-Transitions (z.B. Timer: countdown -> running -> paused -> completed)
- Validierungen und Regeln

### Fehlerbehandlung
- Was passiert bei Invalid Input?
- Was passiert wenn externe Abhaengigkeiten fehlschlagen?
- Edge Cases die in der Praxis vorkommen

### User-kritische Pfade
- Features die der User direkt nutzt
- Flows die nicht kaputt gehen duerfen

## Was NICHT getestet sein muss

- Triviale Getter/Setter
- Reine UI-Layouts (manuell testen)
- Framework-Funktionalitaet (Apple/Google haben das getestet)
- Glue-Code ohne Logik

## Test-Qualitaet (nur wenn problematisch)

### Fragile Tests
- Test bricht bei Refactoring obwohl Verhalten gleich bleibt
- Test testet Implementierungsdetails statt Verhalten

### Sinnlose Tests
- Test ohne echte Assertion
- Test der nur prueft dass kein Crash passiert (wenn das nicht der Punkt ist)
- Test der triviale Sachen testet

### Zu viele Mocks
- Mehr als 3-4 Mocks = Warnsignal fuer schlechtes Design
- Mocks von Dingen die nicht gemockt werden muessen

## Gute Test-Namen

```swift
// Gut: Beschreibt Verhalten
func testTimerCompletesAfterDuration()
func testPausingStopsCountdown()
func testInvalidDurationThrowsError()

// Schlecht: Beschreibt Implementierung
func testTimerStateIsComplete()
func testStartMethodSetsRunning()
```

## NICHT melden

- "Coverage ist nur 75%"
- "Dieser Edge Case koennte auch getestet werden"
- "Mehr Tests waeren besser"
- Fehlende Tests fuer unkritische Pfade
