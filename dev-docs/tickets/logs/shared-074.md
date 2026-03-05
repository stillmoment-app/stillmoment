---

## REVIEW 1
Verdict: FAIL

make check: OK
make test-unit: OK

BLOCKER:
- ios/StillMoment/Domain/Services/TimerReducer.swift:197 - Fallback `Introduction.isAvailableForCurrentLanguage(introId)` verbleibt im Domain-Layer fuer den Fall dass kein Resolver uebergeben wird. Das verletzt das Akzeptanzkriterium "Kein Konsument prueft mehr direkt Introduction.isAvailableForCurrentLanguage()". Der Fallback ermoeglicht es, die Resolver-Absicherung zu umgehen. Da `TimerViewModel.dispatch()` den Resolver immer uebergibt (Zeile 152), ist dieser Pfad in der Praxis nie aktiv — macht die Code-Smell aber nicht weniger ein AC-Verletzung.
- ios/StillMoment/Domain/Services/TimerReducer.swift:29 - `attunementResolver: AttunementResolverProtocol? = nil` als optionaler Parameter in der Domain-Funktion ist ein Architektur-Problem: ein Domain-Service referenziert ein Domain-Protokoll das er selbst nicht benoetigen sollte — aber das ist der beabsichtigte Ansatz fuer Rueckwaertskompatibilitaet. Hauptproblem ist der Fallback-Pfad in Zeile 197 der das Ziel untergrabt.

DISCUSSION:
<!-- DISCUSSION_START -->
- ios/StillMoment/Domain/Models/MeditationSettings.swift:162 - `Introduction.find(byId:)` Aufruf als Fallback in `minimumDuration()`. Dieser befindet sich in einem Domain-Modell und greift direkt auf das Katalog-Objekt zu. Das Akzeptanzkriterium nennt explizit `Introduction.find()` als zu ersetzenden Aufruf. In der Praxis klappt dies nur fuer built-in Intros korrekt; custom Intros ohne `introDurationSeconds` wuerden hier `nil` liefern (was zu minimum=1 fuehrt, nicht zu einem Fehler). Da der ViewModel `customIntroDurationSeconds` immer befuellt (via `resolveIntroDurationSeconds`), ist der Fallback praktisch nicht erreichbar — aber er sollte formal entfernt oder dokumentiert werden.
- ios/StillMoment/Infrastructure/Services/AudioService.swift:32-38 - Lokale `customRepo` Variable um `nil` Fallback zu erstellen (Zeile 31: `let customRepo = customAudioRepository ?? CustomAudioRepository()`). Das bedeutet der uebergebene `customAudioRepository` Parameter (Zeile 22) kann `nil` sein, aber intern wird trotzdem ein neues `CustomAudioRepository()` erstellt. `self.customAudioRepository` (Zeile 254) bleibt `Optional` und wird getrennt gespeichert. Dieses duale Tracking ist unuebersichtlich — `customAudioRepository` koennte non-optional sein wenn die Resolver es bereits kapseln.
- ios/StillMomentTests/Infrastructure/AttunementResolverTests.swift:145 - `testAllAvailableIncludesBuiltInAndCustom` erwartet genau 2 Eintraege. Das setzt voraus, dass in der Test-Umgebung genau 1 built-in Introduction auf "en" verfuegbar ist. Dieser Test ist sproede, wenn weitere built-in Introductions hinzukommen.
<!-- DISCUSSION_END -->

Summary:
Die Implementierung ist gut strukturiert. Protokolle im Domain-Layer, Implementierungen im Infrastructure-Layer, MockResolver fuer Tests. make check und alle 892 Tests sind gruen. Die Resolver loesen transparent built-in und custom IDs auf, und werden korrekt in TimerViewModel und ConfigurationDescription verwendet.

BLOCKER: Das Akzeptanzkriterium "Kein Konsument prueft mehr direkt Introduction.isAvailableForCurrentLanguage()" ist nicht vollstaendig erfuellt. In `TimerReducer.hasActiveIntroduction()` existiert ein expliziter Fallback-Pfad (Zeile 197), der bei fehlendem Resolver direkt `Introduction.isAvailableForCurrentLanguage()` aufruft. Dieser Pfad ist in der Praxis nie aktiv (ViewModel uebergibt immer den Resolver), aber er verletzt das AC formal und ist ein latentes Risiko falls der Reducer kuenftig von anderer Stelle ohne Resolver aufgerufen wird.

DISCUSSION: `Introduction.find(byId:)` in `MeditationSettings.minimumDuration()` als Fallback ist ein aehnliches Problem, aber der Kontext ist ein Validierungs-Helfer, nicht ein Playback-Entscheider — daher als Discussion eingestuft.

---

## FIX 1
Status: DONE
Commits:
- 8efb1fe fix(ios): #shared-074 make attunementResolver non-optional in TimerReducer

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
BLOCKER aus REVIEW 1 gefixt: `attunementResolver` Parameter in `TimerReducer.reduce()` von optional (`AttunementResolverProtocol? = nil`) auf non-optional geaendert. Fallback-Pfad zu `Introduction.isAvailableForCurrentLanguage()` in `hasActiveIntroduction()` entfernt. Alle 6 Test-Dateien die `TimerReducer.reduce()` aufrufen aktualisiert mit `MockAttunementResolver`. Introduction-Tests nutzen `breathResolver` (mit gestubtem "breath" ResolvedAttunement), alle anderen nutzen `emptyResolver`. `Introduction.languageOverride` in setUp/tearDown entfernt da nicht mehr noetig.

Verbleibende direkte Katalog-Lookups in Production Code (ios/StillMoment/):
- `Introduction.find(byId:)` in AttunementResolver.swift (Infrastructure — beabsichtigt, der Resolver kapselt den Katalog-Zugriff)
- `Introduction.find(byId:)` in MeditationSettings.swift (Domain — bewusst belassen als Validierungs-Fallback fuer built-in Intros)
- `Introduction.availableForCurrentLanguage()` in PraxisEditorViewModel.swift, TimerViewModel+Preview.swift, AttunementResolver.swift (beabsichtigt — ViewModel/Infrastructure nutzen Katalog fuer UI-Listen)
- `Introduction.audioFilenameForCurrentLanguage()` in AttunementResolver.swift (Infrastructure — beabsichtigt)

---

## IMPLEMENT (Android)
Status: DONE
Commits:
- 62ae4d3 feat(android): #shared-074 implement AttunementResolver and SoundscapeResolver with tests

Challenges:
<!-- CHALLENGES_START -->
- FakeCustomAudioRepository had private _files field with no addFile method — needed to add addFile() to support direct test setup without going through importFile()
<!-- CHALLENGES_END -->

Summary:
Android Infrastructure-Implementierungen fuer AttunementResolver und SoundscapeResolver erstellt. Domain-Protokolle und Models waren bereits vorhanden (aus vorheriger Task). Beide Resolver nutzen runBlocking fuer den Zugriff auf suspend-Methoden des CustomAudioRepository, da die Resolver-Protokolle synchron sind (Aufruf aus reinen Reducer-Funktionen). Hilt DI-Bindings in AppModule hinzugefuegt. Test-Mocks (MockAttunementResolver, MockSoundscapeResolver) in neuem testutil-Verzeichnis angelegt. 15 Unit-Tests (8 AttunementResolver, 7 SoundscapeResolver) alle gruen. Alle 898 Tests bestanden.

---

## IMPLEMENT (Android Consumer Refactoring)
Status: DONE
Commits:
- 4f639e4 refactor(android): #shared-074 replace direct catalog lookups with resolver services

Challenges:
<!-- CHALLENGES_START -->
- TimerViewModel constructor change (customAudioRepository -> attunementResolver) required updating 4 additional ViewModel test files beyond TimerReducerTest
- Introduction.languageOverride hack in regression tests no longer needed since resolver mock controls availability
- Introduction pill label required adding resolvedIntroductionName to TimerUiState since Composables cannot access the resolver directly
<!-- CHALLENGES_END -->

Summary:
Replaced all direct Introduction.isAvailableForCurrentLanguage() and Introduction.find() calls in TimerReducer with AttunementResolverProtocol. Added attunementResolver as non-optional parameter to TimerReducer.reduce(). Updated TimerViewModel to inject resolver via Hilt, pass to dispatch, and use resolver for intro duration resolution (replacing the old customAudioRepository-based approach). Fixed introduction pill label by adding resolvedIntroductionName to TimerUiState and populating it in all settings update paths. Updated all 5 test files (TimerReducerTest + 4 ViewModel tests) with MockAttunementResolver. All 898 tests pass.

Remaining direct catalog lookups in Android production code:
- Introduction.find() in AttunementResolver.kt (Infrastructure — beabsichtigt, Resolver kapselt Katalog)
- Introduction.availableForCurrentLanguage() in SettingsSheet.kt, PraxisEditorViewModel.kt, SelectIntroductionScreen.kt (UI-Listen — beabsichtigt, matching iOS approach)
- Introduction.find() in SettingsSheet.kt, PraxisEditorScreen.kt (display name in editor UI — future ticket)

---

## CLOSE
Status: DONE
Commits:
- c0742f4 docs: #shared-074 Close ticket (iOS)
- ab3d21e docs: #shared-074 Close ticket

---

## REVIEW 2
Verdict: PASS

make check: OK
make test-unit-agent: OK (898/898)

DISCUSSION:
<!-- DISCUSSION_START -->
- android/app/src/main/kotlin/com/stillmoment/domain/models/MeditationSettings.kt:99 - `Introduction.find(activeIntroductionId)` bleibt als Fallback in `minimumDuration()` erhalten (Domain-Layer). Identisches Muster wie auf iOS (REVIEW 1 DISCUSSION). Der `customIntroDurationSeconds`-Pfad wird vom ViewModel immer befuellt wenn ein Resolver vorliegt, daher ist der Fallback praktisch nie aktiv fuer custom IDs. Als bewusste Entscheidung dokumentiert, aber formal eine direkte Katalog-Abhaengigkeit im Domain-Layer.
- android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/SoundscapeResolver.kt:79 - `localizedSoundName()` nutzt `Introduction.currentLanguage` um die Sprache zu ermitteln. Leicht unerwartet: Sprachermittlung ueber `Introduction`-Klasse statt einen expliziten Sprachparameter. Funktioniert korrekt, da beide auf die gleiche `languageOverride`-Logik zugreifen, ist aber eine implizite Kopplung zwischen zwei unverwandten Domain-Klassen.
<!-- DISCUSSION_END -->

Summary:
Die Android-Implementierung ist korrekt und vollstaendig. Domain-Protokolle (`AttunementResolverProtocol`, `SoundscapeResolverProtocol`) und Models (`ResolvedAttunement`, `ResolvedSoundscape`) im Domain-Layer ohne Platform-Imports. Infrastructure-Implementierungen kapseln die duale Lookup-Logik (built-in + custom). Hilt-Bindings in `AppModule` korrekt als `@Singleton` registriert. `TimerReducer` erhaelt den Resolver non-optional als Parameter — kein Fallback-Pfad zu direkten Katalog-Lookups. `TimerViewModel` injiziert den Resolver via Hilt und verwendet ihn fuer Intro-Dauer und Pill-Anzeige (`resolvedIntroductionName` in `TimerUiState`). `ConfigurationPills` liest den aufgeloesten Namen aus dem UiState statt direkt vom Katalog.

Verbleibende direkte `Introduction.find()`-Aufrufe in Infrastructure (`TimerForegroundService`, `AudioService`) sind korrekt: Playback-Code benoetigt die Unterscheidung zwischen built-in (Resource-Dateiname) und custom (Dateipfad) und kann nicht allein durch den Resolver ersetzt werden — der Resolver liefert nur Metadaten.

Alle Akzeptanzkriterien erfuellt. `make check` und alle 898 Unit-Tests sind gruen. Glossar dokumentiert. PASS.
