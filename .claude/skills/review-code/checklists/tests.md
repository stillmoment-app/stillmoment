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

## Sinnvolle Tests (User-Perspektive)

**Tests sollen erwartetes Verhalten verifizieren, nicht den aktuellen Zustand dokumentieren.**

### Prueffragen
- Testet der Test was RICHTIG ist, oder was der Code AKTUELL tut?
- Hat der Test echten Pruefwert, oder erhoeht er nur die Coverage?
- Wuerde der Test fehlschlagen wenn das Feature kaputt geht?

### Warnzeichen fuer sinnlose Tests

| Warnzeichen | Problem |
|-------------|---------|
| Test beschreibt Implementierung statt Verhalten | Bricht bei Refactoring, faengt keine Bugs |
| Assertion wiederholt nur was der Code tut | Verifiziert Bugs statt korrektes Verhalten |
| Test prueft nur dass kein Crash passiert | Kein echter Pruefwert |
| Triviale Getter/Setter getestet | Reine Coverage-Inflation |

### Gute vs. schlechte Tests

```swift
// GUT: Prueft erwartetes Verhalten
func testPausingTimerStopsCountdownButRetainsProgress()
func testTimerAt60MinutesIsValidMaximum()

// SCHLECHT: Dokumentiert nur was Code tut (koennte Bug sein)
func testStartSetsStateToRunning()  // Was wenn running falsch ist?

// SCHLECHT: Kein Pruefwert
func testTimerInitializesWithoutCrash()
func testSettingsPropertyReturnsValue()
```

## Edge Cases aktiv identifizieren

Bei jedem Feature aktiv pruefen:

### Initialisierung
- Startzustand korrekt?
- Defaults sinnvoll?
- Erster Aufruf funktioniert?

### Boundaries
- 0, 1, Maximum
- Leere Collections
- Grenzwerte (z.B. Timer: 1 Minute, 60 Minuten)

### State-Uebergaenge
- Alle Pfade der State Machine abgedeckt?
- Unerwartete Uebergaenge behandelt?
- State nach Fehler korrekt?

### Fehler-Recovery
- Was passiert nach einem Fehler?
- Kann der User weitermachen?

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
