# Konzept: Definierter Ausgangszustand für iOS-UI-Tests

Recherche vom 08.10.2026 (Xcode 27.0, Build 27A266a). Bezug: ios-056 (UI-Tests unabhängig vom Simulator), ios-057 (Unit-Tests ohne Reste im App-Ordner).

## Kurzfazit

**Empfehlung: Der Ausgangszustand wird App-seitig über Launch-Argumente pro Test hergestellt, und zwar in einem eigenen, vom echten Datenbestand getrennten Speicherort. Der Schalter wird nur in Debug-Builds kompiliert. Simulator zurücksetzen oder App deinstallieren bleibt ein optionales Sicherheitsnetz für CI, ist aber nicht die Lösung.**

Begründung in drei Sätzen:

1. Apple selbst zeigt genau dieses Muster: in `setUp` den Gerätezustand festlegen und der App per `launchArguments`/`launchEnvironment` mitgeben, was sie beim Start tun soll. Das Beispiel aus WWDC25 lautet wörtlich `app.launchArguments = ["ClearFavoritesOnLaunch"]` ([WWDC25-344](https://developer.apple.com/videos/play/wwdc2025/344/)).
2. Große Open-Source-Apps (Firefox iOS, WordPress iOS) machen es genauso: ein Launch-Argument, das beim Start Profil bzw. Datenbank und `UserDefaults` leert (Quellen unten).
3. Ein Simulator-Reset wirkt nur einmal **pro Lauf** und nicht **pro Test**. Er kostet einen Neustart des Simulators und hilft nicht, wenn ein früherer Test im selben Lauf die Bibliothek verändert. Ein Reset würde außerdem das AK von ios-056 („grün, ohne dass der Simulator vorher zurückgesetzt wird“) nur umgehen, nicht erfüllen.

---

## Ausgangslage in Still Moment

| Stelle | Heutiger Stand | Quelle |
|--------|----------------|--------|
| UI-Test-Start | `LibraryFlowUITests`/`TimerFlowUITests` setzen nur `-AppleLanguages (en)` und `-DisablePreparation`. Nichts legt den Bibliothekszustand fest. | `ios/StillMomentUITests/LibraryFlowUITests.swift:19`, `TimerFlowUITests.swift:20` |
| Bundle-ID im UI-Test | `XCUIApplication()` startet die normale App `com.stillmoment.StillMoment`, also denselben Datenbestand, den man beim manuellen Testen auf dem Simulator nutzt. | `project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`), `scripts/test-config.sh` (`UI_TEST_SCHEME="StillMoment-UITests"`) |
| Leere Bibliothek | `-EmptyLibrary` existiert, wirkt aber nur unter `#if SCREENSHOTS_BUILD` (eigenes Target, Bundle-ID `…screenshots`). | `ios/StillMoment/StillMomentApp.swift:102-108` |
| Seeding | `TestFixtureSeeder.seedIfNeeded` seedet nur bei **leerer** Bibliothek. Ein Rest-Eintrag würde das Seeding verhindern. | `ios/StillMoment-Screenshots/TestFixtureSeeder.swift:76-85` |
| Simulator-Wahl | `DEVICE ?= iPhone 17`, erster passender Simulator, `-parallel-testing-enabled NO` | `ios/Makefile:3`, `ios/scripts/run-tests.sh:134` |
| Reset | `make simulator-reset` bzw. `make test-clean` → `xcrun simctl erase all` (Begründung dort: Spotlight-/WidgetRenderer-Abstürze, nicht Datenzustand) | `ios/Makefile:57-65`, `ios/scripts/test-helpers.sh:55` |
| Persistenz | `GuidedMeditationService` und `UserDefaultsPraxisRepository` nehmen `userDefaults:` per Init entgegen (Default `.standard`). Dateipfade werden fest aus `applicationSupportDirectory` abgeleitet. | `GuidedMeditationService.swift:24,138`, `UserDefaultsPraxisRepository.swift:20`, `CustomAudioRepository.swift:149`, `WaveformCacheService.swift:77` |
| Composition Root | Alle Dienste entstehen in `AppDependencies.live()`, aufgerufen in `StillMomentApp.init` (ios-055) | `ios/StillMoment/AppDependencies.swift`, `StillMomentApp.swift:59` |
| Build-Konfiguration der Test-Action | `Debug` in allen drei Test-Schemes | `xcschemes/StillMoment-UITests.xcscheme:27` u. a. |
| Unit-Test-Host | `TEST_HOST = …/StillMoment.app/…/StillMoment`, Unit-Tests laufen also im App-Prozess mit dem echten App-Container | `project.pbxproj:856,875` |

**Nebenbefund Fastlane (nur aus dem Quellcode abgeleitet, nicht durch einen Lauf geprüft):** Im `Snapfile` steht `reinstall_app(true)`, aber kein `app_identifier`. Laut fastlane-Quellcode fällt `app_identifier` dann auf den Wert aus dem `Appfile` zurück (`com.stillmoment.StillMoment`) ([options.rb:150-158](https://github.com/fastlane/fastlane/blob/1f8de9278e1827c8fb4c74e385c0a0e8a93603b6/snapshot/lib/snapshot/options.rb#L150-L158)). Die Screenshot-App hat aber die Bundle-ID `com.stillmoment.StillMoment.screenshots`. Vermutlich deinstalliert `make screenshots` deshalb die **normale** App auf „iPhone 17 Pro Max“ und nicht die Screenshot-App. Der Kommentar „Clean app install per language run“ im Snapfile träfe dann nicht zu. Das sollte jemand mit einem Blick auf die fastlane-Logausgabe (`xcrun simctl uninstall … <bundle id>`) bestätigen.

---

## Optionen im Vergleich

| Ansatz | Was es löst | Kosten/Laufzeit | Risiken | Quelle |
|--------|-------------|-----------------|---------|--------|
| **Simulator löschen** (`xcrun simctl erase <udid>` / `all`, `make simulator-reset`) | Setzt **alle** Inhalte und Einstellungen des Geräts zurück: Apps, Daten, Berechtigungen, Tastatur-Hinweise | Simulator muss heruntergefahren und neu gebootet werden. Messwerte für Still Moment liegen nicht vor (Einschätzung: zweistelliger Sekundenbereich pro Lauf). | Wirkt nur einmal pro Lauf, nicht pro Test. Löscht auch manuelle Testdaten des Entwicklers. `erase all` trifft alle Simulatoren. Verdeckt Tests, die selbst keinen Zustand festlegen. | `xcrun simctl help erase`: „Erase a device's contents and settings. Usage: simctl erase <device> … \| all“ |
| **Frischer Simulator pro Lauf** (`simctl create` / `simctl clone`) | Garantiert leeres Gerät, ohne vorhandene Simulatoren anzufassen | Erstellen und Booten bei jedem Lauf; Aufräumen nötig | Gerätename/UDID ändern sich, Skripte müssen die UDID durchreichen; verwaiste Simulatoren bei Abbruch | `xcrun simctl help create`, `xcrun simctl help clone` |
| **Parallel Testing (Klone)** | Verteilt Testklassen auf von Xcode verwaltete Simulator-Klone | Schneller bei vielen Klassen | **Löst das Zustandsproblem nicht von selbst.** Ob ein Klon Daten des Originals übernimmt, ist bei Apple nicht nachlesbar (siehe unten). Tests müssen ohnehin unabhängig sein. | `xcodebuild -help`: `-parallel-testing-enabled`, `-parallel-testing-worker-count`; [WWDC19-413](https://developer.apple.com/videos/play/wwdc2019/413/) („running all of its test in parallel on multiple clone simulators“) |
| **App deinstallieren** (`xcrun simctl uninstall <udid> <bundle id>`, fastlane `reinstall_app`) | Entfernt die App samt Daten-Container. Der nächste Start ist eine Erstinstallation. | Billig (Sekunden), die App muss danach neu installiert werden (macht `xcodebuild test` ohnehin) | Nur einmal pro Lauf. Löscht manuelle Testdaten. App-Group-Container (`group.com.stillmoment`, ShareInbox) bleibt möglicherweise bestehen (nicht geprüft). Falsche Bundle-ID wirkt still auf die falsche App (siehe Nebenbefund). | `xcrun simctl help uninstall`; [fastlane scan runner.rb:46-52](https://github.com/fastlane/fastlane/blob/1f8de9278e1827c8fb4c74e385c0a0e8a93603b6/scan/lib/scan/runner.rb#L46-L52) |
| **Container von außen leeren** (`simctl get_app_container <udid> <id> data` + Dateien löschen) | Gezielt nur die App-Daten | Billig | Greift in Interna ein (Pfadstruktur, `Library/Preferences/*.plist` wird von `cfprefsd` gecacht, Einschätzung). Kein dokumentierter Reset-Weg. | `xcrun simctl help get_app_container` |
| **App-seitiger Reset per Launch-Argument** (`-ResetLibrary`, `-EmptyLibrary`) | Legt den Zustand **pro Test** fest. Funktioniert auf jedem Simulator, lokal und in CI. | Praktisch kostenlos (ein Argument, ein Lesezugriff beim Start) | Schalter darf nicht im Release-Build wirken. Löscht weiterhin die Daten der Dev-App, wenn er auf den echten Speicher zielt. | [XCUIApplication.launchArguments](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/launcharguments); [WWDC25-344](https://developer.apple.com/videos/play/wwdc2025/344/); Firefox, WordPress (unten) |
| **App-seitig getrennter Speicher im Testmodus** (eigene `UserDefaults(suiteName:)`, eigenes Verzeichnis, optional In-Memory) | Wie oben, zusätzlich bleiben die echten Daten der Dev-App unberührt. Ein frischer Zustand entsteht durch Leeren nur der Test-Suite. | Gering; braucht Injektion von Suite und Basisverzeichnis in die Dienste | Testmodus weicht im Speicherort von Produktion ab, Migrationspfade werden dadurch nicht getestet (Einschätzung). | [UserDefaults.init(suiteName:)](https://developer.apple.com/documentation/foundation/userdefaults/init(suitename:)), [removePersistentDomain(forName:)](https://developer.apple.com/documentation/foundation/userdefaults/removepersistentdomain(forname:)); Firefox `testProfile` (unten) |
| **Fixtures seeden per Launch-Argument** | Definierter, **nicht leerer** Zustand (z. B. Beispiel-Meditationen) | Gering | Seeding „nur wenn leer“ (wie heute) ist nicht deterministisch, wenn Reste da sind. Richtig ist erst leeren, dann seeden. | `TestFixtureSeeder.swift:76-85` (eigener Code) |
| **Berechtigungen zurücksetzen** (`XCUIApplication.resetAuthorizationStatus(for:)`, `simctl privacy … reset`) | Nur Berechtigungsdialoge (Fotos, Mikrofon …), keine App-Daten | Beendet ggf. den App-Prozess | Für Still Moment derzeit nicht relevant (keine geschützten Ressourcen in UI-Tests, Einschätzung) | [resetAuthorizationStatus(for:)](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/resetauthorizationstatus(for:)); [WWDC20-10220](https://developer.apple.com/videos/play/wwdc2020/10220/); `xcrun simctl help privacy` |

---

## Apples Position

**Was Apple ausdrücklich sagt:**

- **Zustand in `setUp` herstellen, Parameter per Launch-Argument übergeben.** WWDC25 „Record, replay, and review: UI automation with Xcode“: „It can be useful to use the setup instance method of an XCTestCase to make sure the device is in the same state in future runs. […] Before launching my app, I can use properties like launchArguments and launchEnvironment to have my app use those parameters when the launch method is called.“ Der Beispielcode setzt `app.launchArguments = ["ClearFavoritesOnLaunch"]`, also genau einen App-seitigen Reset-Schalter ([WWDC25-344](https://developer.apple.com/videos/play/wwdc2025/344/), Abschnitt 16:54).
- **Tests hinterlassen nichts.** WWDC19 „Testing in Xcode“: „tearDown can be used to clean up any changes you've made to the data or the global state of your app, to make sure your test leaves nothing behind that could impact subsequent tests.“ Außerdem: Zufällige Reihenfolge „is really helpful for finding hidden dependencies between your test methods“ ([WWDC19-413](https://developer.apple.com/videos/play/wwdc2019/413/)).
- **Testdaten über Argumente/Umgebung umschalten.** Ebenfalls WWDC19-413: Argumente oder Umgebungsvariablen variieren „can be helpful if the code that you're testing needs to modify or fake certain things when you're testing such as using a testing version of your web server or maybe mock data sets.“ Test-Plan-Konfigurationen können „Arguments Passed on Launch“ und „Environment Variables“ setzen ([Improving code assessment by organizing tests into test plans](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback)).
- **Semantik von `launchArguments`/`launchEnvironment`:** Ohne Änderung sind es die Argumente, die Xcode übergibt. Änderungen nach dem Start wirken erst beim nächsten `launch()` ([launchArguments](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/launcharguments), [launchEnvironment](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/launchenvironment)). Hinweis: Die Doku liegt seit Xcode 16.3 unter dem Framework **XCUIAutomation**, die alten `xctest/…`-URLs liefern nichts mehr.
- **`-Key Wert`-Argumente landen in der Argument-Domain von `UserDefaults`:** „The defaults system stores those overrides in this domain, which is volatile and resets with each app launch. Values in this domain override most other domains“ ([UserDefaults.argumentDomain](https://developer.apple.com/documentation/foundation/userdefaults/argumentdomain)). Das ist der Mechanismus hinter `-AppleLanguages (en)` und dem Snapfile-`-appearanceMode`. Er wirkt auch im Release-Build, ist aber flüchtig und überschreibt nichts dauerhaft.
- **Systemzustand Berechtigungen:** „the user response is stored as system state so after the first such interaction the device is no longer in a clean state“. Lösung ist `resetAuthorizationStatus(for:)` (seit iOS 13.4), das den App-Prozess beenden kann ([WWDC20-10220](https://developer.apple.com/videos/play/wwdc2020/10220/)).
- **Unit-Tests mit Host-App: Start-Arbeit überspringen.** WWDC18 „Testing Tips & Tricks“: „XCTest waits until your app delegates did finish launching method returns before beginning to run tests […] detect when your app is launched as a test runner and avoid this work.“ Mittel: eigene Umgebungsvariable oder Launch-Argument in der Test-Action des Schemes. Dazu der Hinweis „be sure that the code you skip truly is nonessential“ ([WWDC18-417](https://developer.apple.com/videos/play/wwdc2018/417/)).
- **Host-App oder nicht:** Apple DTS (Quinn): Mit `Test Host` startet Xcode die App und lädt das Test-Bundle hinein, ohne ihn einen eigenen Test-Runner. „it might make sense to have two test targets: one with a host application and one without“ ([Forum 751559](https://developer.apple.com/forums/thread/751559)). Build-Setting-Referenz: `TEST_HOST` „Only specify this setting if testing an application or other executable“ ([Build settings reference](https://developer.apple.com/documentation/xcode/build-settings-reference#Test-Host)).
- **Compile-Flags:** `SWIFT_ACTIVE_COMPILATION_CONDITIONS` ist „A list of compilation conditions to enable for conditional compilation expressions“ ([Build settings reference](https://developer.apple.com/documentation/xcode/build-settings-reference)). Daran hängen `#if DEBUG` bzw. eigene Flags wie `SCREENSHOTS_BUILD`.

**Was ich bei Apple nicht gefunden habe:**

- Keine Apple-Quelle, die `simctl erase` oder Deinstallation vor UI-Tests als Standard empfiehlt. `simctl` dokumentiert die Befehle nur (`xcrun simctl help …`).
- Kein Xcode- oder Test-Plan-Schalter „App-Daten vor dem Test löschen“.
- Ob Parallel-Testing-Klone die App-Daten des Original-Simulators übernehmen: Die WWDC18-Session „What's New in Testing“ (403), die das Feature eingeführt hat, ist auf developer.apple.com nicht mehr abrufbar (Weiterleitung auf die Übersichtsseite). Laut Community-Notizen dient der Original-Simulator nur als Vorlage für die Klone ([wwdcnotes.com/notes/wwdc18/403](https://wwdcnotes.com/notes/wwdc18/403)). **Nur sekundär belegt.**
- `xcodebuild` bietet keinen Reset-Schalter. Relevant sind nur `-parallel-testing-enabled`, `-parallel-testing-worker-count`, `-testPlan`, `-test-iterations`, `-retry-tests-on-failure`, `-run-tests-until-failure` und `-test-repetition-relaunch-enabled` (`xcodebuild -help`). Wiederholungen mit `-run-tests-until-failure` eignen sich gut, um Zustandsabhängigkeiten aufzudecken (Einschätzung).

---

## Praxis in Fastlane und Open-Source-Projekten

### Fastlane

- **snapshot:** `erase_simulator` (Default `false`) ruft `xcrun simctl erase <udid>` auf. `reinstall_app` (Default `false`) deinstalliert vorher die App, „no need to reinstall if device has been erased“ ([simulator_launcher_base.rb:62-76, 159-172](https://github.com/fastlane/fastlane/blob/1f8de9278e1827c8fb4c74e385c0a0e8a93603b6/snapshot/lib/snapshot/simulator_launchers/simulator_launcher_base.rb#L62-L76)). Beides geschieht **einmal pro Gerät und Sprache**, nicht pro Test. `app_identifier` fällt auf das Appfile zurück ([options.rb:150-158](https://github.com/fastlane/fastlane/blob/1f8de9278e1827c8fb4c74e385c0a0e8a93603b6/snapshot/lib/snapshot/options.rb#L150-L158)).
- **snapshot erkennt sich App-seitig über Launch-Argumente:** `SnapshotHelper` hängt `-FASTLANE_SNAPSHOT YES -ui_testing` an (`ios/StillMomentUITests/SnapshotHelper.swift:131`). Die Doku nennt das ausdrücklich als Weg, damit die App den Screenshot-Lauf erkennt ([docs.fastlane.tools/actions/snapshot](https://docs.fastlane.tools/actions/snapshot/)). Fastlane selbst setzt also ebenfalls auf App-seitige Erkennung.
- **scan (`run_tests`):** `reset_simulator` → `FastlaneCore::Simulator.reset` → `xcrun simctl erase`; `reinstall_app` → `xcrun simctl uninstall`. Beide Defaults sind `false` ([scan/runner.rb:31-52](https://github.com/fastlane/fastlane/blob/1f8de9278e1827c8fb4c74e385c0a0e8a93603b6/scan/lib/scan/runner.rb#L31-L52), [device_manager.rb:224-227, 321-332](https://github.com/fastlane/fastlane/blob/1f8de9278e1827c8fb4c74e385c0a0e8a93603b6/fastlane_core/lib/fastlane_core/device_manager.rb#L224-L227), [docs.fastlane.tools/actions/scan](https://docs.fastlane.tools/actions/scan/)).
- `clean` ist ein **Build**-Clean (Xcode-Projekt), kein Daten-Reset.

### Firefox iOS (mozilla-mobile/firefox-ios, Stand `546399cd`)

- **Pro-Test-Reset per Launch-Argument:** `LaunchArguments.ClearProfile = "FIREFOX_CLEAR_PROFILE"`. `BaseTestCase` setzt es standardmäßig für jeden UI-Test ([LaunchArguments.swift](https://github.com/mozilla-mobile/firefox-ios/blob/546399cd8ea39dae34f1d35c9d83570164cfa47d/BrowserKit/Sources/Common/Constants/LaunchArguments.swift), [BaseTestCase.swift](https://github.com/mozilla-mobile/firefox-ios/blob/546399cd8ea39dae34f1d35c9d83570164cfa47d/firefox-ios/firefox-ios-tests/Tests/XCUITests/BaseTestCase.swift)).
- **Eigener Speicherort im Testmodus:** Der `UITestAppDelegate` nutzt ein separates Profil `localName: "testProfile"` und leert es bei `ClearProfile` (`clear: true`). Die Daten des normalen Profils bleiben unberührt ([UITestAppDelegate.swift:13-60](https://github.com/mozilla-mobile/firefox-ios/blob/546399cd8ea39dae34f1d35c9d83570164cfa47d/firefox-ios/Client/Application/UITestAppDelegate.swift#L13-L60)). Dort steht auch der Kommentar, dass `ClearProfile` `UserDefaults.standard` **nicht** zurücksetzt und einzelne Schlüssel deshalb „across“ Tests leaken. Das ist ein konkretes Beispiel dafür, dass ein Reset alle Speicherorte abdecken muss.
- **Erkennung des Testlaufs:** UI-Tests über das Argument `FIREFOX_TEST`. Unit-Tests über `NSClassFromString("XCTestCase") != nil`, was nur im Host-Prozess der Unit-Tests greift, weil dort XCTest geladen ist ([AppConstants.swift:7-25](https://github.com/mozilla-mobile/firefox-ios/blob/546399cd8ea39dae34f1d35c9d83570164cfa47d/BrowserKit/Sources/Common/Constants/AppConstants.swift#L7-L25)).
- **Unit-Tests mit leerem App-Start:** `main.swift` wählt `UnitTestAppDelegate`, wenn Tests laufen. Dieser Delegate initialisiert nur das Nötigste und baut die eigentliche App nicht auf ([main.swift](https://github.com/mozilla-mobile/firefox-ios/blob/546399cd8ea39dae34f1d35c9d83570164cfa47d/firefox-ios/Client/Application/main.swift), [UnitTestAppDelegate.swift](https://github.com/mozilla-mobile/firefox-ios/blob/546399cd8ea39dae34f1d35c9d83570164cfa47d/firefox-ios/Client/Application/UnitTestAppDelegate.swift)).
- **Release-Schutz:** Kein `#if DEBUG` um die Weiche. Ein Release-Build reagiert also auf `FIREFOX_TEST`, landet dann aber im separaten Testprofil.

### WordPress iOS (wordpress-mobile/WordPress-iOS, Stand `6df9ab12`)

- **App-seitiger Reset:** `-ui-test-reset-everything` löscht die Core-Data-Datenbank und alle Schlüssel in `UserDefaults.standard` ([UITestConfigurator.swift](https://github.com/wordpress-mobile/WordPress-iOS/blob/6df9ab12a922f20db4a9ddb3d6283ce4b81828b4/WordPress/Classes/System/UITesting/UITestConfigurator.swift)). Der Aufruf steht unbedingt in `application(_:didFinishLaunching…)` ([WordPressAppDelegate.swift:106](https://github.com/wordpress-mobile/WordPress-iOS/blob/6df9ab12a922f20db4a9ddb3d6283ce4b81828b4/WordPress/Classes/System/WordPressAppDelegate.swift#L106)). Es gibt **keinen Compile-Schutz**, der Schalter wirkt also auch im Store-Build.
- **Zusätzlich Simulator-Reset in CI:** Die CI-Lane `test_without_building` ruft `run_tests(… reset_simulator: true …)` auf ([fastlane/lanes/build.rb:118-141](https://github.com/wordpress-mobile/WordPress-iOS/blob/6df9ab12a922f20db4a9ddb3d6283ce4b81828b4/fastlane/lanes/build.rb#L118-L141)). Kombination: Erase als grobe Grundreinigung in CI, Launch-Argument für den Zustand im Test.

**Einordnung:** Beide Projekte verlassen sich für den Zustand **im Test** auf einen App-seitigen Schalter, keines nur auf Simulator-Reset. Beide verzichten auf einen Compile-Schutz. Für eine App, deren Kernwert die eigene Bibliothek des Nutzers ist, ist das zu schwach. Still Moment hat mit `SCREENSHOTS_BUILD` bereits den strengeren Weg. (Die Auswahl von zwei Projekten ist eine Stichprobe und keine Erhebung.)

---

## Release-Schutz für einen Test-Schalter

| Mechanismus | Wirkt im Release-Build? | Bewertung |
|-------------|-------------------------|-----------|
| `#if DEBUG` (in `SWIFT_ACTIVE_COMPILATION_CONDITIONS` der Debug-Konfiguration, `project.pbxproj:712`) | Nein, der Code wird nicht kompiliert | Harte Garantie. Die UI-Test-Action läuft in `Debug` (`StillMoment-UITests.xcscheme:27`). Einschränkung: Debug-Builds auf echten Geräten (Xcode-Run) hätten den Schalter ebenfalls. Er greift aber nur, wenn jemand das Argument übergibt. |
| Eigenes Flag wie `SCREENSHOTS_BUILD` (`OTHER_SWIFT_FLAGS`, nur im Screenshots-Target) | Nein | Am strengsten, braucht aber ein eigenes Target. Für normale UI-Tests wäre das ein dritter App-Build (Einschätzung: unverhältnismäßig). |
| Laufzeit-Prüfung `NSClassFromString("XCTestCase") != nil` | — | **Funktioniert nicht für UI-Tests**, weil die App dort ein eigener Prozess ohne XCTest ist. Taugt nur für Unit-Tests mit Host (Firefox nutzt es genau so). |
| Nur Laufzeit-Argument (Firefox, WordPress) | Ja | Kein Schutz. |
| Schalter zielt auf separaten Test-Speicher statt auf echte Daten | Selbst wenn er wirkt, bleiben echte Daten unberührt | Gute **zweite** Schutzschicht, ergänzt `#if DEBUG`. |

Prüfbarkeit (Einschätzung): Ein Release-Build lässt sich nicht per Unit-Test prüfen, weil Tests in Debug laufen. Machbar ist eine statische Prüfung in `make check` (wie `lint-selftest.sh` für ios-055), die sicherstellt, dass die Auswertung des Arguments nur innerhalb eines `#if DEBUG`-Blocks vorkommt, oder ein Blick in das Archiv mit `make release-dry`.

---

## Nebenfrage: Unit-Tests mit Host-App schreiben in echte App-Daten (ios-057)

Standardlösungen, nach Wirksamkeit geordnet:

1. **Speicherorte injizieren, in Tests temporär setzen.** Jeder Dienst bekommt `UserDefaults` und ein **Basisverzeichnis** per Init. Tests übergeben `UserDefaults(suiteName: "test-<UUID>")` und ein Verzeichnis unter `FileManager.default.temporaryDirectory` und räumen in `tearDown` mit `removePersistentDomain(forName:)` bzw. `removeItem` auf ([init(suiteName:)](https://developer.apple.com/documentation/foundation/userdefaults/init(suitename:)), [removePersistentDomain(forName:)](https://developer.apple.com/documentation/foundation/userdefaults/removepersistentdomain(forname:)), [WWDC19-413](https://developer.apple.com/videos/play/wwdc2019/413/) zu `tearDown`). Still Moment kann `userDefaults:` bereits injizieren. Die **Dateipfade** sind aber fest an `applicationSupportDirectory` gebunden (`GuidedMeditationService.swift:138`, `CustomAudioRepository.swift:149`, `WaveformCacheService.swift:77`). Das passt zur Hypothese in ios-057 (96 `test_audio_<UUID>.mp3` im echten Ordner).
2. **Host-App startet im Testlauf ohne echten Zustand.** Apple empfiehlt, den Testlauf zu erkennen und Start-Arbeit zu überspringen ([WWDC18-417](https://developer.apple.com/videos/play/wwdc2018/417/)). Firefox schaltet auf einen minimalen `UnitTestAppDelegate` um. In SwiftUI wäre das Gegenstück ein `@main`, das im Testlauf eine leere Szene zeigt und `AppDependencies.live()` nicht aufruft (Einschätzung, nicht recherchiert). Das verhindert Schreibzugriffe **des App-Starts** (Migrationen, Seeding, `DurationConfigurer`), aber nicht die Schreibzugriffe der Tests selbst. Es ergänzt Punkt 1, ersetzt ihn nicht.
3. **Tests ohne Host-App.** Apple DTS schlägt zwei Test-Targets vor, mit und ohne Host ([Forum 751559](https://developer.apple.com/forums/thread/751559)). Ohne Host läuft das Bundle im Test-Runner von Xcode und damit nicht mehr im Container der App. Wie der Container des Runners auf dem iOS-Simulator genau aussieht, habe ich nicht in einer Primärquelle gefunden. Weil die Domain-Tests ohnehin kein UIKit brauchen, ist das ein mittelfristiger Weg, für ios-057 aber vermutlich zu groß (Einschätzung).

---

## Empfehlung für Still Moment

### ios-056 (UI-Tests): was ins Ticket gehört

Lösungsrichtung als Hinweis ins Ticket (keine Implementierung):

- **Ein Launch-Argument für „definierter Ausgangszustand“**, das jeder UI-Test in `setUp` übergibt, z. B. ein gemeinsamer Basis-Helfer für `LibraryFlowUITests`/`TimerFlowUITests`. Der Test legt fest, welchen Zustand er braucht (leer oder Beispiel-Meditationen). Gemäß Apple WWDC25-344 und Firefox `BaseTestCase`.
- **Auswertung an genau einer Stelle:** in `StillMomentApp.init` vor `AppDependencies.live()` bzw. als Parameter dafür (Composition Root aus ios-055). Reihenfolge: erst leeren, dann bei Bedarf seeden. Nicht „seed nur wenn leer“.
- **Getrennter Speicher im UI-Test-Modus** (eigene `UserDefaults`-Suite und eigenes Basisverzeichnis) statt Leeren der echten Daten. Vorteil: Ein `make test-ui` löscht nicht mehr die manuell angelegten Meditationen auf dem Dev-Simulator. Das ist eine bewusste Entscheidung im Ticket, weil der Aufwand höher ist als ein reines „Bibliothek leeren“. Dazu braucht es die Injektion des Basisverzeichnisses aus ios-057, die beiden Tickets teilen sich also diese Vorarbeit.
- **Release-Schutz:** Auswertung nur unter `#if DEBUG` (oder einem eigenen Flag nur in der Debug-Konfiguration). Dazu ein Check in `make check` analog `lint-selftest.sh`. Das AK „Im Release-Build kann kein Startparameter die Bibliothek leeren“ ist damit prüfbar.
- **Alle Speicherorte abdecken**, die die Bibliothek beeinflussen: Bibliotheks-Liste in `UserDefaults`, Meditations-Dateien in Application Support, ggf. ShareInbox im App-Group-Container und Waveform-Cache. Firefox zeigt im Code-Kommentar, dass ein vergessener Ort (dort `UserDefaults.standard`) später als Test-Leak zurückkommt.
- **Nicht** in ios-056: `simctl erase` oder `uninstall` als Pflichtschritt vor `make test-ui`. Das bleibt optional (`make test-clean`). Das AK „grün ohne Reset“ verlangt den App-seitigen Weg.
- **Prüfidee fürs AK „Screenshot-Tests unverändert“:** Den vorhandenen `SCREENSHOTS_BUILD`-Mechanismus nicht doppeln, sondern auf denselben Code umstellen. Dabei den Snapfile-Nebenbefund (`reinstall_app` ohne passenden `app_identifier`) mitprüfen oder als eigenes Mini-Ticket festhalten.
- **Optional:** Ein CI-Lauf mit `-run-tests-until-failure` oder zufälliger Reihenfolge (Test-Plan „Execution Order: Random“) deckt verbliebene Abhängigkeiten zwischen Tests auf ([organizing-tests-to-improve-feedback](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback)).

### ios-057 (Unit-Tests): was ins Ticket gehört

- **Ursache zuerst bestätigen** (steht schon im Ticket). Der Befund oben bestätigt, dass die Dateipfade nicht injizierbar sind. Das ist eine notwendige Bedingung für die Hypothese, aber noch kein Beweis.
- **Basisverzeichnis injizierbar machen** für `GuidedMeditationService`, `CustomAudioRepository` und `WaveformCacheService`, gesetzt in `AppDependencies.live()`. Tests übergeben ein temporäres Verzeichnis und eine eigene `UserDefaults`-Suite. Gemeinsame Vorarbeit mit ios-056.
- **Host-App im Unit-Test-Lauf ohne echten Start:** Erkennung über `NSClassFromString("XCTestCase")` oder über eine Umgebungsvariable in der Test-Action des Schemes `StillMoment-UnitTests` (WWDC18-417). In dem Fall `AppDependencies.live()`, Migrationen und `DurationConfigurer` nicht ausführen. Als eigenes AK formulieren, da es auch „App-Start schreibt in den echten Bestand“ abdeckt.
- **Wächter-Check** (AK „Ein Test oder Check schlägt fehl …“): z. B. ein `XCTestObservation`, der vor dem ersten und nach dem letzten Test den echten Meditations-Ordner und die relevanten `UserDefaults`-Schlüssel vergleicht. Das ist eine Einschätzung und nicht recherchiert. Die konkrete Form ist Sache der Planung.
- **Kein Wechsel auf Tests ohne Host** in diesem Ticket. Höchstens als Ausblick notieren (Apple DTS: zwei Targets).

---

## Quellen

**Apple (primär)**
- XCUIApplication.launchArguments: https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/launcharguments
- XCUIApplication.launchEnvironment: https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/launchenvironment
- XCUIApplication.resetAuthorizationStatus(for:): https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/resetauthorizationstatus(for:)
- UserDefaults.argumentDomain: https://developer.apple.com/documentation/foundation/userdefaults/argumentdomain
- UserDefaults.init(suiteName:): https://developer.apple.com/documentation/foundation/userdefaults/init(suitename:)
- UserDefaults.removePersistentDomain(forName:): https://developer.apple.com/documentation/foundation/userdefaults/removepersistentdomain(forname:)
- Improving code assessment by organizing tests into test plans: https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback
- Build settings reference (TEST_HOST, SWIFT_ACTIVE_COMPILATION_CONDITIONS): https://developer.apple.com/documentation/xcode/build-settings-reference
- WWDC25-344 Record, replay, and review: UI automation with Xcode: https://developer.apple.com/videos/play/wwdc2025/344/
- WWDC20-10220 Handle interruptions and alerts in UI tests: https://developer.apple.com/videos/play/wwdc2020/10220/
- WWDC19-413 Testing in Xcode: https://developer.apple.com/videos/play/wwdc2019/413/
- WWDC18-417 Testing Tips & Tricks: https://developer.apple.com/videos/play/wwdc2018/417/
- Apple Developer Forums, DTS-Antwort zu Test Host: https://developer.apple.com/forums/thread/751559
- Lokal: `xcrun simctl help erase|uninstall|clone|create|get_app_container|privacy`, `xcodebuild -help` (Xcode 27.0)

**Fastlane (primär, Commit `1f8de927`)**
- https://docs.fastlane.tools/actions/snapshot/
- https://docs.fastlane.tools/actions/scan/
- snapshot/lib/snapshot/simulator_launchers/simulator_launcher_base.rb, snapshot/lib/snapshot/options.rb, scan/lib/scan/runner.rb, fastlane_core/lib/fastlane_core/device_manager.rb (Links im Text)

**Open Source (primär)**
- Firefox iOS @ `546399cd`: UITestAppDelegate.swift, UnitTestAppDelegate.swift, main.swift, AppConstants.swift, LaunchArguments.swift, BaseTestCase.swift (Links im Text)
- WordPress iOS @ `6df9ab12`: UITestConfigurator.swift, WordPressAppDelegate.swift, fastlane/lanes/build.rb (Links im Text)

**Sekundär (nur Hinweis)**
- wwdcnotes.com zu WWDC18-403 (Parallel-Testing-Klone, Original nur Vorlage): https://wwdcnotes.com/notes/wwdc18/403. Die Apple-Originalsession ist nicht mehr abrufbar.

**Eigener Code (Still Moment)**
- `ios/StillMoment/StillMomentApp.swift`, `ios/StillMoment/AppDependencies.swift`, `ios/StillMoment-Screenshots/TestFixtureSeeder.swift`, `ios/StillMomentUITests/*.swift`, `ios/Makefile`, `ios/scripts/run-tests.sh`, `ios/scripts/test-helpers.sh`, `ios/scripts/test-config.sh`, `ios/fastlane/Snapfile`, `ios/fastlane/Appfile`, `ios/fastlane/Fastfile`
