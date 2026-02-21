# Discussion Items: shared-050

Gesammelt waehrend automatischem Review. Zum spaeteren Abarbeiten.

## Review-Runde 1

- ios/StillMoment/Domain/Models/Introduction.swift:93 - `currentLanguage` ist ein static computed property auf Domain-Ebene, der direkt `Locale.current` liest. Das macht Unit-Tests locale-abhaengig (sichtbar in TimerReducerIntroductionTests: Tests mit `if Introduction.isAvailableForCurrentLanguage("breath")` guards). Alternativ: Locale als Parameter uebergeben oder eine injizierbare Abhaengigkeit. In der Praxis ein Design-Kompromiss, der bewusst gemacht scheint.
- ios/StillMoment/Application/ViewModels/TimerViewModel.swift:384-393 - Der Kommentar "Don't return - interval gong check must still run" bei `preparationFinished` ist etwas tricky: Wenn `preparationFinished` AND gleichzeitig `introductionFinished` dispatched werden koennte, weil Timer direkt in `.running` springt, koennte ein doppelter Background-Audio-Start auftreten. In der Praxis verhindert das die State Machine, aber der Kontrollfluss ist nicht sofort offensichtlich. Kein Bug, aber schwer lesbar.

## Review-Runde 2

- ios/StillMoment/Domain/Models/Introduction.swift:93-96 - `currentLanguage` liest direkt `Locale.current` (Design-Kompromiss aus Review 1, unveraendert).
- ios/StillMoment/Application/ViewModels/TimerViewModel.swift:384-393 - "Don't return"-Kontrollfluss nach `preparationFinished`-Dispatch lesbar via Kommentar aber tricky (aus Review 1, unveraendert).
- ios/StillMomentTests/Domain/TimerReducerIntroductionTests.swift:60-68 - Tests mit `if Introduction.isAvailableForCurrentLanguage("breath")` Guards sind in englischer CI-Umgebung weniger aussagekraeftig (aus Review 1, unveraendert).

## Review-Runde 3

- ios/StillMoment/Domain/Services/TimerReducer.swift:205-214 - `hasActiveIntroduction()` ruft `Introduction.isAvailableForCurrentLanguage()` auf, das `Locale.current` liest. Locale-Abhaengigkeit im pure Reducer (aus Review 1 unveraendert, Design-Kompromiss).
- ios/StillMomentTests/Domain/TimerReducerIntroductionTests.swift:60-68 - Guards mit `if Introduction.isAvailableForCurrentLanguage("breath")` sind in englischer CI-Umgebung wirkungslos (aus Review 1+2 unveraendert).
