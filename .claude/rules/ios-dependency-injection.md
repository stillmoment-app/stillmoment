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
- **Wer bekommt was:** Nur Views, die selbst ein ViewModel bauen, bekommen das `AppDependencies`-Struct. ViewModels und Dienste bekommen nie das Struct, sondern ihre Einzel-Abhängigkeiten.
- **Neuer Dienst:** Feld in `AppDependencies` ergänzen, in `live()` erzeugen. Zustand pro Wiedergabe (wie `AudioPlayerService`) → Fabrik-Closure (`make…`) statt Feld.
- **Warum:** Ein Default springt still ein, wenn die Weitergabe vergessen wird. Dann laufen zwei Instanzen, und zustandsbehaftete Dienste brechen (doppelte Waveform-Generierung, überschriebener Audio-Conflict-Handler). Tests übergeben Mocks immer ausdrücklich und merken es deshalb nicht.
- **Ausnahmen:** `#Preview` und Tests erzeugen ihre Mocks/Preview-Dienste selbst (`Preview…`, `Mock…`) oder nutzen `AppDependencies.live()`. Default-Argumente für reine Werte (Zahlen, Flags, Konfiguration) sind erlaubt.
- **Durchgesetzt von `make check`:** SwiftLint-Regel `service_created_outside_composition_root` (`ios/.swiftlint.yml`), Gegenbeweis `ios/scripts/lint-selftest.sh`. Die Regel nicht per `swiftlint:disable` umgehen — Dienst stattdessen in `AppDependencies` anlegen.
