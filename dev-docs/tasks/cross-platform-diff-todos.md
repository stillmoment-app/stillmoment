# Cross-Platform Diff – Offene Todos

Ergebnis der Analyse vom 2026-02-26: Schritt-für-Schritt-Vergleich iOS vs. Android Meditation Timer.

**Status: Alle identifizierten Punkte abgearbeitet.**

---

## Erledigte Punkte

### Session 1 (2026-02-26)
- ✅ Android: Background-Audio Fade-in 3s → 10s (commit c8f6cf4)
- ✅ Android: `TimerViewModelTest` aufgeteilt in 6 Kategorie-Dateien (commit a43b044)
- ✅ Android: `BackgroundSound` Domain-Modell eingeführt, hardcodierte Listen entfernt (commit 5399885)

### Session 2 (2026-02-26)
- ✅ `@OptIn`-Warnings `AudioServiceTest.kt` — waren nicht (mehr) vorhanden
- ✅ `TimerViewModelRegressionTest.kt` angelegt mit Kommentar-Konvention
- ✅ `backgroundPillLabel` nutzt `BackgroundSound.findOrDefault(id).localizedName`
- ✅ `IntervalGongsEditorScreen.kt` existiert bereits, ist in PraxisEditor-Navigation eingebunden

### Session 3 (2026-02-26)

**#1 BackgroundSound Repository:**
Bewusste Abweichung dokumentiert. Companion-Object-Pattern bleibt — intern konsistent mit
`GongSound`, kein konkreter Bedarf für Repository. Begründung in `android/CLAUDE.md`.

**#2 Custom Audio Import:**
Android ist bereits vollständig auf iOS-Parity. Beide Plattformen haben:
- Import von Soundscapes (My Sounds) und Attunements (My Attunements)
- Delete mit Usage-Warning und Fallback
- Rename, Duration-Detection, Accessibility, Lokalisierung, Tests
Der Todo-Punkt war veraltet — Feature ist komplett implementiert.

**#3 TimerViewModel strukturelle Aufteilung:**
- `TimerUiState` in eigene Datei `TimerUiState.kt` extrahiert (reine data class, keine Visibility-Änderungen)
- `TimerViewModel.kt` mit 6 präzisen MARK-Sektionen strukturiert (Dispatch, Public Actions, Audio Preview, Settings Management, Timer Loop, Persistence, Lifecycle)
- Extension-Files wurden bewusst **nicht** gewählt: Kotlin-Extension-Functions in anderen Dateien können nicht auf `private` Member zugreifen. Das wäre ein Cargo-Cult aus Swift — Swift-Extensions teilen file-private Sichtbarkeit, Kotlin-Extensions nicht.
- `make test` + `make check`: BUILD SUCCESSFUL, alle Quality Gates grün

---

## Keine offenen Punkte mehr

Alle Punkte aus der ursprünglichen Analyse sind entweder umgesetzt oder als bewusste Abweichung dokumentiert.
