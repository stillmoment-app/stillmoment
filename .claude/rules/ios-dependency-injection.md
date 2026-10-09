---
paths:
  - "ios/StillMoment/**/*.swift"
---

# iOS: Dienste nur im App-Einstieg erzeugen

Muster: Composition Root mit Pure DI (ios-055). Alle Dienste (Services, Repositories, Provider,
Clock) werden nur in `AppDependencies.live()` (`ios/StillMoment/AppDependencies.swift`) erzeugt.
`StillMomentApp.init` ruft das genau einmal auf und reicht die Instanzen per Initializer nach unten.

- **Kein Default-Argument, das einen Dienst erzeugt.** Falsch: `waveformProvider: WaveformProviderProtocol = WaveformProvider()`. Richtig: `waveformProvider: WaveformProviderProtocol` ohne Default.
- **Keine Dienst-Erzeugung in ViewModels, Views oder anderen Diensten.** Braucht ein neuer Bildschirm einen Dienst, wird er vom Aufrufer durchgereicht, auch über mehrere Views.
- **Wer bekommt was:** Das `AppDependencies`-Struct bekommen nur Views, die ein ViewModel bauen oder das Struct an eine solche View weiterreichen (z. B. `GuidedMeditationsListView` → `GuidedMeditationPlayerView`). ViewModels und Dienste bekommen es nie, sondern ihre Einzel-Abhängigkeiten.
- **Verdrahtung:** Die ViewModels mit geteilten Diensten bauen die `make…`-Funktionen von `AppDependencies` (`makeTimerViewModel()`, `makePlayerViewModel(…)` …), getestet in `AppDependenciesTests`. Einige Stellen greifen direkt auf Felder zu (ListView → Edit-Sheet, Settings, `InboxHandler`, `DurationConfigurer`, Screenshot-Seeding); diese Pfade decken die Tests nicht ab.
- **Neuer Dienst:** Feld in `AppDependencies` ergänzen, in `live()` erzeugen. Zustand pro Wiedergabe (wie `AudioPlayerService`) → Fabrik-Closure (`make…`) statt Feld.
- **Warum:** Ein Default springt still ein, wenn die Weitergabe vergessen wird. Dann laufen zwei Instanzen, und zustandsbehaftete Dienste brechen (doppelte Waveform-Generierung, überschriebener Audio-Conflict-Handler). Tests übergeben Mocks immer ausdrücklich und merken es deshalb nicht.
- **Ausnahmen:** `#Preview` und Tests erzeugen ihre Mocks/Preview-Dienste selbst (`Preview…`, `Mock…`). `AppDependencies.live()` ist außer in `StillMomentApp` nur in Tests und in Preview-Dateien `X+Previews.swift` (unter `#if DEBUG`) erlaubt — Previews, die es brauchen, gehören dorthin, nicht in die View-Datei. Default-Argumente für reine Werte (Zahlen, Flags, Konfiguration) sind erlaubt.
- **Durchgesetzt von `make check`:** SwiftLint-Regel `service_created_outside_composition_root` (`ios/.swiftlint.yml`; erkennt `X(`, `X.init(`, `: X = .init(` für Typen auf `…Service/Repository/Provider/Clock/GongPlayer/Resolver/Handler/Store/Coordinator/Manager` sowie `.live(`), Gegenbeweis `ios/scripts/lint-selftest.sh`. Die Regel nicht per `swiftlint:disable` umgehen — Dienst stattdessen in `AppDependencies` anlegen. Einzige begründete Ausnahmen: `AudioSessionCoordinator.shared` und der interne Legacy-Leser in `UserDefaultsPraxisRepository`.
