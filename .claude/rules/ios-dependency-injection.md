---
paths:
  - "ios/StillMoment/**/*.swift"
  - "ios/StillMomentTests/**/*.swift"
---

# iOS: Dienste nur im App-Einstieg erzeugen

Muster: Composition Root mit Pure DI (ios-055). Alle Dienste (Services, Repositories, Provider,
Clock) werden nur in `AppDependencies.live()` (`ios/StillMoment/AppDependencies.swift`) erzeugt.
`StillMomentApp.init` ruft das genau einmal auf und reicht die Instanzen per Initializer nach unten.

- **Kein Default-Argument, das einen Dienst erzeugt.** Falsch: `waveformProvider: WaveformProviderProtocol = WaveformProvider()`. Richtig: `waveformProvider: WaveformProviderProtocol` ohne Default.
- **Warum:** Ein Default springt still ein, wenn die Weitergabe vergessen wird. Dann laufen zwei Instanzen, und zustandsbehaftete Dienste brechen (doppelte Waveform-Generierung, überschriebener Audio-Conflict-Handler). Tests übergeben Mocks immer ausdrücklich und merken es deshalb nicht. Ohne Default bricht stattdessen der Build.
- **Erlaubte Defaults:** reine Werte (Zahlen, Flags, Konfiguration) und zustandslose System-Objekte (`URLSession = .shared`, `Bundle = .main`) — sie erzeugen keine zweite Instanz.
- **Speicherorte nie als Default (ios-056).** `UserDefaults`, Basisverzeichnis und Share-Inbox kommen aus `StorageLocation` (`ios/StillMoment/StorageLocation.swift`), das `StillMomentApp.init` einmal wählt und an `live(storage:)` gibt. Dienste bekommen die Einzelteile (`userDefaults:`, `baseDirectory:`) ohne Default, `@AppStorage` immer mit `store:`. `UserDefaults.standard` und `applicationSupportDirectory` stehen nur in `StorageLocation.production()`. Sonst schreiben Tests still in die echten Daten der App.
- **Keine Dienst-Erzeugung in ViewModels, Views oder anderen Diensten.** Braucht ein neuer Bildschirm einen Dienst, wird er vom Aufrufer durchgereicht, auch über mehrere Views.
- **Wer bekommt was:** Das `AppDependencies`-Struct bekommen nur Views, die ein ViewModel bauen oder das Struct an eine solche View weiterreichen. ViewModels und Dienste bekommen es nie, sondern ihre Einzel-Abhängigkeiten.
- **Verdrahtung:** ViewModels mit geteilten Diensten bevorzugt über eine `make…`-Funktion auf `AppDependencies` bauen — nur diese Pfade prüft `AppDependenciesTests`. Direkte Feldzugriffe (`dependencies.praxisRepository`) sind erlaubt, aber ungetestet.
- **Lebensdauer:** Dienste mit app-weitem Zustand gibt es genau einmal (Feld in `AppDependencies`). Dienste, deren Zustand zu einer einzelnen Wiedergabe gehört (wie `AudioPlayerService`), entstehen pro Player über eine Fabrik-Closure (`make…`) — ebenfalls nur in `AppDependencies`.
- **Neuer Dienst:** Feld (oder Fabrik) in `AppDependencies` ergänzen, in `live()` erzeugen. Der Typname endet auf eine der Endungen der Regel `service_created_outside_composition_root` in `ios/.swiftlint.yml` — sonst erkennt der Lint ihn nicht.
- **Previews und Tests** erzeugen ihre Doubles selbst (`Preview…`, `Mock…`). `AppDependencies.live()` ist außer in `StillMomentApp` nur in Tests und in Preview-Dateien `X+Previews.swift` (unter `#if DEBUG`) erlaubt — Previews, die es brauchen, gehören dorthin, nicht in die View-Datei. Test-Helfer: `AudioService.makeForTesting()`, `MockedAppDependencies` und `TestStorage` (eigener Speicher pro Test) in `ios/StillMomentTests/Helpers/`.
- **Durchgesetzt von `make check`:** SwiftLint-Regel `service_created_outside_composition_root`, Gegenbeweis `ios/scripts/lint-selftest.sh`. Die Regel nicht per `swiftlint:disable` umgehen — Dienst stattdessen in `AppDependencies` anlegen. Einzige begründete Ausnahmen: `AudioSessionCoordinator.shared` und der interne Legacy-Leser in `UserDefaultsPraxisRepository`.
