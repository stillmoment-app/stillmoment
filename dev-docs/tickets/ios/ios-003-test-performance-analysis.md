# Ticket ios-003: Test-Performance Analyse

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Mittel (~4-6h)
**Abhaengigkeiten**: Keine
**Phase**: 5-QA
**Abgeschlossen**: 2025-12-18

---

## Beschreibung

Analyse der aktuellen Test-Ausfuehrungszeiten (Unit + UI) und Recherche
zu modernen iOS Test-Strategien. Ziel: Identifikation von Performance-
Bottlenecks und Empfehlungen zur Optimierung.

**Scope**: Nur Analyse und Empfehlungen - keine Implementierung.

**Ergebnis**: Vollstaendiger Analyse-Bericht erstellt: [ios-test-analysis-report.md](../../ios-test-analysis-report.md)

---

## Akzeptanzkriterien

### Phase 1: IST-Zustand messen
- [x] Test-Zeiten dokumentieren (Unit / UI / Gesamt)
- [x] Build-Zeit vs. Test-Ausfuehrungszeit trennen
- [x] Top 5 langsamste Test-Dateien identifizieren
- [x] Simulator-Startup-Zeit messen

### Phase 2: Bottleneck-Analyse
- [x] Timer-Tests mit Delays pruefen (sleep, XCTWait)
- [x] Setup/Teardown Overhead analysieren
- [x] Mock-Komplexitaet bewerten
- [x] Parallele Test-Ausfuehrung evaluieren

### Phase 3: State-of-the-Art Recherche
- [x] XCTest Parallel Testing Best Practices
- [x] Swift Testing Framework (Xcode 16+) evaluieren
- [x] Test Sharding Strategien dokumentieren
- [x] CI/CD Test-Optimierungen recherchieren
- [x] Async/await Test-Patterns analysieren

### Phase 4: Empfehlungen dokumentieren
- [x] Quick Wins (niedriger Aufwand, hoher Nutzen)
- [x] Mittelfristige Verbesserungen
- [x] Langfristige Architektur-Aenderungen
- [x] Aufwand/Nutzen-Matrix erstellen

### Dokumentation
- [x] Analyse-Bericht in dev-docs/ erstellen
- [x] Folge-Tickets fuer Umsetzung definieren

---

## Betroffene Dateien (nur Analyse)

### Zu analysieren:
- `ios/scripts/run-tests.sh` - Test-Ausfuehrung
- `ios/StillMomentTests/**/*.swift` - Unit Tests (16 Dateien)
- `ios/StillMomentUITests/**/*.swift` - UI Tests (2 Dateien)
- `.github/workflows/ci.yml` - CI Pipeline

### Zu erstellen:
- `dev-docs/ios-test-analysis-report.md` - Analyse-Bericht

---

## Technische Details

### Bekannte potenzielle Probleme

1. **Parallele Tests deaktiviert**: `-parallel-testing-enabled NO` in run-tests.sh
2. **Keine Test-Sharding**: Alle Tests in einem Target
3. **Sequentielle UI-Tests**: Keine Parallelisierung
4. **Simulator-Overhead**: Jeder Testlauf bootet Simulator neu

### Metriken zu erfassen

| Metrik | Befehl |
|--------|--------|
| Gesamt-Zeit | `time make test` |
| Unit-Zeit | `time make test-unit` |
| UI-Zeit | `time make test-ui` |
| Build-Zeit | xcodebuild output parsen |
| Einzeltest | `time make test-single TEST=...` |

### Recherche-Themen

1. **XCTest Parallelisierung**
   - `-parallel-testing-enabled YES`
   - `-parallel-testing-worker-count N`
   - Test-Isolation Anforderungen

2. **Swift Testing Framework (Xcode 16)**
   - Migration von XCTest
   - Performance-Vorteile
   - Kompatibilitaet mit bestehendem Code

3. **Test Sharding**
   - Aufteilung in mehrere Targets
   - CI-Matrix-Builds
   - GitHub Actions Parallelisierung

4. **Best Practices**
   - Mock vs. Stub vs. Spy Strategien
   - Async Test-Patterns
   - Test-Daten Management

---

## Testanweisungen

```bash
# Zeitmessung
cd ios
time make test        # Gesamt
time make test-unit   # Unit only
time make test-ui     # UI only

# Einzeltest Timing
time make test-single TEST=MeditationTimerTests/testStartTimer

# Build-Zeit analysieren
xcodebuild test ... 2>&1 | grep -E "(Build|Test)"
```

---

## Deliverables

1. **Analyse-Bericht** (`dev-docs/ios-test-analysis-report.md`)
   - IST-Zustand mit Metriken
   - Identifizierte Bottlenecks
   - Recherche-Ergebnisse
   - Priorisierte Empfehlungen

2. **Folge-Tickets** (in INDEX.md definieren)
   - ios-004: Quick Wins umsetzen (falls identifiziert)
   - ios-005: Swift Testing Migration (falls empfohlen)
   - etc.

---

## Referenzen

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing](https://developer.apple.com/documentation/testing/)
- [WWDC 2024: What's new in Testing](https://developer.apple.com/wwdc24/10179)
- [Parallel Testing](https://developer.apple.com/documentation/xcode/running-tests-in-parallel)
